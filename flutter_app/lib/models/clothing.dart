class ClothingItem {
  final String id;
  final String userId;
  final String name;
  final String category;
  final String color;
  final String material;
  final double tempMin;
  final double tempMax;
  final List<String> suitableOccasions;
  final String imageFilename;
  final String? aiDescription;
  final DateTime createdAt;

  const ClothingItem({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    required this.color,
    required this.material,
    required this.tempMin,
    required this.tempMax,
    required this.suitableOccasions,
    required this.imageFilename,
    this.aiDescription,
    required this.createdAt,
  });

  factory ClothingItem.fromJson(Map<String, dynamic> json) => ClothingItem(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        color: json['color'] as String,
        material: json['material'] as String,
        tempMin: (json['temp_min'] as num).toDouble(),
        tempMax: (json['temp_max'] as num).toDouble(),
        suitableOccasions: (json['suitable_occasions'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        imageFilename: json['image_filename'] as String,
        aiDescription: json['ai_description'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  String get categoryIcon {
    const icons = {
      'top': '👕',
      'bottom': '👖',
      'shoes': '👟',
      'jacket': '🧥',
      'accessory': '💍',
    };
    return icons[category] ?? '👔';
  }

  String get categoryLabel {
    const labels = {
      'top': 'Top',
      'bottom': 'Pantaloni',
      'shoes': 'Scarpe',
      'jacket': 'Giacca',
      'accessory': 'Accessorio',
    };
    return labels[category] ?? category;
  }
}

class ClothingStats {
  final int total;
  final Map<String, int> byCategory;

  const ClothingStats({required this.total, required this.byCategory});

  factory ClothingStats.fromJson(Map<String, dynamic> json) => ClothingStats(
        total: json['total'] as int,
        byCategory: Map<String, int>.from(json['by_category'] as Map),
      );
}
