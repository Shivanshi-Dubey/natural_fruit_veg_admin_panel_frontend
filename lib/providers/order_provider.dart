import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/order_model.dart';

class OrderProvider with ChangeNotifier {
  // ================= STATE =================
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  Timer? _autoRefreshTimer;

  // ================= GETTERS =================
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 🔴 COUNT OF NEW (PLACED) ORDERS – for badge
  int get newOrdersCount =>
      _orders.where((o) => o.status == 'placed').length;

  // ================= BASE URL =================
  final String baseUrl = 'https://naturalfruitveg.com/api/orders/admin';

  // ================= FETCH ORDERS =================
  Future<void> fetchOrders({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/all'));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _orders = data.map((e) => Order.fromJson(e)).toList();
        _errorMessage = null;
      } else {
        _errorMessage =
            'Failed to load orders (${response.statusCode})';
      }
    } catch (e) {
      _errorMessage = 'Error fetching orders: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ================= AUTO REFRESH =================
  /// 🔁 Call this ONCE (initState)
  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => fetchOrders(silent: true),
    );
  }

  /// 🛑 Call this on dispose
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
  }

  // ================= ACCEPT ORDER =================
  /// API: PUT /api/orders/admin/accept/:id
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
            'Failed to accept order (${response.statusCode})';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error accepting order: $e';
      notifyListeners();
    }
  }

  // ================= ASSIGN DELIVERY BOY =================
  /// API: PUT /api/orders/admin/assign/:id
  Future<void> assignDeliveryBoy(
    String orderId,
    String deliveryBoyId,
  ) async {
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/assign/$orderId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'deliveryBoyId': deliveryBoyId}),
      );

      if (response.statusCode == 200) {
        await fetchOrders();
      } else {
        _errorMessage =
            'Failed to assign delivery boy (${response.statusCode})';
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Error assigning delivery boy: $e';
      notifyListeners();
    }
  }

  // ================= CLEAR ERROR =================
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ================= CLEANUP =================
  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}
