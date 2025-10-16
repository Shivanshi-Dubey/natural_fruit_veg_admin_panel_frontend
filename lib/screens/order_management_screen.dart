import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../widgets/order_card.dart';

class OrderManagementScreen extends StatelessWidget {
  const OrderManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Orders')),
      body: RefreshIndicator(
        onRefresh: () async => await orderProvider.fetchOrders(),
        child: orderProvider.orders.isEmpty
            ? const Center(child: Text('No orders available.'))
            : ListView.builder(
                itemCount: orderProvider.orders.length,
                itemBuilder: (context, index) {
                  final order = orderProvider.orders[index];
                  return OrderCard(order: order);
                },
              ),
      ),
    );
  }
}
