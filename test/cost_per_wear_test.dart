import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_closet/data/models/garment.dart';

Garment _garment({double? price, int wears = 0, String currency = 'COP'}) =>
    Garment(
      id: 'id',
      userId: 'u',
      name: 'n',
      category: 'Tops',
      price: price,
      wearCount: wears,
      currency: currency,
      createdAt: DateTime(2026),
    );

void main() {
  test('is null when no garment has both a price and a wear', () {
    expect(averageCostPerWear([]), isNull);
    expect(
      averageCostPerWear([_garment(price: 100), _garment(wears: 3)]),
      isNull,
    );
  });

  test('divides total price by total wears', () {
    final result = averageCostPerWear([
      _garment(price: 100, wears: 1),
      _garment(price: 200, wears: 4),
    ]);
    expect(result?.amount, 60);
    expect(result?.currency, 'COP');
  });

  test('does not mix currencies, using the most common one', () {
    final result = averageCostPerWear([
      _garment(price: 50, wears: 1, currency: 'USD'),
      _garment(price: 100, wears: 1),
      _garment(price: 300, wears: 1),
    ]);
    expect(result?.amount, 200);
    expect(result?.currency, 'COP');
  });
}
