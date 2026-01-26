class PurchaseReturn {
  final String id;
  final String supplierName;
  final DateTime date;

  PurchaseReturn({
    required this.id,
    required this.supplierName,
    required this.date,
  });

  factory PurchaseReturn.fromJson(Map<String, dynamic> json) {
    return PurchaseReturn(
      id: json['_id'],
      supplierName: json['supplier']['name'],
      date: DateTime.parse(json['createdAt']),
    );
  }
}
