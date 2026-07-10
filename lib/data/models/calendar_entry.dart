import 'outfit.dart';

class CalendarEntry {
  final String id;
  final String userId;
  final String outfitId;
  final Outfit? outfit;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;

  const CalendarEntry({
    required this.id,
    required this.userId,
    required this.outfitId,
    this.outfit,
    required this.date,
    this.notes,
    required this.createdAt,
  });

  factory CalendarEntry.fromJson(Map<String, dynamic> json) => CalendarEntry(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        outfitId: json['outfit_id'] as String,
        outfit: json['outfit'] != null
            ? Outfit.fromJson(json['outfit'] as Map<String, dynamic>)
            : null,
        date: DateTime.parse(json['date'] as String),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'outfit_id': outfitId,
        'date': date.toIso8601String().split('T')[0],
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };
}
