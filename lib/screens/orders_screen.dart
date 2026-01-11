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
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🆔 ORDER ID + STATUS
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Order #${order.id.substring(order.id.length - 6)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    order.status,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: _statusColor(order.status),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            // 💰 PRICE + PAYMENT
                            Text(
                              'Total: ₹${order.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Payment: ${order.paymentStatus}',
                              style: TextStyle(
                                fontSize: 13,
                                color: order.paymentStatus == 'paid'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),

                            const Divider(height: 20),

                            // 📦 ITEMS
                            const Text(
                              'Items:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: order.items.map((item) {
                                return Text(
                                  '• ${item.name} × ${item.quantity}',
                                  style: const TextStyle(fontSize: 13),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 12),

                            // 🚚 DELIVERY BOY
                            Text(
                              'Delivery Boy: ${order.deliveryBoyName ?? "Not assigned"}',
                              style: const TextStyle(fontSize: 12),
                            ),

                            // ✅ ACCEPT BUTTON (ONLY IF PLACED)
                            if (order.status == 'placed') ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () async {
                                    await orderProvider.acceptOrder(order.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Order accepted'),
                                      ),
                                    );
                                  },
                                  child: const Text('Accept Order'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  // 🎨 STATUS COLOR
  Color _statusColor(String status) {
    switch (status) {
      case 'placed':
        return Colors.grey.shade300;
      case 'assigned':
        return Colors.orange.shade200;
      case 'out_for_delivery':
        return Colors.blue.shade200;
      case 'delivered':
        return Colors.green.shade200;
      default:
        return Colors.grey.shade200;
    }
  }
}

