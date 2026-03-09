class Weather {
  final double temperature;
  final double feelsLike;
  final String condition;
  final String description;
  final int humidity;
  final double windSpeed;
  final String icon;
  final String city;

  const Weather({
    required this.temperature,
    required this.feelsLike,
    required this.condition,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.icon,
    required this.city,
  });

  factory Weather.fromJson(Map<String, dynamic> json) => Weather(
        temperature: (json['temperature'] as num).toDouble(),
        feelsLike: (json['feels_like'] as num).toDouble(),
        condition: json['condition'] as String,
        description: json['description'] as String,
        humidity: json['humidity'] as int,
        windSpeed: (json['wind_speed'] as num).toDouble(),
        icon: json['icon'] as String,
        city: json['city'] as String,
      );

  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';

  String get weatherEmoji {
    final c = condition.toLowerCase();
    if (c.contains('clear')) return '☀️';
    if (c.contains('cloud')) return '☁️';
    if (c.contains('rain') || c.contains('drizzle')) return '🌧️';
    if (c.contains('thunder')) return '⛈️';
    if (c.contains('snow')) return '❄️';
    if (c.contains('mist') || c.contains('fog')) return '🌫️';
    return '🌤️';
  }
}

class CalendarEvent {
  final String id;
  final String userId;
  final String title;
  final String occasionType;
  final DateTime eventDate;
  final String? notes;

  const CalendarEvent({
    required this.id,
    required this.userId,
    required this.title,
    required this.occasionType,
    required this.eventDate,
    this.notes,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => CalendarEvent(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        title: json['title'] as String,
        occasionType: json['occasion_type'] as String,
        eventDate: DateTime.parse(json['event_date'] as String),
        notes: json['notes'] as String?,
      );

  String get occasionEmoji {
    const map = {
      'casual': '😊',
      'formal': '🤵',
      'sport': '⚽',
      'business': '💼',
      'party': '🎉',
      'beach': '🏖️',
    };
    return map[occasionType] ?? '📅';
  }
}
