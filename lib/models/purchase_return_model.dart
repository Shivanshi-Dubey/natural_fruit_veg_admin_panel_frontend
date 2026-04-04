class PurchaseReturnItem {
  final String productId;
  final String productName;
  final int quantity;
  final String reason;

  PurchaseReturnItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'reason': reason,
      };
}

class PurchaseReturn {
  final String id;
  final String supplierName;
  final DateTime date;
  final List<PurchaseReturnItem> items;

  PurchaseReturn({
    required this.id,
    required this.supplierName,
    required this.date,
    required this.items,
  });

  factory PurchaseReturn.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return PurchaseReturn(
      id: json['_id'] ?? '',
      supplierName: json['supplierName'] ??
          (json['supplier'] is Map
              ? json['supplier']['name']
              : json['supplier'] ?? ''),
      date: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      items: rawItems
          .map((e) => PurchaseReturnItem(
                productId: e['productId'] ?? '',
                productName: e['productName'] ?? '',
                quantity: (e['quantity'] ?? 0) as int,
                reason: e['reason'] ?? '',
              ))
          .toList(),
    );
  }
}