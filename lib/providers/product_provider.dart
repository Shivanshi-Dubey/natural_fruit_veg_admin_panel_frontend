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

  final String baseUrl =
      'https://natural-fruit-veg-admin-panel-backend.onrender.com/api/products';

  // ✅ FETCH PRODUCTS
  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(baseUrl));
      print('📥 fetchProducts response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> data =
            body is List ? body : (body['products'] ?? body['data'] ?? []);
        _products = data.map((e) => Product.fromJson(e)).toList();
      } else {
        _errorMessage =
            'Failed to load products (${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      print('❌ fetchProducts error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // ✅ ADD PRODUCT
  Future<void> addProduct(Product product, BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product.toJson()),
      );

      print('📤 addProduct response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 201) {
        _showSnackBar(context, '✅ Product added successfully!');
        await fetchProducts();
      } else {
        _showSnackBar(context,
            '❌ Failed to add product (${response.statusCode})');
      }
    } catch (e) {
      _showSnackBar(context, '⚠️ Error adding product: $e');
    }
  }

  // ✅ UPDATE PRODUCT
  Future<void> updateProduct(Product product, BuildContext context) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/${product.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(product.toJson()),
      );

      print('🔁 updateProduct response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        await fetchProducts();
        _showSnackBar(context, '✅ Product updated successfully!');
      } else {
        _showSnackBar(context,
            '❌ Failed to update product (${response.statusCode})');
      }
    } catch (e) {
      _showSnackBar(context, '⚠️ Error updating product: $e');
    }
  }

  // ✅ DELETE PRODUCT
  Future<void> deleteProduct(String id, BuildContext context) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));

      print('🗑️ deleteProduct response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200) {
        _products.removeWhere((p) => p.id == id);
        notifyListeners();
        _showSnackBar(context, '🗑️ Product deleted successfully!');
      } else {
        _showSnackBar(context,
            '❌ Failed to delete product (${response.statusCode})');
      }
    } catch (e) {
      _showSnackBar(context, '⚠️ Error deleting product: $e');
    }
  }

  // ✅ Snackbar Helper
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        backgroundColor:
            message.contains('✅') || message.contains('🗑️')
                ? Colors.green
                : Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
      ),
    );
  }
}
