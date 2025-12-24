import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = Provider.of<OrderProvider>(context).orders;

    // Unique customers
    final customers = {
      for (var o in orders) o.customerName: o
    }.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Customers"),
        backgroundColor: Colors.green.shade700,
      ),
      body: ListView.builder(
        itemCount: customers.length,
        itemBuilder: (context, index) {
          final order = customers[index];
          return ListTile(
            leading: const Icon(Icons.person),
            title: Text(order.customerName),
            subtitle: Text("Orders placed"),
          );
        },
      ),
    );
  }
}
