import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;

  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<OrderProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Order ID: ${order.id}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text("Customer: ${order.customerName}"),
            const SizedBox(height: 6),
            Text("Status: ${order.status}"),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                final newStatus = order.status == 'Pending' ? 'Delivered' : 'Pending';
                provider.updateOrderStatus(order.id, newStatus);
              },
              child: Text(order.status == 'Pending' ? 'Mark as Delivered' : 'Mark as Pending'),
            ),
          ],
        ),
      ),
    );
  }
}
