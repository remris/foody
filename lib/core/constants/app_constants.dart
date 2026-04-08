class AppConstants {
  AppConstants._();

  // App
  static const String appName = 'Kokomi';

  // Supabase Tables
  static const String tableIngredients = 'ingredients';
  static const String tableUserInventory = 'user_inventory';
  static const String tableRecipes = 'recipes';
  static const String tableRecipeIngredients = 'recipe_ingredients';
  static const String tableShoppingList = 'shopping_list_items';
  static const String tableShoppingLists = 'shopping_lists';
  static const String tableSavedRecipes = 'saved_recipes';
  static const String tableScannedProducts = 'scanned_products';

  // Storage Buckets
  static const String bucketFoodImages = 'food_images';
  static const String bucketReceiptImages = 'receipt_images';

  // OpenFoodFacts
  static const String openFoodFactsBaseUrl =
      'https://world.openfoodfacts.org/api/v0/product';

  // OpenAI
  static const String openAiBaseUrl = 'https://api.openai.com/v1';
  static const String openAiModel = 'gpt-3.5-turbo';

  // Expiry warning threshold
  static const int expiryWarningDays = 3;
}

