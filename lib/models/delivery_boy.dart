class DeliveryBoy {
  final String id;
  final String name;
  final String phone;
  final bool isAvailable;

  const DeliveryBoy({
    required this.id,
    required this.name,
    required this.phone,
    required this.isAvailable,
  });

  factory DeliveryBoy.fromJson(Map<String, dynamic> json) {
    return DeliveryBoy(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      isAvailable: (json['isAvailable'] ?? true) as bool,
    );
  }
}


