class DeliveryBoy {
  final String id;
  final String name;
  final String phone;
  final bool isAvailable;

  DeliveryBoy({
    required this.id,
    required this.name,
    required this.phone,
    required this.isAvailable,
  });

  factory DeliveryBoy.fromJson(Map<String, dynamic> json) {
    return DeliveryBoy(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isAvailable: json['isAvailable'] ?? false,
    );
  }
}


