import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../layouts/admin_layout.dart';
import '../models/order_model.dart';

class SalesInvoiceScreen extends StatefulWidget {
  const SalesInvoiceScreen({super.key});

  @override
  State<SalesInvoiceScreen> createState() =>
      _SalesInvoiceScreenState();
}

class _SalesInvoiceScreenState extends State<SalesInvoiceScreen> {
  List<Order> orders = [];
  bool isLoading = true;

  String filter = "today";

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    final res = await http.get(
      Uri.parse("https://naturalfruitveg.com/api/orders"),
    );

    final data = jsonDecode(res.body);

    setState(() {
      orders = (data as List)
          .map((e) => Order.fromJson(e))
          .toList();
      isLoading = false;
    });
  }

  // 🔥 FILTER LOGIC
  List<Order> get filteredOrders {
    final now = DateTime.now();

    if (filter == "today") {
      return orders.where((o) =>
          o.createdAt.year == now.year &&
          o.createdAt.month == now.month &&
          o.createdAt.day == now.day).toList();
    }

    if (filter == "week") {
      final weekAgo = now.subtract(const Duration(days: 7));
      return orders.where((o) => o.createdAt.isAfter(weekAgo)).toList();
    }

    if (filter == "month") {
      return orders.where((o) =>
          o.createdAt.month == now.month &&
          o.createdAt.year == now.year).toList();
    }

    return orders;
  }

  // 🔥 GROUP ITEMS
  Map<String, int> get itemCount {
    Map<String, int> map = {};

    for (var order in filteredOrders) {
      for (var item in order.items) {
        map[item.name] =
            (map[item.name] ?? 0) + item.quantity;
      }
    }

    return map;
  }

  // 🔥 TOTAL SALES (NO DELIVERY)
  double get totalSales {
    double total = 0;

    for (var order in filteredOrders) {
      total += order.itemsTotal;
    }

    return total;
  }

  int get totalOrders => filteredOrders.length;

  int get totalItems =>
      itemCount.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: "Sales",
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [

                  // 🔥 FILTER BUTTONS
                  Row(
                    children: [
                      _filterBtn("Today", "today"),
                      _filterBtn("Week", "week"),
                      _filterBtn("Month", "month"),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // 🔥 STATS CARDS
                  Wrap(
                    spacing: 16,
                    children: [
                      _card("Sales", "₹${totalSales.toStringAsFixed(0)}"),
                      _card("Orders", "$totalOrders"),
                      _card("Items Sold", "$totalItems"),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Product-wise Sales",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 🔥 ITEM LIST
                  Expanded(
                    child: itemCount.isEmpty
                        ? const Center(child: Text("No Data"))
                        : ListView(
                            children: itemCount.entries.map((e) {
                              return ListTile(
                                title: Text(e.key),
                                trailing: Text("Qty: ${e.value}"),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _filterBtn(String text, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              filter == value ? Colors.black : Colors.grey[300],
          foregroundColor:
              filter == value ? Colors.white : Colors.black,
        ),
        onPressed: () => setState(() => filter = value),
        child: Text(text),
      ),
    );
  }

  Widget _card(String title, String value) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(title),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}