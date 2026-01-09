import 'package:flutter/foundation.dart';

@immutable
class Product {
  final String id;
  final String name;

  // 🔹 Pricing
  final double price;   // selling price
  final double mrp;     // original price
  final int discount;   // percentage
  final String unit;    // 1 kg, 6 pcs, 500 g etc.

  final String imagePath;
  final String category;

  // ✅ ONLY stock (admin controls this)
  final int stock;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.mrp,
    required this.unit,
    this.discount = 0,
    required this.imagePath,
    required this.category,
    required this.stock,
  });

  Product copyWith({
    String? id,
    String? name,
    double? price,
    double? mrp,
    int? discount,
    String? unit,
    String? imagePath,
    String? category,
    int? stock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      discount: discount ?? this.discount,
      unit: unit ?? this.unit,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      stock: stock ?? this.stock,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    final double parsedPrice =
        (json['price'] as num?)?.toDouble() ?? 0.0;

    return Product(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      price: parsedPrice,
      mrp: (json['mrp'] as num?)?.toDouble() ?? parsedPrice,
      discount: json['discount'] ?? 0,
      unit: json['unit'] ?? '1 pc',
      imagePath: json['imagePath'] ?? '',
      category: json['category'] ?? '',
      stock: json['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'mrp': mrp,
        'discount': discount,
        'unit': unit,
        'imagePath': imagePath,
        'category': category,
        'stock': stock,
      };
}
