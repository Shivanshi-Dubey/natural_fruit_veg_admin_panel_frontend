import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/order_model.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final String baseUrl =
      'https://natural-fruit-veg-admin-panel-backend.onrender.com/api/orders';

Future<void> fetchOrders() async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final List<dynamic> orderList =
          data is List ? data : (data['orders'] ?? []);

      _orders = orderList.map((e) => Order.fromJson(e)).toList();
    } else {
      _errorMessage = 'Failed to load orders (${response.statusCode})';
    }
  } catch (e) {
    _errorMessage = 'Error: $e';
  }

  _isLoading = false;
  notifyListeners();
}


  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$orderId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode == 200) {
        await fetchOrders();
      } else {
        _errorMessage = 'Failed to update order status';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      notifyListeners();
    }
  }
}
