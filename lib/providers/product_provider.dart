import 'package:flutter/material.dart';
import '../models/product_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String baseUrl = 'https://natural-fruit-veg-admin-panel-backend.onrender/api/products'; // Backend URL

Future<void> fetchProducts() async {
  _isLoading = true;
  _errorMessage = null;

  try {
    final response = await http.get(Uri.parse(baseUrl));
    print('📥 fetchProducts response: ${response.statusCode} ${response.body}');

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      // ✅ Adjust based on backend response format
      final List<dynamic> data =
          body is List ? body : body['products'] ?? body['data'] ?? [];

      _products = data.map((e) => Product.fromJson(e)).toList();
      _errorMessage = null;
    } else {
      _errorMessage = 'Failed to load products (status: ${response.statusCode}, body: ${response.body})';
    }
  } catch (e) {
    _errorMessage = 'Error: ${e.toString()}';
    print('❌ fetchProducts error: ${e.toString()}');
  }

  _isLoading = false;
  notifyListeners();
}


  Future<void> addProduct(Product product) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product.toJson()),
      );
      if (response.statusCode == 201) {
        await fetchProducts();
      } else {
        _errorMessage = 'Failed to add product';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      notifyListeners();
    }
  }

  Future<void> updateProduct(Product product) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${product.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product.toJson()),
      );
      if (response.statusCode == 200) {
        final index = _products.indexWhere((p) => p.id == product.id);
        if (index != -1) {
          _products[index] = product;
          notifyListeners();
        }
      } else {
        _errorMessage = 'Failed to update product';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));
      if (response.statusCode == 200) {
        _products.removeWhere((p) => p.id == id);
        notifyListeners();
      } else {
        _errorMessage = 'Failed to delete product';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      notifyListeners();
    }
  }
}
