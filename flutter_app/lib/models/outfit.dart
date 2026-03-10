import 'clothing.dart';

class OutfitItem {
  final String clothingId;
  final int layerOrder;
  final ClothingItem clothing;

  const OutfitItem({
    required this.clothingId,
    required this.layerOrder,
    required this.clothing,
  });

  factory OutfitItem.fromJson(Map<String, dynamic> json) => OutfitItem(
        clothingId: json['clothing_id'] as String,
        layerOrder: json['layer_order'] as int,
        clothing: ClothingItem.fromJson(json['clothing'] as Map<String, dynamic>),
      );
}

class Outfit {
  final String id;
  final String userId;
  final bool? liked;
  final String? occasion;
  final String? weatherCondition;
  final double? temperature;
  final String? aiExplanation;
  final DateTime createdAt;
  final List<OutfitItem> items;

  const Outfit({
    required this.id,
    required this.userId,
    this.liked,
    this.occasion,
    this.weatherCondition,
    this.temperature,
    this.aiExplanation,
    required this.createdAt,
    required this.items,
  });

  factory Outfit.fromJson(Map<String, dynamic> json) => Outfit(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        liked: json['liked'] as bool?,
        occasion: json['occasion'] as String?,
        weatherCondition: json['weather_condition'] as String?,
        temperature: (json['temperature'] as num?)?.toDouble(),
        aiExplanation: json['ai_explanation'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => OutfitItem.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.layerOrder.compareTo(b.layerOrder)),
      );

  /// Items sorted for visual stacking: shoes→bottom→top→jacket→accessory
  List<OutfitItem> get stackedItems => List.from(items)
    ..sort((a, b) => a.layerOrder.compareTo(b.layerOrder));
}
