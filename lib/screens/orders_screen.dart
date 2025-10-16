import 'package:flutter/material.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Example static orders — replace with real API call
    final orders = [
      {'id': '#12345', 'total': 250, 'status': 'Delivered'},
      {'id': '#12346', 'total': 100, 'status': 'Pending'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('All Orders')),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return ListTile(
            title: Text(order['id'].toString()),
            subtitle: Text('₹ ${order['total']} - ${order['status']}'),
            onTap: () {
              // Future: Show order details
            },
          );
        },
      ),
    );
  }
}
