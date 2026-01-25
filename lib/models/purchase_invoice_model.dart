class PurchaseInvoice {
  final String id;
  final String invoiceNumber;
  final String supplierName;
  final double totalAmount;
  final String status;
  final DateTime createdAt;

  PurchaseInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.supplierName,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  factory PurchaseInvoice.fromJson(Map<String, dynamic> json) {
    return PurchaseInvoice(
      id: json['_id'] ?? '',
      invoiceNumber: json['invoiceNumber'] ?? '—',
      supplierName: json['supplierName'] ?? '—',
      totalAmount:
          (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'draft',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ??
          DateTime.now(),
    );
  }
}
