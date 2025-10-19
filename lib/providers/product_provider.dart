import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/product_model.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String baseUrl =
      'https://natural-fruit-veg-admin-panel-backend.onrender.com/api/products';

Future<void> fetchProducts() async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // handle both possible cases
      final List<dynamic> productList =
          data is List ? data : (data['products'] ?? []);

      _products = productList.map((e) => Product.fromJson(e)).toList();
      _errorMessage = null;
    } else {
      _errorMessage = 'Failed to load products (${response.statusCode})';
    }
  } catch (e) {
    _errorMessage = 'Error: $e';
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
        }
        notifyListeners();
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
