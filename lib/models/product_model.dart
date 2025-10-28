class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? discountPrice; // ✅ Optional discounted price
  final String imageUrl;
  final String category;
  final int quantity; // ✅ Quantity in cart
  final int stock; // ✅ Stock available in store
  
  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.discountPrice,
    required this.imageUrl,
    required this.category,
    required this.quantity,
    required this.stock, // ✅ Added
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      discountPrice: json['discountPrice'] == null
          ? null
          : (json['discountPrice'] is num)
              ? (json['discountPrice'] as num).toDouble()
              : double.tryParse(json['discountPrice']?.toString() ?? ''),
      imageUrl: (json['imageUrl'] ?? json['imagePath'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      quantity: (json['quantity'] is int)
          ? json['quantity'] as int
          : int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      stock: (json['stock'] is int)
          ? json['stock'] as int
          : int.tryParse(json['stock']?.toString() ?? '0') ?? 0, // ✅ Added
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Prefer backend-friendly keys; include both for compatibility
      '_id': id,
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'imageUrl': imageUrl,
      'imagePath': imageUrl,
      'category': category,
      'quantity': quantity,
      'stock': stock, // ✅ Added
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? discountPrice,
    String? imageUrl,
    String? category,
    int? quantity,
    int? stock, // ✅ Added
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      discountPrice: discountPrice ?? this.discountPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      stock: stock ?? this.stock, // ✅ Added
    );
  }
}
