import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/order_model.dart';
import '../models/delivery_boy.dart';
import '../providers/order_provider.dart';

class OrdersScreen extends StatelessWidget {
  final bool showOnlyPaid;

  const OrdersScreen({
    super.key,
    this.showOnlyPaid = false,
  });

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    List<Order> orders = orderProvider.orders;

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
                            /// ORDER ID + STATUS
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
                                  label: Text(order.status),
                                  backgroundColor:
                                      _statusColor(order.status),
                                ),
                              ],
                            ),

                            const SizedBox(height: 6),

                            /// PRICE + PAYMENT
                            Text(
                              'Total: ₹${order.totalPrice.toStringAsFixed(2)}',
                            ),
                            Text(
                              'Payment: ${order.paymentStatus}',
                              style: TextStyle(
                                color: order.paymentStatus == 'paid'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),

                            const Divider(height: 20),

                            /// ITEMS
                            const Text(
                              'Items:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            ...order.items.map(
                              (i) => Text('• ${i.name} × ${i.quantity}'),
                            ),

                            const SizedBox(height: 10),

                            /// DELIVERY BOY
                            Text(
                              order.deliveryBoyName != null
                                  ? 'Assigned to: ${order.deliveryBoyName}'
                                  : 'Delivery Boy: Not assigned',
                              style: TextStyle(
                                color: order.deliveryBoyName != null
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            /// ACTIONS
                            if (order.deliveryBoyName == null &&
                                (order.status == 'placed' ||
                                    order.status == 'accepted')) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () =>
                                      _showAssignDialog(context, order.id),
                                  child:
                                      const Text('Assign Delivery Boy'),
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

  /// ASSIGN DIALOG
  Future<void> _showAssignDialog(
    BuildContext context,
    String orderId,
  ) async {
    final provider = context.read<OrderProvider>();
    final boys = await _fetchDeliveryBoys();
    DeliveryBoy? selected;

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Assign Delivery Boy'),
              content: DropdownButton<DeliveryBoy>(
                isExpanded: true,
                value: selected,
                hint: const Text('Select delivery boy'),
                items: boys.map((b) {
                  return DropdownMenuItem(
                    value: b,
                    child: Text('${b.name} (${b.phone})'),
                  );
                }).toList(),
                onChanged: (v) => setState(() => selected = v),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selected == null
                      ? null
                      : () async {
                          await provider.assignDeliveryBoy(
                            orderId,
                            selected!.id,
                          );
                          await provider.fetchOrders();
                          if (context.mounted) Navigator.pop(context);
                        },
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// FETCH DELIVERY BOYS
  Future<List<DeliveryBoy>> _fetchDeliveryBoys() async {
    final res = await http.get(
      Uri.parse(
        'https://naturalfruitveg.com/api/delivery-boys?onlyAvailable=true',
      ),
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => DeliveryBoy.fromJson(e)).toList();
    }
    return [];
  }

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

