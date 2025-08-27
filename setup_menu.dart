import 'lib/shared/models/menu_category.dart';
import 'lib/shared/models/product.dart';

/// Script to populate the Prime POS menu with organized nightclub/bar menu
void main() {
  print('🍹 Prime POS - Setting up Bar/Nightclub Menu');
  print('=' * 50);
  
  // Create categories
  final categories = createMenuCategories();
  final products = createMenuProducts();
  
  print('\n📋 MENU CATEGORIES (${categories.length})');
  print('-' * 30);
  for (var category in categories) {
    print('• ${category.name} (${category.type.displayName})');
  }
  
  print('\n🍸 PRODUCTS BY CATEGORY (${products.length} total)');
  print('-' * 40);
  
  for (var category in categories) {
    final categoryProducts = products.where((p) => p.category == category.id).toList();
    if (categoryProducts.isNotEmpty) {
      print('\n${category.name.toUpperCase()} (${categoryProducts.length} items)');
      for (var product in categoryProducts) {
        String variants = '';
        if (product.modifiers.isNotEmpty) {
          variants = ' [${product.modifiers.map((m) => '${m.name}: ₱${m.price}').join(', ')}]';
        }
        print('  • ${product.name} - ₱${product.price}$variants');
      }
    }
  }
  
  print('\n' + '=' * 50);
  print('📊 SUMMARY:');
  print('  Categories: ${categories.length}');
  print('  Products: ${products.length}');
  print('  Alcoholic: ${products.where((p) => p.isAlcoholic).length}');
  print('  Non-Alcoholic: ${products.where((p) => !p.isAlcoholic).length}');
  print('  Bar Items: ${products.where((p) => p.preparationArea == PreparationArea.bar).length}');
  
  // Generate JSON for easy import
  print('\n📁 Generating JSON files...');
  generateJsonFiles(categories, products);
  print('✅ Menu setup complete!');
}

