class GRN {
  final String id;
  final String supplierName;
  final DateTime date;
  final int totalItems;

  GRN({
    required this.id,
    required this.supplierName,
    required this.date,
    required this.totalItems,
  });

  factory GRN.fromJson(Map<String, dynamic> json) {
    return GRN(
      id: json['_id'],
      supplierName: json['supplier']?['name'] ?? '',
      date: DateTime.parse(json['createdAt']),
      totalItems: (json['items'] as List).length,
    );
  }
}
