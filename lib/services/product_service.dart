import 'package:flutter/foundation.dart';

@immutable
class Product {
  final String id;
  final String name;
  final int price;
  final String imagePath; // ✅ matches backend
  final String category;
  final int quantity;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imagePath,
    required this.category,
    required this.quantity,
  });

  Product copyWith({
    String? id,
    String? name,
    int? price,
    String? imagePath,
    String? category,
    int? quantity,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
    );
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      price: json['price']?.toInt() ?? 0,
      imagePath: json['imagePath'] ?? json['image'] ?? '',
      category: json['category'] ?? '',
      quantity: json['quantity']?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'price': price,
      'imagePath': imagePath,
      'category': category,
      'quantity': quantity,
    };
  }
}
