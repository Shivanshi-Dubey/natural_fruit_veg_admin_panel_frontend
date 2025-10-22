import 'product_model.dart';

class Order {
  final String id;
  final String userId;
  final List<Product> products;
  final double totalPrice;
  final String status; // e.g., "Pending", "Shipped", "Delivered"
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.userId,
    required this.products,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      status: json['status'] ?? 'Pending',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'products': products.map((p) => p.toJson()).toList(),
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// ✅ Getter correctly placed inside the class
  double get totalAmount {
    return products.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }
}
