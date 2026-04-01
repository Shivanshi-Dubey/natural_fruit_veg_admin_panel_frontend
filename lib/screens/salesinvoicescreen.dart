import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

class SalesInvoiceScreen extends StatefulWidget {
  const SalesInvoiceScreen({super.key});

  @override
  State<SalesInvoiceScreen> createState() =>
      _SalesInvoiceScreenState();
}

class _SalesInvoiceScreenState extends State<SalesInvoiceScreen> {
  String filter = "today";

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final orders = provider.orders;

    // 🔥 FILTER LOGIC
    List<Order> filteredOrders = orders.where((o) {
      final now = DateTime.now();

      if (filter == "today") {
        return o.createdAt.year == now.year &&
            o.createdAt.month == now.month &&
            o.createdAt.day == now.day;
      }

      if (filter == "week") {
        return o.createdAt.isAfter(
            now.subtract(const Duration(days: 7)));
      }

      if (filter == "month") {
        return o.createdAt.month == now.month &&
            o.createdAt.year == now.year;
      }

      return true;
    }).toList();

    // 🔥 GROUP ITEMS
    Map<String, int> itemCount = {};
    for (var order in filteredOrders) {
      for (var item in order.items) {
        itemCount[item.name] =
            (itemCount[item.name] ?? 0) + item.quantity;
      }
    }

    // 🔥 TOTAL SALES (NO DELIVERY)
    double totalSales = filteredOrders.fold(
        0, (sum, o) => sum + o.itemsTotal);

    int totalOrders = filteredOrders.length;

    int totalItems =
        itemCount.values.fold(0, (a, b) => a + b);

    return AdminLayout(
      title: "Sales",
      child: provider.isLoading
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
                    runSpacing: 16,
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
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}