import 'package:flutter/foundation.dart';

@immutable
class Product {
  final String id;
  final String name;
   final double buyPrice;
  final double sellPrice;
  // ✅ Subtitle / Variety / Description
  final String description;

  // 🔹 Pricing
  final double price;   // selling price
  final double mrp;     // original price
  final int discount;   // percentage
  final String unit;    // 1 kg, 6 pcs, 500 g etc.

  final String imagePath;
  final String category;

  // ✅ Stock controlled by admin
  final int stock;

  const Product({
    required this.id,
    required this.name,
  this.buyPrice = 0.0,
this.sellPrice = 0.0,
    this.description = '', // ✅ SAFE DEFAULT
    required this.price,
    required this.mrp,
    required this.unit,
    this.discount = 0,
    required this.imagePath,
    required this.category,
    required this.stock,
  });

  /// ✅ IMMUTABLE UPDATE
  Product copyWith({
    String? id,
    String? name,
    String? description,
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
      description: description ?? this.description, // ✅ FIXED
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      discount: discount ?? this.discount,
      unit: unit ?? this.unit,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      stock: stock ?? this.stock,
    );
  }

  /// ✅ BACKEND → APP
  factory Product.fromJson(Map<String, dynamic> json) {
    final double parsedPrice =
        (json['price'] as num?)?.toDouble() ?? 0.0;

    return Product(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      description: json['description'] ?? '', // ✅ ONLY THIS
      price: parsedPrice,
      mrp: (json['mrp'] as num?)?.toDouble() ?? parsedPrice,
      discount: json['discount'] ?? 0,
      unit: json['unit'] ?? '1 pc',
      imagePath: json['imagePath'] ?? '',
      category: json['category'] ?? '',
      stock: json['stock'] ?? 0,
    );
  }

  /// ✅ APP → BACKEND
  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description, // ✅ ONLY THIS
        'price': price,
        'mrp': mrp,
        'discount': discount,
        'unit': unit,
        'imagePath': imagePath,
        'category': category,
        'stock': stock,
      };
}
