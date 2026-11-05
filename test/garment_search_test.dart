import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_closet/data/models/garment.dart';

void main() {
  final garment = Garment(
    id: '1',
    userId: 'u',
    name: 'Linen Shirt',
    category: 'Tops',
    brand: 'Zara',
    color: 'White',
    createdAt: DateTime(2026),
  );

  test('a blank query matches everything', () {
    expect(garment.matchesQuery(''), isTrue);
    expect(garment.matchesQuery('   '), isTrue);
  });

  test('matching ignores case and covers descriptive fields', () {
    expect(garment.matchesQuery('LINEN'), isTrue);
    expect(garment.matchesQuery('zara'), isTrue);
    expect(garment.matchesQuery('white'), isTrue);
    expect(garment.matchesQuery('tops'), isTrue);
  });

  test('every word must match, in any order', () {
    expect(garment.matchesQuery('white shirt'), isTrue);
    expect(garment.matchesQuery('white shoes'), isFalse);
  });
}
