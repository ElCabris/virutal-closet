class AppConstants {
  AppConstants._();

  static const String appName = 'Crayoli Closet';
  static const String appTagline = 'Your closet, curated.';

  // Supabase tables
  static const String tableGarments = 'garments';
  static const String tableGarmentImages = 'garment_images';
  static const String tableOutfits = 'outfits';
  static const String tableOutfitGarments = 'outfit_garments';
  static const String tableCalendarEntries = 'calendar_entries';
  static const String tableProfiles = 'profiles';

  // Storage buckets
  static const String bucketGarments = 'garments';
  static const String bucketOutfits = 'outfits';
  static const String bucketAvatars = 'avatars';

  // Garment categories
  static const List<String> garmentCategories = [
    'Tops',
    'Bottoms',
    'Dresses',
    'Outerwear',
    'Shoes',
    'Bags',
    'Accessories',
    'Activewear',
    'Swimwear',
    'Underwear',
  ];

  // Occasions
  static const List<String> occasions = [
    'Casual',
    'Work',
    'Formal',
    'Sport',
    'Evening',
    'Beach',
    'Travel',
    'Date Night',
  ];

  // Seasons
  static const List<String> seasons = [
    'Spring',
    'Summer',
    'Fall',
    'Winter',
    'All Season',
  ];

  // Colors
  static const List<String> garmentColors = [
    'Black',
    'White',
    'Gray',
    'Beige',
    'Brown',
    'Navy',
    'Blue',
    'Green',
    'Red',
    'Pink',
    'Purple',
    'Yellow',
    'Orange',
    'Gold',
    'Silver',
    'Multicolor',
  ];
}
