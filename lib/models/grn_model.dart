class GRN {
  final String id;
  final String grnNumber;
  final String supplierName;
  final DateTime createdAt;
  final String status;

  GRN({
    required this.id,
    required this.grnNumber,
    required this.supplierName,
    required this.createdAt,
    required this.status,
  });

  factory GRN.fromJson(Map<String, dynamic> json) {
    return GRN(
      id: json['_id'],
      grnNumber: json['grnNumber'] ?? 'N/A',
      supplierName: json['supplier']?['name'] ?? 'Unknown',
      createdAt: DateTime.parse(json['createdAt']),
      status: json['status'] ?? 'Pending',
    );
  }
}
