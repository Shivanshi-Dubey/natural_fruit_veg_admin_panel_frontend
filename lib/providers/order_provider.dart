import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/order_model.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Admin-specific orders endpoint
  final String baseUrl = 'https://naturalfruitveg.com/api/orders/admin';

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$baseUrl/all'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _orders = data.map((e) => Order.fromJson(e)).toList();
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to load orders (${response.statusCode})';
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Generic update used by UI helpers below
  Future<void> updateOrder(
    String orderId, {
    String? orderStatus,
    String? paymentStatus,
    String? deliveryBoyId,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (orderStatus != null) body['orderStatus'] = orderStatus;
      if (paymentStatus != null) body['paymentStatus'] = paymentStatus;
      if (deliveryBoyId != null) body['deliveryBoyId'] = deliveryBoyId;

      final response = await http.put(
        Uri.parse('$baseUrl/$orderId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        await fetchOrders();
      } else {
        _errorMessage =
            'Failed to update order (${response.statusCode}): ${response.body}';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      notifyListeners();
    }
  }

  Future<void> acceptOrder(String orderId) =>
      updateOrder(orderId, orderStatus: 'accepted');

 Future<void> assignDeliveryBoy(String orderId, String deliveryBoyId) async {
  final url = Uri.parse('$baseUrl/api/orders/admin/$orderId');

  final response = await http.put(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'deliveryBoyId': deliveryBoyId,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception(
      'Failed to update order (${response.statusCode}): ${response.body}',
    );
  }

  // Refresh orders after update
  await fetchOrders();
}

}

