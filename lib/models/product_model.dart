class Product {
  final String? id;
  final String name;
  final double price;
  final String imagePath;
  final String category;
  final int quantity;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.imagePath,
    required this.category,
    required this.quantity,
  });

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? imagePath,
    String? category,
    int? quantity,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      imagePath: json['imagePath'] ?? '',
      category: json['category'] ?? '',
      quantity: json['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'imagePath': imagePath,
      'category': category,
      'quantity': quantity,
    };
  }
}
