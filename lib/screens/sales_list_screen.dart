import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/order_model.dart';

class SalesListScreen extends StatelessWidget {
  const SalesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final orders = provider.orders;

    double totalSale =
        orders.fold(0, (sum, o) => sum + o.itemsTotal);

    return Scaffold(
      appBar: AppBar(title: const Text("Sale List")),
      body: Column(
        children: [
          // 🔥 TOTAL SALE
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Sale"),
                Text("₹${totalSale.toStringAsFixed(2)}"),
              ],
            ),
          ),

          // 🔥 LIST
          Expanded(
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (_, i) {
                final o = orders[i];

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  child: ListTile(
                    title: Text(o.customerName),
                    subtitle: Text(
                        "₹${o.itemsTotal} • ${o.createdAt}"),
                    trailing: const Icon(Icons.picture_as_pdf),
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // 🔥 ADD SALE BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, "/create-order");
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}