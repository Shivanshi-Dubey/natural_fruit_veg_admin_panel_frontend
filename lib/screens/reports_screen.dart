import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/order_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = Provider.of<OrderProvider>(context).orders;

    final totalOrders = orders.length;
    final totalRevenue =
        orders.fold(0.0, (sum, o) => sum + o.totalPrice);
    final paidOrders =
        orders.where((o) => o.paymentStatus == 'paid').length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _reportTile('Total Orders', totalOrders.toString()),
            _reportTile(
                'Total Revenue', '₹${totalRevenue.toStringAsFixed(2)}'),
            _reportTile('Paid Orders', paidOrders.toString()),
          ],
        ),
      ),
    );
  }

  Widget _reportTile(String title, String value) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
