class Supplier {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String gstNumber;
  final String address;
  final bool isActive;
  final DateTime createdAt;

  Supplier({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.gstNumber,
    required this.address,
    required this.isActive,
    required this.createdAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['_id'],
      name: json['name'],
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      gstNumber: json['gstNumber'] ?? '',
      address: json['address'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'gstNumber': gstNumber,
      'address': address,
    };
  }
}
