import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
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
    final data = await _get('/weather/', query: {'lat': '$lat', 'lon': '$lon'});
    return Weather.fromJson(data as Map<String, dynamic>);
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

  // ── Calendar ─────────────────────────────────────────────────────────────

  static Future<CalendarEvent> createEvent({
    required String userId,
    required String title,
    required String occasionType,
    required DateTime eventDate,
    String? notes,
  }) async {
    final data = await _post('/events/', {
      'user_id': userId,
      'title': title,
      'occasion_type': occasionType,
      'event_date': eventDate.toIso8601String(),
      if (notes != null) 'notes': notes,
    });
    return CalendarEvent.fromJson(data as Map<String, dynamic>);
  }

  static Future<List<CalendarEvent>> getEvents(String userId) async {
    final data = await _get('/events/user/$userId');
    return (data as List).map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<void> deleteEvent(String eventId, String userId) async {
    await _delete('/events/$eventId', query: {'user_id': userId});
  }
}
