import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../constants/app_constants.dart';

String formatDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);
String formatShortDate(DateTime date) => DateFormat('MMM d').format(date);

String formatPrice(double amount, [String currency = AppConstants.defaultCurrency]) {
  final symbol = AppConstants.currencySymbols[currency] ?? currency;
  final decimalDigits = AppConstants.zeroDecimalCurrencies.contains(currency) ? 0 : 2;
  // es_CO's default currency pattern places the symbol as a suffix
  // ("150.000 $"); a custom pattern forces the "$150.000" prefix style
  // Colombian users expect, while keeping the locale's separators
  // (period for thousands, comma for decimals).
  final decimals = decimalDigits > 0 ? '.${'0' * decimalDigits}' : '';
  return NumberFormat.currency(
    locale: 'es_CO',
    symbol: symbol,
    decimalDigits: decimalDigits,
    customPattern: '¤#,##0$decimals',
  ).format(amount);
}

Color categoryColor(String category) {
  final map = {
    'Tops': AppColors.categoryTops,
    'Bottoms': AppColors.categoryBottoms,
    'Shoes': AppColors.categoryShoes,
    'Accessories': AppColors.categoryAccessories,
    'Outerwear': AppColors.categoryOuterwear,
    'Dresses': AppColors.categoryDresses,
    'Bags': AppColors.categoryBags,
  };
  return map[category] ?? AppColors.primary;
}

Color seasonColor(String season) {
  final map = {
    'Spring': AppColors.seasonSpring,
    'Summer': AppColors.seasonSummer,
    'Fall': AppColors.seasonFall,
    'Winter': AppColors.seasonWinter,
  };
  return map[season] ?? AppColors.primary;
}

String categoryIcon(String category) {
  final map = {
    'Tops': '👕',
    'Bottoms': '👖',
    'Dresses': '👗',
    'Outerwear': '🧥',
    'Shoes': '👟',
    'Bags': '👜',
    'Accessories': '💍',
    'Activewear': '🏃',
    'Swimwear': '🩱',
    'Underwear': '🩲',
  };
  return map[category] ?? '👔';
}
