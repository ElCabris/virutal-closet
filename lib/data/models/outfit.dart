import 'garment.dart';

class Outfit {
  final String id;
  final String userId;
  final String name;
  final List<String> garmentIds;
  final List<Garment> garments;
  final String? occasion;
  final String? season;
  final String? imageUrl;
  final String? notes;
  final int wearCount;
  final DateTime? lastWorn;
  final DateTime createdAt;

  const Outfit({
    required this.id,
    required this.userId,
    required this.name,
    required this.garmentIds,
    this.garments = const [],
    this.occasion,
    this.season,
    this.imageUrl,
    this.notes,
    this.wearCount = 0,
    this.lastWorn,
    required this.createdAt,
  });

  factory Outfit.fromJson(Map<String, dynamic> json) => Outfit(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        garmentIds: List<String>.from(json['garment_ids'] ?? []),
        garments: (json['garments'] as List<dynamic>?)
                ?.map((g) => Garment.fromJson(g as Map<String, dynamic>))
                .toList() ??
            [],
        occasion: json['occasion'] as String?,
        season: json['season'] as String?,
        imageUrl: json['image_url'] as String?,
        notes: json['notes'] as String?,
        wearCount: json['wear_count'] as int? ?? 0,
        lastWorn: json['last_worn'] != null
            ? DateTime.parse(json['last_worn'] as String)
            : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'garment_ids': garmentIds,
        'occasion': occasion,
        'season': season,
        'image_url': imageUrl,
        'notes': notes,
        'wear_count': wearCount,
        'last_worn': lastWorn?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  Outfit copyWith({
    String? name,
    List<String>? garmentIds,
    List<Garment>? garments,
    String? occasion,
    String? season,
    String? imageUrl,
    String? notes,
    int? wearCount,
    DateTime? lastWorn,
  }) =>
      Outfit(
        id: id,
        userId: userId,
        name: name ?? this.name,
        garmentIds: garmentIds ?? this.garmentIds,
        garments: garments ?? this.garments,
        occasion: occasion ?? this.occasion,
        season: season ?? this.season,
        imageUrl: imageUrl ?? this.imageUrl,
        notes: notes ?? this.notes,
        wearCount: wearCount ?? this.wearCount,
        lastWorn: lastWorn ?? this.lastWorn,
        createdAt: createdAt,
      );
}
