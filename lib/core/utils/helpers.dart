import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../constants/app_constants.dart';

String formatDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);
String formatShortDate(DateTime date) => DateFormat('MMM d').format(date);
String formatCurrency(double amount) => NumberFormat.currency(symbol: '\$').format(amount);

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
