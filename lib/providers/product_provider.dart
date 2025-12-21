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

  final String baseUrl = 'https://naturalfruitveg.com/api/products';

  /* =========================
     📥 FETCH PRODUCTS
  ========================= */
  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(baseUrl));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> list =
            decoded is List ? decoded : (decoded['products'] ?? []);

        _products = list.map((e) => Product.fromJson(e)).toList();
      } else {
        _errorMessage =
            'Failed to load products (${response.statusCode})';
      }
    } catch (e) {
      _errorMessage = 'Error fetching products: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /* =========================
     ➕ ADD PRODUCT
  ========================= */
  Future<void> addProduct(Product product, BuildContext context) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': product.name,
          'price': product.price,
          'imagePath': product.imagePath,
          'category': product.category,
          'stock': product.stock,
        }),
      );

      if (response.statusCode == 201) {
        await fetchProducts();
        _showSnackBar(context, '✅ Product added successfully');
      } else {
        _showSnackBar(context, '❌ Failed to add product');
      }
    } catch (e) {
      _showSnackBar(context, '⚠️ Error adding product: $e');
    }
  }

  /* =========================
     ✏️ UPDATE PRODUCT (STOCK FIX)
  ========================= */
  Future<void> updateProduct(Product product, BuildContext context) async {
    try {
      if (product.id.isEmpty) {
        _showSnackBar(context, '❌ Product ID is missing');
        return;
      }

      // Optimistically update the UI immediately
      final index = _products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        _products[index] = product;
        notifyListeners();
      }

      final requestBody = {
        'name': product.name,
        'price': product.price,
        'imagePath': product.imagePath,
        'category': product.category,
        'stock': product.stock, // ✅ Send stock explicitly (including 0)
      };

      print('🔄 Updating product ${product.id} with stock: ${product.stock}');
      print('📤 Request body: $requestBody');

      final response = await http.put(
        Uri.parse('$baseUrl/${product.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final updatedStock = responseData['product']?['stock'] ?? responseData['stock'];
        print('✅ Updated product from server - Stock: $updatedStock');
        print('✅ Full response: $responseData');
        
        // Refresh from server to ensure consistency
        await fetchProducts();
        _showSnackBar(context, '✅ Product updated successfully (Stock: $updatedStock)');
      } else {
        // Revert optimistic update on error
        if (index != -1) {
          await fetchProducts(); // Reload to revert
        }
        final errorBody = response.body;
        _showSnackBar(
            context, '❌ Failed to update product (${response.statusCode}): $errorBody');
      }
    } catch (e) {
      // Revert optimistic update on error
      await fetchProducts(); // Reload to revert
      _showSnackBar(context, '⚠️ Error updating product: $e');
    }
  }

  /* =========================
     🗑 DELETE PRODUCT
  ========================= */
  Future<void> deleteProduct(String id, BuildContext context) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
      );

      if (response.statusCode == 200) {
        _products.removeWhere((p) => p.id == id);
        notifyListeners();
        _showSnackBar(context, '🗑 Product deleted');
      } else {
        _showSnackBar(
            context, '❌ Failed to delete product');
      }
    } catch (e) {
      _showSnackBar(context, '⚠️ Error deleting product: $e');
    }
  }

  /* =========================
     🔔 SNACKBAR
  ========================= */
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            message.startsWith('✅') || message.startsWith('🗑')
                ? Colors.green
                : Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
      ),
    );
  }
}
