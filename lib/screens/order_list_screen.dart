import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  List<dynamic> orders = [];

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    const String url =
        'https://natural-fruit-veg-admin-panel-backend.onrender.com/api/orders';

    print('📡 Fetching orders from: $url');

    try {
      final response = await http.get(Uri.parse(url));

      print('🔹 Response code: ${response.statusCode}');
      print('🔹 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          orders = data;
        });
      } else {
        print('❌ Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error fetching orders: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
      ),
      body: orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return ListTile(
                  title: Text('Order ID: ${order['_id']}'),
                  subtitle: Text('Total: ₹${order['totalAmount']}'),
                );
              },
            ),
    );
  }
}
