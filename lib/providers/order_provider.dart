import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/order_model.dart';

class OrderProvider with ChangeNotifier {
  // ================= STATE =================
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ================= GETTERS =================
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ================= BASE URL =================
  final String baseUrl = 'https://naturalfruitveg.com/api/orders/admin';

  // ================= FETCH ORDERS =================
  Future<void> fetchOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$baseUrl/all'));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _orders = data.map((e) => Order.fromJson(e)).toList();
      } else {
        _errorMessage =
            'Failed to load orders (${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      _errorMessage = 'Error fetching orders: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ================= ACCEPT ORDER =================
  /// API: PUT /api/orders/admin/accept/:id
  /// ❌ No deliveryBoyId required
  Future<void> acceptOrder(String orderId) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/accept/$orderId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        await fetchOrders();
      } else {
        _errorMessage =
            'Failed to accept order (${response.statusCode}): ${response.body}';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error accepting order: $e';
      notifyListeners();
    }
  }

  // ================= ASSIGN DELIVERY BOY =================
  /// API: PUT /api/orders/admin/:id
  /// ✅ deliveryBoyId REQUIRED
Future<void> assignDeliveryBoy(String orderId, String deliveryBoyId) async {
  _errorMessage = null;
  notifyListeners();

  try {
    print('Assigning delivery boy: $deliveryBoyId to order: $orderId');

    final response = await http.put(
      Uri.parse('$baseUrl/assign/$orderId'), // ✅ correct route
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'deliveryBoyId': deliveryBoyId, // ✅ MUST be non-null
      }),
    );

    print('Assign response status: ${response.statusCode}');
    print('Assign response body: ${response.body}');

    if (response.statusCode == 200) {
      await fetchOrders(); // 🔥 refresh state
    } else {
      _errorMessage =
          'Failed to assign delivery boy (${response.statusCode}): ${response.body}';
      notifyListeners();
    }
  } catch (e) {
    _errorMessage = 'Error assigning delivery boy: $e';
    notifyListeners();
  }
}


  // ================= CLEAR ERROR (OPTIONAL) =================
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
