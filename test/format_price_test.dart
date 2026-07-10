import 'package:flutter_test/flutter_test.dart';
import 'package:crayoli_closet/core/utils/helpers.dart';

void main() {
  group('formatPrice', () {
    test('defaults to COP with no decimals and a prefixed symbol', () {
      expect(formatPrice(150000), r'$150.000');
    });

    test('formats USD with two decimals', () {
      expect(formatPrice(45.5, 'USD'), r'US$45,50');
    });

    test('formats EUR with two decimals', () {
      expect(formatPrice(39.99, 'EUR'), '€39,99');
    });

    test('falls back to the currency code for unknown currencies', () {
      expect(formatPrice(10, 'XYZ'), 'XYZ10,00');
    });
  });
}
