import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order_model.dart';
import '../providers/order_provider.dart';

class OrdersScreen extends StatelessWidget {
  final bool showOnlyPaid;

  const OrdersScreen({
    super.key,
    this.showOnlyPaid = false,
  });

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    List<Order> orders = orderProvider.orders;

    // 🔹 Filter only paid orders if required
    if (showOnlyPaid) {
      orders = orders.where((o) => o.paymentStatus == 'paid').toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(showOnlyPaid ? 'Paid Orders' : 'All Orders'),
        backgroundColor: Colors.green.shade700,
      ),
      body: orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text('No orders found'))
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return ListTile(
                      title: Text(
                        'Order #${order.id.substring(order.id.length - 6)}',
                      ),
                      subtitle: Text(
                        '₹${order.totalPrice.toStringAsFixed(2)} • ${order.paymentStatus}',
                      ),
                      trailing: Chip(
                        label: Text(order.status),
                      ),
                    );
                  },
                ),
    );
  }
}

