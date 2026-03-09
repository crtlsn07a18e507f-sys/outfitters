import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../config/api_config.dart';
import '../models/clothing.dart';
import '../models/outfit.dart';
import '../models/weather.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static const Duration _timeout = Duration(seconds: 30);

  static Future<dynamic> _get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);
    final response = await http.get(uri).timeout(_timeout);
    return _handle(response);
  }

  static Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = await http
        .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
        .timeout(_timeout);
    return _handle(response);
  }

  static Future<dynamic> _delete(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);
    final response = await http.delete(uri).timeout(_timeout);
    return _handle(response);
  }

  static dynamic _handle(http.Response r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      if (r.body.isEmpty) return null;
      return jsonDecode(r.body);
    }
    String message = 'Request failed';
    try {
      final decoded = jsonDecode(r.body);
      message = decoded['detail'] ?? decoded['message'] ?? message;
    } catch (_) {}
    throw ApiException(message, r.statusCode);
  }

  // ── Weather ─────────────────────────────────────────────────────────────

  static Future<Weather> getWeather(double lat, double lon) async {
    // 1. Dati meteo da Open-Meteo (gratuita, no API key)
    final weatherUri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,apparent_temperature,relative_humidity_2m,'
      'wind_speed_10m,weather_code'
      '&wind_speed_unit=ms',
    );

    // 2. Nome città da nominatim (gratuita, no API key)
    final geoUri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?lat=$lat&lon=$lon&format=json',
    );

    final responses = await Future.wait([
      http.get(weatherUri),
      http.get(geoUri, headers: {'User-Agent': 'FlutterApp'}),
    ]);

    if (responses[0].statusCode != 200 || responses[1].statusCode != 200) {
      throw Exception('Errore nel recupero dei dati meteo');
    }

    final weatherData = jsonDecode(responses[0].body);
    final geoData = jsonDecode(responses[1].body);

    final current = weatherData['current'] as Map<String, dynamic>;
    final weatherCode = current['weather_code'] as int;

    return Weather(
      temperature: (current['temperature_2m'] as num).toDouble(),
      feelsLike: (current['apparent_temperature'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      condition: _conditionFromCode(weatherCode),
      description: _descriptionFromCode(weatherCode),
      icon: _iconFromCode(weatherCode),
      city: geoData['address']?['city'] ??
            geoData['address']?['town'] ??
            geoData['address']?['village'] ??
            'Unknown',
    );
  }

  /// WMO weather code → condizione (compatibile con weatherEmoji esistente)
  static String _conditionFromCode(int code) {
    if (code == 0) return 'Clear';
    if (code <= 2) return 'Clouds';
    if (code == 3) return 'Overcast';
    if (code <= 49) return 'Mist';
    if (code <= 67) return 'Rain';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Rain';
    if (code <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  static String _descriptionFromCode(int code) {
    if (code == 0) return 'Cielo sereno';
    if (code == 1) return 'Prevalentemente sereno';
    if (code == 2) return 'Parzialmente nuvoloso';
    if (code == 3) return 'Coperto';
    if (code <= 49) return 'Nebbia';
    if (code <= 57) return 'Pioggerella';
    if (code <= 67) return 'Pioggia';
    if (code <= 77) return 'Neve';
    if (code <= 82) return 'Rovesci';
    if (code <= 99) return 'Temporale';
    return 'Sconosciuto';
  }

  /// Restituisce un'emoji come "icon" — iconUrl non sarà usata con Open-Meteo
  static String _iconFromCode(int code) {
    if (code == 0) return '01d';
    if (code <= 2) return '02d';
    if (code == 3) return '04d';
    if (code <= 49) return '50d';
    if (code <= 67) return '10d';
    if (code <= 77) return '13d';
    if (code <= 82) return '09d';
    if (code <= 99) return '11d';
    return '01d';
  }

  // ── Clothes ──────────────────────────────────────────────────────────────

  static Future<ClothingItem> uploadClothing(String userId, File imageFile) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/clothes/upload');
    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
    final parts = mimeType.split('/');

    final request = http.MultipartRequest('POST', uri)
      ..fields['user_id'] = userId
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType(parts[0], parts[1]),
      ));

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    final data = _handle(response);
    return ClothingItem.fromJson(data as Map<String, dynamic>);
  }

  static Future<List<ClothingItem>> getUserClothes(String userId) async {
    final data = await _get('/clothes/user/$userId');
    return (data as List).map((e) => ClothingItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<ClothingStats> getClothingStats(String userId) async {
    final data = await _get('/clothes/user/$userId/stats');
    return ClothingStats.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> deleteClothing(String itemId, String userId) async {
    await _delete('/clothes/$itemId', query: {'user_id': userId});
  }

  // ── Outfits ──────────────────────────────────────────────────────────────

  static Future<Outfit> generateOutfit({
    required String userId,
    required double latitude,
    required double longitude,
    String? occasion,
  }) async {
    final data = await _post('/outfits/generate', {
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      if (occasion != null) 'occasion': occasion,
    });
    return Outfit.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> reactToOutfit(String outfitId, bool liked) async {
    await _post('/outfits/$outfitId/react', {'liked': liked});
  }

  static Future<List<Outfit>> getLikedOutfits(String userId, double temperature) async {
    final data = await _get('/outfits/liked/$userId', query: {
      'temp': '$temperature',
      'limit': '4',
    });
    return (data as List).map((e) => Outfit.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Calendar (storage locale) ────────────────────────────────────────────

  static String _eventsKey(String userId) => 'events_$userId';

  static Future<List<CalendarEvent>> getEvents(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_eventsKey(userId)) ?? [];
    final now = DateTime.now();
    // Restituisce solo gli eventi futuri, ordinati per data
    return raw
        .map((e) => CalendarEvent.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .where((e) => e.eventDate.isAfter(now))
        .toList()
      ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
  }

  static Future<CalendarEvent> createEvent({
    required String userId,
    required String title,
    required String occasionType,
    required DateTime eventDate,
    String? notes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_eventsKey(userId)) ?? [];

    final event = CalendarEvent(
      id: const Uuid().v4(),
      userId: userId,
      title: title,
      occasionType: occasionType,
      eventDate: eventDate,
      notes: notes,
    );

    raw.add(jsonEncode({
      'id': event.id,
      'user_id': event.userId,
      'title': event.title,
      'occasion_type': event.occasionType,
      'event_date': event.eventDate.toIso8601String(),
      'notes': event.notes,
    }));

    await prefs.setStringList(_eventsKey(userId), raw);
    return event;
  }

  static Future<void> deleteEvent(String eventId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_eventsKey(userId)) ?? [];
    raw.removeWhere((e) {
      final decoded = jsonDecode(e) as Map<String, dynamic>;
      return decoded['id'] == eventId;
    });
    await prefs.setStringList(_eventsKey(userId), raw);
  }
}