import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/garment.dart';

class AiService {
  AiService(this._apiKey, this._model)
      : _dio = Dio(BaseOptions(
          baseUrl: 'https://api.anthropic.com/v1',
          headers: {
            'x-api-key': _apiKey,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
        ));

  final String _apiKey;
  final String _model;
  final Dio _dio;

  Future<List<OutfitSuggestion>> suggestOutfits({
    required List<Garment> garments,
    String? occasion,
    String? season,
    String? weather,
    int count = 3,
  }) async {
    final garmentList = garments
        .map((g) => {
              'name': g.name,
              'category': g.category,
              'color': g.color ?? 'unknown',
              'brand': g.brand,
              'season': g.season,
            })
        .toList();

    final prompt = '''
You are a professional fashion stylist. Given this wardrobe:
${jsonEncode(garmentList)}

Create $count outfit suggestions${occasion != null ? ' for $occasion' : ''}${season != null ? ' suitable for $season' : ''}${weather != null ? ' with $weather weather' : ''}.

Respond ONLY with a JSON array, no other text:
[
  {
    "name": "outfit name",
    "garments": ["exact garment names from the list above"],
    "description": "brief style description",
    "occasion": "occasion label",
    "tip": "one styling tip"
  }
]
''';

    final response = await _dio.post('/messages', data: {
      'model': _model,
      'max_tokens': 1024,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
    });

    final content =
        response.data['content'][0]['text'] as String;

    // Extract JSON from the response
    final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(content);
    if (jsonMatch == null) return [];

    final suggestions = jsonDecode(jsonMatch.group(0)!) as List<dynamic>;
    return suggestions
        .map((s) => OutfitSuggestion.fromJson(
            s as Map<String, dynamic>, garments))
        .toList();
  }
}

class OutfitSuggestion {
  final String name;
  final List<Garment> garments;
  final String description;
  final String occasion;
  final String tip;

  const OutfitSuggestion({
    required this.name,
    required this.garments,
    required this.description,
    required this.occasion,
    required this.tip,
  });

  factory OutfitSuggestion.fromJson(
      Map<String, dynamic> json, List<Garment> allGarments) {
    final names = List<String>.from(json['garments'] ?? []);
    final matched = allGarments
        .where((g) => names.any(
            (n) => g.name.toLowerCase().contains(n.toLowerCase()) ||
                n.toLowerCase().contains(g.name.toLowerCase())))
        .toList();

    return OutfitSuggestion(
      name: json['name'] as String? ?? 'Outfit',
      garments: matched,
      description: json['description'] as String? ?? '',
      occasion: json['occasion'] as String? ?? 'Casual',
      tip: json['tip'] as String? ?? '',
    );
  }
}
