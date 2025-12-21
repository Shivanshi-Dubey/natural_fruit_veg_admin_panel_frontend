class OrderItem {
  final String name;
  final double price;
  final int quantity;

  const OrderItem({
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'],
    );
  }
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalPrice;
  final String status;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'],
      userId: json['userId'],
      items: (json['products'] as List)
          .map((e) => OrderItem.fromJson(e))
          .toList(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  double get totalAmount =>
      items.fold(0, (sum, i) => sum + (i.price * i.quantity));
}
