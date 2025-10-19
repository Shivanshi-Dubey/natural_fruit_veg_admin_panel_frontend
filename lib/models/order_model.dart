import 'product_model.dart';

class Order {
  final String id;
  final String status;
  final String user;
  final List<Product> products;
  final DateTime createdAt;
  final double totalPrice;

  const Order({
    required this.id,
    required this.status,
    required this.user,
    required this.products,
    required this.createdAt,
    required this.totalPrice,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Safely decode products list
    List<Product> productList = [];
    if (json['products'] != null) {
      productList = List<Map<String, dynamic>>.from(json['products'])
          .map((productJson) {
        // Handle nested product info or flat structure
        if (productJson.containsKey('product') && productJson['product'] != null) {
          return Product.fromJson({
            '_id': productJson['product']['_id'] ?? '',
            'name': productJson['product']['name'] ?? '',
            'price': productJson['product']['price'] ?? 0,
            'imagePath': productJson['product']['image'] ?? '',
            'category': '',
            'quantity': productJson['quantity'] ?? 1,
          });
        } else {
          return Product.fromJson({
            '_id': productJson['_id'] ?? '',
            'name': productJson['name'] ?? '',
            'price': productJson['price'] ?? 0,
            'imagePath': productJson['image'] ?? '',
            'category': '',
            'quantity': productJson['quantity'] ?? 1,
          });
        }
      }).toList();
    }

    double total = 0.0;
    for (var p in productList) {
      total += (p.price * p.quantity);
    }

    return Order(
      id: json['_id'] ?? '',
      status: json['status'] ?? 'Pending',
      user: json['user'] ?? '',
      products: productList,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      totalPrice: total,
    );
  }
}