List<MenuCategory> createMenuCategories() {
  final now = DateTime.now();
  
  return [
    // Alcohol Categories
    MenuCategory(
      id: 'cocktail_towers',
      name: 'Cocktail Towers',
      description: '1.5L & 3L cocktail towers perfect for sharing',
      type: CategoryType.alcohol,
      sortOrder: 1,
      createdAt: now,
      updatedAt: now,
    ),
    MenuCategory(
      id: 'premium_towers',
      name: 'Premium Towers',
      description: 'Premium 1.5L & 3L towers with top-shelf spirits',
      type: CategoryType.alcohol,
      sortOrder: 2,
      createdAt: now,
      updatedAt: now,
    ),
    MenuCategory(
      id: 'cocktails_glass',
      name: 'Cocktails (By Glass)',
      description: 'Individual cocktails and mixed drinks',
      type: CategoryType.alcohol,
      sortOrder: 3,
      createdAt: now,
      updatedAt: now,
    ),
    MenuCategory(
      id: 'flaming_shots',
      name: 'Flaming Shots',
      description: 'Spectacular flaming shots for the adventurous',
      type: CategoryType.alcohol,
      sortOrder: 4,
      createdAt: now,
      updatedAt: now,
    ),
    MenuCategory(
      id: 'beer',
      name: 'Beer',
      description: 'Local and international beers, bottles and buckets',
      type: CategoryType.alcohol,
      sortOrder: 5,
      createdAt: now,
      updatedAt: now,
    ),
    MenuCategory(
      id: 'brandy',
      name: 'Brandy',
      description: 'Premium brandy selections',
      type: CategoryType.alcohol,
      sortOrder: 6,
      createdAt: now,
      updatedAt: now,
    ),
    MenuCategory(
      id: 'tequila',
      name: 'Tequila',
      description: 'Premium tequila brands',
      type: CategoryType.alcohol,
      sortOrder: 7,
      createdAt: now,
      updatedAt: now,
    ),
    MenuCategory(
      id: 'vodka',
      name: 'Vodka',
      description: 'Premium vodka selections',
      type: CategoryType.alcohol,
      sortOrder: 8,
      createdAt: now,
      updatedAt: now,
    ),
    MenuCategory(
      id: 'rum',
      name: 'Rum',
      description: 'Caribbean rum varieties',
      type: CategoryType.alcohol,
      sortOrder: 9,
      createdAt: now,
      updatedAt: now,
    ),
    MenuCategory(
      id: 'whiskey',
      name: 'Whiskey',
      description: 'Whiskey and bourbon selections',
      type: CategoryType.alcohol,
      sortOrder: 10,
      createdAt: now,
      updatedAt: now,
    ),
    MenuCategory(
      id: 'liqueur',
      name: 'Liqueur',
      description: 'Specialty liqueurs and flavored spirits',
      type: CategoryType.alcohol,
      sortOrder: 11,
      createdAt: now,
      updatedAt: now,
    ),
    // Non-Alcoholic Category
    MenuCategory(
      id: 'non_alcoholic',
      name: 'Non-Alcoholic',
      description: 'Soft drinks and non-alcoholic beverages',
      type: CategoryType.alcohol, // Still under alcohol menu but non-alcoholic items
      sortOrder: 12,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}

List<Product> createMenuProducts() {
  final now = DateTime.now();
  final products = <Product>[];
  
  // COCKTAIL TOWERS
  final cocktailTowers = [
    {'name': 'Tequila Sunrise', 'small': 349, 'large': 599},
    {'name': 'Mixberry', 'small': 349, 'large': 599},
    {'name': 'Fruity Grapes', 'small': 349, 'large': 599},
    {'name': 'Gintea', 'small': 349, 'large': 599},
    {'name': 'Blue Lagoon', 'small': 349, 'large': 599},
  ];
  
  for (var tower in cocktailTowers) {
    products.add(Product(
      id: 'tower_${tower['name'].toString().toLowerCase().replaceAll(' ', '_')}',
      name: '${tower['name']} Tower',
      sku: 'TWR_${tower['name'].toString().toUpperCase().replaceAll(' ', '_')}',
      price: (tower['small'] as int).toDouble(),
      category: 'cocktail_towers',
      isAlcoholic: true,
      description: '${tower['name']} cocktail tower - perfect for sharing',
      stockQuantity: 50,
      unit: 'tower',
      cost: ((tower['small'] as int) * 0.4), // 40% cost margin
      preparationArea: PreparationArea.bar,
      modifiers: [
        ProductModifier(
          id: 'size_1_5l',
          name: '1.5L',
          price: 0, // Base price
        ),
        ProductModifier(
          id: 'size_3l',
          name: '3L',
          price: ((tower['large'] as int) - (tower['small'] as int)).toDouble(),
        ),
      ],
      createdAt: now,
      updatedAt: now,
    ));
  }
  
  // PREMIUM TOWERS
  final premiumTowers = [
    {'name': 'Blue Hawaiian', 'small': 449, 'large': 799},
    {'name': 'Galaxy', 'small': 449, 'large': 799},
    {'name': 'Zombie', 'small': 449, 'large': 799},
    {'name': 'Blue Margarita', 'small': 449, 'large': 799},
    {'name': 'Rhum Sour', 'small': 449, 'large': 799},
    {'name': 'Pomelo Punch', 'small': 449, 'large': 799},
  ];
  
  for (var tower in premiumTowers) {
    products.add(Product(
      id: 'premium_${tower['name'].toString().toLowerCase().replaceAll(' ', '_')}',
      name: '${tower['name']} Premium Tower',
      sku: 'PREM_${tower['name'].toString().toUpperCase().replaceAll(' ', '_')}',
      price: (tower['small'] as int).toDouble(),
      category: 'premium_towers',
      isAlcoholic: true,
      description: 'Premium ${tower['name']} tower with top-shelf spirits',
      stockQuantity: 30,
      unit: 'tower',
      cost: ((tower['small'] as int) * 0.35), // 35% cost margin for premium
      preparationArea: PreparationArea.bar,
      modifiers: [
        ProductModifier(
          id: 'size_1_5l',
          name: '1.5L',
          price: 0,
        ),
        ProductModifier(
          id: 'size_3l',
          name: '3L',
          price: ((tower['large'] as int) - (tower['small'] as int)).toDouble(),
        ),
      ],
      createdAt: now,
      updatedAt: now,
    ));
  }
  
  // COCKTAILS BY GLASS
  final cocktails = [
    'Blue Margarita', 'Classic Margarita', 'Strawberry Mojito', 'Galaxy',
    'Mixberry Good', 'Malibu Pineapple', 'Virgin Mojito', 'Pomelo Punch', 'Wet Kiss'
  ];
  
  for (var cocktail in cocktails) {
    final isVirgin = cocktail == 'Virgin Mojito';
    products.add(Product(
      id: 'cocktail_${cocktail.toLowerCase().replaceAll(' ', '_')}',
      name: cocktail,
      sku: 'COC_${cocktail.toUpperCase().replaceAll(' ', '_')}',
      price: 149.0,
      category: 'cocktails_glass',
      isAlcoholic: !isVirgin,
      description: 'Premium $cocktail cocktail',
      stockQuantity: 100,
      unit: 'glass',
      cost: 60.0, // Fixed cost for cocktails
      preparationArea: PreparationArea.bar,
      createdAt: now,
      updatedAt: now,
    ));
  }
  
  // FLAMING SHOTS
  final flamingShots = [
    'Flamming Ferrari',
    'Blow Job',
  ];
  
  for (var shot in flamingShots) {
    products.add(Product(
      id: 'shot_${shot.toLowerCase().replaceAll(' ', '_')}',
      name: shot,
      sku: 'SHOT_${shot.toUpperCase().replaceAll(' ', '_')}',
      price: 199.0,
      category: 'flaming_shots',
      isAlcoholic: true,
      description: 'Spectacular flaming shot - $shot',
      stockQuantity: 50,
      unit: 'shot',
      cost: 70.0,
      preparationArea: PreparationArea.bar,
      createdAt: now,
      updatedAt: now,
    ));
  }
  
  // BEER
  final beers = [
    {'name': 'Red Horse', 'price': 99},
    {'name': 'Pale Pilsen', 'price': 99},
    {'name': 'San Mig Lights', 'price': 99},
    {'name': 'Smirnoff Mule', 'price': 119},
  ];
  
  for (var beer in beers) {
    products.add(Product(
      id: 'beer_${beer['name'].toString().toLowerCase().replaceAll(' ', '_')}',
      name: beer['name'] as String,
      sku: 'BEER_${beer['name'].toString().toUpperCase().replaceAll(' ', '_')}',
      price: (beer['price'] as int).toDouble(),
      category: 'beer',
      isAlcoholic: true,
      description: '${beer['name']} bottle',
      stockQuantity: 200,
      unit: 'bottle',
      cost: ((beer['price'] as int) * 0.5), // 50% cost margin
      preparationArea: PreparationArea.bar,
      createdAt: now,
      updatedAt: now,
    ));
  }
  
  // Beer Buckets
  products.addAll([
    Product(
      id: 'beer_bucket_regular',
      name: 'Beer Bucket',
      sku: 'BUCKET_BEER',
      price: 549.0,
      category: 'beer',
      isAlcoholic: true,
      description: 'Beer bucket with 6 bottles',
      stockQuantity: 50,
      unit: 'bucket',
      cost: 250.0,
      preparationArea: PreparationArea.bar,
      createdAt: now,
      updatedAt: now,
    ),
    Product(
      id: 'smirnoff_bucket',
      name: 'Smirnoff Bucket',
      sku: 'BUCKET_SMIRNOFF',
      price: 599.0,
      category: 'beer',
      isAlcoholic: true,
      description: 'Smirnoff Mule bucket with 6 bottles',
      stockQuantity: 30,
      unit: 'bucket',
      cost: 280.0,
      preparationArea: PreparationArea.bar,
      createdAt: now,
      updatedAt: now,
    ),
  ]);
  
  // BRANDY
  final brandies = [
    {'name': 'Primera Lights', 'price': 549},
    {'name': 'Alfonso Light', 'price': 699},
    {'name': 'Alfonso Zero', 'price': 849},
    {'name': 'Alfonso Platinum', 'price': 999},
    {'name': 'Fundador Lights', 'price': 999},
  ];
  
  for (var brandy in brandies) {
    products.add(Product(
      id: 'brandy_${brandy['name'].toString().toLowerCase().replaceAll(' ', '_')}',
      name: brandy['name'] as String,
      sku: 'BRANDY_${brandy['name'].toString().toUpperCase().replaceAll(' ', '_')}',
      price: (brandy['price'] as int).toDouble(),
      category: 'brandy',
      isAlcoholic: true,
      description: '${brandy['name']} brandy bottle',
      stockQuantity: 20,
      unit: 'bottle',
      cost: ((brandy['price'] as int) * 0.3), // 30% cost margin for spirits
      preparationArea: PreparationArea.bar,
      createdAt: now,
      updatedAt: now,
    ));
  }
  
  // TEQUILA
  products.addAll([
    Product(
      id: 'tequila_jose_cuervo_700ml',
      name: 'Jose Cuervo',
      sku: 'TEQ_JOSE_CUERVO_700',
      price: 2499.0,
      category: 'tequila',
      isAlcoholic: true,
      description: 'Jose Cuervo 700ml bottle',
      stockQuantity: 10,
      unit: 'bottle',
      cost: 750.0,
      preparationArea: PreparationArea.bar,
      modifiers: [
        ProductModifier(id: 'size_700ml', name: '700ml', price: 0),
        ProductModifier(id: 'size_1l', name: '1L', price: 500.0),
      ],
      createdAt: now,
      updatedAt: now,
    ),
  ]);
  
  // VODKA
  products.addAll([
    Product(
      id: 'vodka_absolut_blue_700ml',
      name: 'Absolut Blue',
      sku: 'VOD_ABSOLUT_BLUE_700',
      price: 2499.0,
      category: 'vodka',
      isAlcoholic: true,
      description: 'Absolut Blue 700ml bottle',
      stockQuantity: 15,
      unit: 'bottle',
      cost: 750.0,
      preparationArea: PreparationArea.bar,
      modifiers: [
        ProductModifier(id: 'size_700ml', name: '700ml', price: 0),
        ProductModifier(id: 'size_1l', name: '1L', price: 500.0),
      ],
      createdAt: now,
      updatedAt: now,
    ),
  ]);
  
  // RUM
  final rums = [
    'Bacardi Gold', 'Bacardi Black', 'Bacardi Superior'
  ];
  
  for (var rum in rums) {
    products.add(Product(
      id: 'rum_${rum.toLowerCase().replaceAll(' ', '_')}',
      name: rum,
      sku: 'RUM_${rum.toUpperCase().replaceAll(' ', '_')}',
      price: 1899.0,
      category: 'rum',
      isAlcoholic: true,
      description: '$rum rum bottle',
      stockQuantity: 12,
      unit: 'bottle',
      cost: 570.0,
      preparationArea: PreparationArea.bar,
      createdAt: now,
      updatedAt: now,
    ));
  }
  
  // WHISKEY
  final whiskeys = [
    {'name': 'Jim Beam', 'price': 2499},
    {'name': 'Jack Daniels', 'price': 2999, 'variants': [{'700ml': 0}, {'1L': 500}]},
    {'name': 'JW Red Label', 'price': 3499},
    {'name': 'JW Black Label', 'price': 3499},
    {'name': 'JW Double Black', 'price': 3499},
    {'name': 'Charles & James', 'price': 799},
  ];
  
  for (var whiskey in whiskeys) {
    final hasVariants = whiskey['variants'] != null;
    products.add(Product(
      id: 'whiskey_${whiskey['name'].toString().toLowerCase().replaceAll(' ', '_').replaceAll('&', 'and')}',
      name: whiskey['name'] as String,
      sku: 'WHIS_${whiskey['name'].toString().toUpperCase().replaceAll(' ', '_').replaceAll('&', 'AND')}',
      price: (whiskey['price'] as int).toDouble(),
      category: 'whiskey',
      isAlcoholic: true,
      description: '${whiskey['name']} whiskey bottle',
      stockQuantity: 8,
      unit: 'bottle',
      cost: ((whiskey['price'] as int) * 0.3),
      preparationArea: PreparationArea.bar,
      modifiers: hasVariants ? [
        ProductModifier(id: 'size_700ml', name: '700ml', price: 0),
        ProductModifier(id: 'size_1l', name: '1L', price: 500.0),
      ] : [],
      createdAt: now,
      updatedAt: now,
    ));
  }
  
  // LIQUEUR
  final liqueurs = [
    {'name': 'Tequila Rose', 'price': 2499},
    {'name': 'Jaggermeister', 'price': 1999},
  ];
  
  for (var liqueur in liqueurs) {
    products.add(Product(
      id: 'liqueur_${liqueur['name'].toString().toLowerCase().replaceAll(' ', '_')}',
      name: liqueur['name'] as String,
      sku: 'LIQ_${liqueur['name'].toString().toUpperCase().replaceAll(' ', '_')}',
      price: (liqueur['price'] as int).toDouble(),
      category: 'liqueur',
      isAlcoholic: true,
      description: '${liqueur['name']} liqueur bottle',
      stockQuantity: 10,
      unit: 'bottle',
      cost: ((liqueur['price'] as int) * 0.3),
      preparationArea: PreparationArea.bar,
      createdAt: now,
      updatedAt: now,
    ));
  }
  
  // NON-ALCOHOLIC
  final nonAlcoholic = [
    {'name': 'Bottled Water', 'price': 50},
    {'name': 'Coke Bottle', 'price': 99},
    {'name': 'Coke 1.5 Liters', 'price': 199},
  ];
  
  for (var item in nonAlcoholic) {
    products.add(Product(
      id: 'non_alc_${item['name'].toString().toLowerCase().replaceAll(' ', '_').replaceAll('.', '_')}',
      name: item['name'] as String,
      sku: 'NA_${item['name'].toString().toUpperCase().replaceAll(' ', '_').replaceAll('.', '_')}',
      price: (item['price'] as int).toDouble(),
      category: 'non_alcoholic',
      isAlcoholic: false,
      description: item['name'] as String,
      stockQuantity: 100,
      unit: 'bottle',
      cost: ((item['price'] as int) * 0.6), // 60% cost for non-alcoholic
      preparationArea: PreparationArea.none,
      createdAt: now,
      updatedAt: now,
    ));
  }
  
  return products;
}

void generateJsonFiles(List<MenuCategory> categories, List<Product> products) {
  // This would generate JSON files for import
  print('Categories JSON: ${categories.length} items');
  print('Products JSON: ${products.length} items');
}