class Garment {
  final String id;
  final String userId;
  final String name;
  final String category;
  final String? brand;
  final String? color;
  final String? season;
  final String? occasion;
  final double? price;
  final List<String> imageUrls;
  final String? notes;
  final int wearCount;
  final DateTime? lastWorn;
  final DateTime createdAt;

  const Garment({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    this.brand,
    this.color,
    this.season,
    this.occasion,
    this.price,
    this.imageUrls = const [],
    this.notes,
    this.wearCount = 0,
    this.lastWorn,
    required this.createdAt,
  });

  String? get coverImageUrl => imageUrls.isEmpty ? null : imageUrls.first;

  double get costPerWear {
    if (price == null || price! <= 0 || wearCount <= 0) return price ?? 0;
    return price! / wearCount;
  }

  factory Garment.fromJson(Map<String, dynamic> json) => Garment(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        brand: json['brand'] as String?,
        color: json['color'] as String?,
        season: json['season'] as String?,
        occasion: json['occasion'] as String?,
        price: (json['price'] as num?)?.toDouble(),
        imageUrls: (json['image_urls'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
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
        'category': category,
        'brand': brand,
        'color': color,
        'season': season,
        'occasion': occasion,
        'price': price,
        'notes': notes,
        'wear_count': wearCount,
        'last_worn': lastWorn?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  Garment copyWith({
    String? name,
    String? category,
    String? brand,
    String? color,
    String? season,
    String? occasion,
    double? price,
    List<String>? imageUrls,
    String? notes,
    int? wearCount,
    DateTime? lastWorn,
  }) =>
      Garment(
        id: id,
        userId: userId,
        name: name ?? this.name,
        category: category ?? this.category,
        brand: brand ?? this.brand,
        color: color ?? this.color,
        season: season ?? this.season,
        occasion: occasion ?? this.occasion,
        price: price ?? this.price,
        imageUrls: imageUrls ?? this.imageUrls,
        notes: notes ?? this.notes,
        wearCount: wearCount ?? this.wearCount,
        lastWorn: lastWorn ?? this.lastWorn,
        createdAt: createdAt,
      );
}
