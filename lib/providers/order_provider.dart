import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/order_model.dart';

class OrderProvider with ChangeNotifier {

  /// ================= STATE =================
  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  Timer? _autoRefreshTimer;

  /// ================= GETTERS =================
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// COUNT OF NEW ORDERS
  int get newOrdersCount =>
      _orders.where((o) => o.orderStatus == 'placed').length;

  /// ================= BASE URL =================
  final String baseUrl = "https://naturalfruitveg.com/api/orders";

  /// ================= FETCH ORDERS =================
  Future<void> fetchOrders({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final response =
          await http.get(Uri.parse("$baseUrl/admin/all"));

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        _orders = data.map((e) => Order.fromJson(e)).toList();
        _errorMessage = null;
      } else {
        _errorMessage =
            "Failed to load orders (${response.statusCode})";
      }
    } catch (e) {
      _errorMessage = "Error fetching orders: $e";
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createOrder(Map<String, dynamic> orderData) async {
  try {
    final res = await http.post(
      Uri.parse(baseUrl), // already defined
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(orderData),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      await fetchOrders(); // refresh list
    } else {
      _errorMessage = "Failed to create order";
      notifyListeners();
    }
  } catch (e) {
    _errorMessage = "Create order error: $e";
    notifyListeners();
  }
}

  /// ================= AUTO REFRESH =================
  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();

    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => fetchOrders(silent: true),
    );
  }

  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
  }

  /// ================= ACCEPT ORDER =================
  Future<void> acceptOrder(String orderId) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/admin/accept/$orderId"),
      );

      if (response.statusCode == 200) {
        await fetchOrders();
      } else {
        _errorMessage =
            "Failed to accept order (${response.statusCode})";
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "Accept order error: $e";
      notifyListeners();
    }
  }

  /// ================= UPDATE ORDER STATUS =================
  Future<void> updateOrderStatus(
      String orderId, String status) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/admin/status/$orderId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": status}),
      );

      if (response.statusCode == 200) {
        await fetchOrders();
      } else {
        _errorMessage =
            "Failed to update status (${response.statusCode})";
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "Status update error: $e";
      notifyListeners();
    }
  }



  /// ================= ASSIGN DELIVERY BOY =================
  Future<void> assignDeliveryBoy(
      String orderId, String deliveryBoyId) async {
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/admin/assign/$orderId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "deliveryBoyId": deliveryBoyId
        }),
      );

      if (response.statusCode == 200) {
        await fetchOrders();
      } else {
        _errorMessage =
            "Failed to assign delivery (${response.statusCode})";
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = "Assign delivery error: $e";
      notifyListeners();
    }
  }

  /// ================= UPDATE RETURN STATUS =================
  Future<void> updateReturnStatus(
      String orderId, String status) async {
    try {
      await http.put(
        Uri.parse(
            "https://naturalfruitveg.com/api/orders/update-return/$orderId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"returnStatus": status}),
      );

      await fetchOrders();
    } catch (e) {
      debugPrint("Return update error: $e");
    }
  }

 void addOrder(Order order) {
  _orders.insert(0, order); 
  notifyListeners();
}

  /// ================= CLEAR ERROR =================
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// ================= CLEANUP =================
  @override
  void dispose() {
    stopAutoRefresh();
    super.dispose();
  }
}