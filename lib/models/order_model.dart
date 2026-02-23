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
 /// 💳 PAYMENT INFO
  final String paymentMode;              // cod | upi
  final String paymentStatus;            // pending | paid | collected | completed
  final bool cashDepositedToAdmin; 
  final DateTime createdAt;
  final String? deliveryBoyName;
  final String? deliveryBoyId;

  const Order({
    required this.id,
    required this.customerName,
    required this.items,
    required this.deliveryCharge,
    required this.orderStatus,
    required this.paymentMode,
    required this.paymentStatus,
    required this.cashDepositedToAdmin,
    required this.createdAt,
    this.deliveryBoyName,
    this.deliveryBoyId,
  });

 String get status => orderStatus;
 
  factory Order.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    final deliveryBoy = json['deliveryBoy'];
    final List productsJson = (json['products'] as List? ?? []);

    final String resolvedCustomerName;
    if (user is Map) {
      resolvedCustomerName = (user['name'] ?? 'Unknown') as String;
    } else if (json['customerName'] != null) {
      resolvedCustomerName = json['customerName'] as String;
    } else {
      resolvedCustomerName = 'Unknown';
    }

    final String? resolvedDeliveryBoyName;
    final String? resolvedDeliveryBoyId;
    if (deliveryBoy is Map) {
      resolvedDeliveryBoyName = deliveryBoy['name'] as String?;
      resolvedDeliveryBoyId =
          (deliveryBoy['_id'] ?? deliveryBoy['id'])?.toString();
    } else {
      resolvedDeliveryBoyName = null;
      resolvedDeliveryBoyId = null;
    }

    final createdAtRaw = json['createdAt'];

 return Order(
      id: (json['_id'] ?? '').toString(),
      customerName: resolvedCustomerName,
      items: productsJson.map((e) => OrderItem.fromJson(e)).toList(),
      deliveryCharge: (json['deliveryCharge'] ?? 0).toDouble(),
      orderStatus: (json['orderStatus'] ?? 'placed') as String,

      /// 💳 NEW FIELDS
      paymentMode: (json['paymentMode'] ?? 'cod') as String,
      paymentStatus: (json['paymentStatus'] ?? 'pending') as String,
      cashDepositedToAdmin:
          (json['cashDepositedToAdmin'] ?? false) as bool,

      createdAt: createdAtRaw != null
          ? DateTime.parse(createdAtRaw as String)
          : DateTime.now(),

      deliveryBoyName: resolvedDeliveryBoyName,
      deliveryBoyId: resolvedDeliveryBoyId,
    );
  }


  /// Backwards compatible: total of items (without delivery charge)
  double get itemsTotal =>
      items.fold(0, (sum, i) => sum + (i.price * i.quantity));

  /// Total including delivery charge (used by dashboard)
  double get totalPrice => itemsTotal + deliveryCharge;
}

