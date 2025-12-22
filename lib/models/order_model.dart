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
    final product = json['product'] ?? {};
    return OrderItem(
      name: (product['name'] ?? json['name'] ?? '') as String,
      price: (product['price'] ?? json['price'] ?? 0).toDouble(),
      quantity: (json['quantity'] ?? 0) as int,
    );
  }
}

class Order {
  final String id;
  final String customerName;
  final List<OrderItem> items;
  final double deliveryCharge;
  final String orderStatus;
  final String paymentStatus;
  final DateTime createdAt;
  final String? deliveryBoyName;
  final String? deliveryBoyId;

  const Order({
    required this.id,
    required this.customerName,
    required this.items,
    required this.deliveryCharge,
    required this.orderStatus,
    required this.paymentStatus,
    required this.createdAt,
    this.deliveryBoyName,
    this.deliveryBoyId,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    final deliveryBoy = json['deliveryBoy'];
    final List productsJson = (json['products'] as List? ?? []);

    return Order(
      id: (json['_id'] ?? '').toString(),
      customerName: (user['name'] ?? 'Unknown') as String,
      items: productsJson.map((e) => OrderItem.fromJson(e)).toList(),
      deliveryCharge: (json['deliveryCharge'] ?? 0).toDouble(),
      orderStatus: (json['orderStatus'] ?? 'placed') as String,
      paymentStatus: (json['paymentStatus'] ?? 'pending') as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      deliveryBoyName: deliveryBoy != null ? deliveryBoy['name'] as String? : null,
      deliveryBoyId:
          deliveryBoy != null ? (deliveryBoy['_id'] ?? deliveryBoy['id'])?.toString() : null,
    );
  }

  /// Backwards compatible: total of items (without delivery charge)
  double get itemsTotal =>
      items.fold(0, (sum, i) => sum + (i.price * i.quantity));

  /// Total including delivery charge (used by dashboard)
  double get totalPrice => itemsTotal + deliveryCharge;

  /// Backwards compatible field used in older widgets
  String get status => orderStatus;
}

