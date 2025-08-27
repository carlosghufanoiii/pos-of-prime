enum CategoryType {
  food('Food'),
  alcohol('Alcohol');

  const CategoryType(this.displayName);
  final String displayName;
}

class MenuCategory {
  final String id;
  final String name;
  final String description;
  final CategoryType type;
  final bool isActive;
  final int sortOrder;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MenuCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    this.isActive = true,
    this.sortOrder = 0,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  MenuCategory copyWith({
    String? id,
    String? name,
    String? description,
    CategoryType? type,
    bool? isActive,
    int? sortOrder,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: CategoryType.values.firstWhere(
        (type) => type.name == json['type'],
        orElse: () => CategoryType.food,
      ),
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Predefined category templates for quick setup
class DefaultMenuCategories {
  static List<MenuCategory> get foodCategories => [
    MenuCategory(
      id: 'food_starters',
      name: 'Starters',
      description: 'Appetizers and small plates',
      type: CategoryType.food,
      sortOrder: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    MenuCategory(
      id: 'food_soups_salads',
      name: 'Soups & Salads',
      description: 'Fresh soups and garden salads',
      type: CategoryType.food,
      sortOrder: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    MenuCategory(
      id: 'food_main_dishes',
      name: 'Main Dishes',
      description: 'Hearty main courses',
      type: CategoryType.food,
      sortOrder: 3,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    MenuCategory(
      id: 'food_pizza_pasta',
      name: 'Pizza & Pasta',
      description: 'Italian favorites',
      type: CategoryType.food,
      sortOrder: 4,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    MenuCategory(
      id: 'food_desserts',
      name: 'Desserts',
      description: 'Sweet treats and desserts',
      type: CategoryType.food,
      sortOrder: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  static List<MenuCategory> get alcoholCategories => [
    MenuCategory(
      id: 'alcohol_cocktails',
      name: 'Cocktails',
      description: 'Premium mixed drinks and specialty cocktails',
      type: CategoryType.alcohol,
      sortOrder: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    MenuCategory(
      id: 'alcohol_beer',
      name: 'Beer',
      description: 'Draft and bottled beers',
      type: CategoryType.alcohol,
      sortOrder: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    MenuCategory(
      id: 'alcohol_wine',
      name: 'Wine',
      description: 'Red, white, and sparkling wines',
      type: CategoryType.alcohol,
      sortOrder: 3,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    MenuCategory(
      id: 'alcohol_spirits',
      name: 'Spirits',
      description: 'Whiskey, vodka, rum, and premium spirits',
      type: CategoryType.alcohol,
      sortOrder: 4,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    MenuCategory(
      id: 'alcohol_shots',
      name: 'Shots',
      description: 'Party shots and quick drinks',
      type: CategoryType.alcohol,
      sortOrder: 5,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    MenuCategory(
      id: 'alcohol_non_alcoholic',
      name: 'Non-Alcoholic',
      description: 'Mocktails and alcohol-free beverages',
      type: CategoryType.alcohol,
      sortOrder: 6,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  static List<MenuCategory> get allCategories => [
    ...foodCategories,
    ...alcoholCategories,
  ];
}
