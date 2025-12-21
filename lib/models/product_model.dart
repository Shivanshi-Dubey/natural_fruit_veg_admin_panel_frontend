import 'package:flutter/foundation.dart';

@immutable
class Product {
  final String id;
  final String name;
  final double price;
  final String imagePath;
  final String category;

  // ✅ ONLY stock (admin controls this)
  final int stock;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imagePath,
    required this.category,
    required this.stock,
  });

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? imagePath,
    String? category,
    int? stock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      stock: stock ?? this.stock,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imagePath: json['imagePath'] ?? '',
      category: json['category'] ?? '',
      stock: json['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'imagePath': imagePath,
        'category': category,
        'stock': stock,
      };
}
