enum PreparationArea {
  kitchen('Kitchen'),
  bar('Bar'),
  none('None');

  const PreparationArea(this.displayName);
  final String displayName;
}

class Product {
  final String id;
  final String name;
  final String sku;
  final double price;
  final String category;
  final bool isAlcoholic;
  final bool isActive;
  final String? description;
  final String? imageUrl;
  final int stockQuantity;
  final String unit; // pcs, ml, kg, etc.
  final double? cost;
  final List<ProductModifier> modifiers;
  final PreparationArea preparationArea;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.price,
    required this.category,
    required this.isAlcoholic,
    this.isActive = true,
    this.description,
    this.imageUrl,
    required this.stockQuantity,
    this.unit = 'pcs',
    this.cost,
    this.modifiers = const [],
    this.preparationArea = PreparationArea.kitchen,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isInStock => stockQuantity > 0;

  double get profitMargin => cost != null ? ((price - cost!) / price) * 100 : 0;

  Product copyWith({
    String? id,
    String? name,
    String? sku,
    double? price,
    String? category,
    bool? isAlcoholic,
    bool? isActive,
    String? description,
    String? imageUrl,
    int? stockQuantity,
    String? unit,
    double? cost,
    List<ProductModifier>? modifiers,
    PreparationArea? preparationArea,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      category: category ?? this.category,
      isAlcoholic: isAlcoholic ?? this.isAlcoholic,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      unit: unit ?? this.unit,
      cost: cost ?? this.cost,
      modifiers: modifiers ?? this.modifiers,
      preparationArea: preparationArea ?? this.preparationArea,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'price': price,
      'category': category,
      'isAlcoholic': isAlcoholic,
      'isActive': isActive,
      'description': description,
      'imageUrl': imageUrl,
      'stockQuantity': stockQuantity,
      'unit': unit,
      'cost': cost,
      'modifiers': modifiers.map((m) => m.toJson()).toList(),
      'preparationArea': preparationArea.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      isAlcoholic: json['isAlcoholic'] as bool,
      isActive: json['isActive'] as bool? ?? true,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      stockQuantity: json['stockQuantity'] as int? ?? 0,
      unit: json['unit'] as String? ?? 'pcs',
      cost: (json['cost'] as num?)?.toDouble(),
      modifiers:
          (json['modifiers'] as List<dynamic>?)
              ?.map((m) => ProductModifier.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      preparationArea: PreparationArea.values.firstWhere(
        (area) => area.name == json['preparationArea'],
        orElse: () => PreparationArea.kitchen,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class ProductModifier {
  final String id;
  final String name;
  final double price;
  final bool isRequired;

  const ProductModifier({
    required this.id,
    required this.name,
    required this.price,
    this.isRequired = false,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'price': price, 'isRequired': isRequired};
  }

  factory ProductModifier.fromJson(Map<String, dynamic> json) {
    return ProductModifier(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      isRequired: json['isRequired'] as bool? ?? false,
    );
  }
}
