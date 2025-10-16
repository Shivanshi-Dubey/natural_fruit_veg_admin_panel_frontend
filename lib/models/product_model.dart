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
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      discountPrice: json['discountPrice'] != null
          ? (json['discountPrice'] as num).toDouble()
          : null,
      imageUrl: json['imageUrl'],
      category: json['category'],
      quantity: json['quantity'],
      stock: json['stock'], // ✅ Added
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'discountPrice': discountPrice,
      'imageUrl': imageUrl,
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
