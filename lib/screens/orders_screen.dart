import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
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

    return AdminLayout(
      title: showOnlyPaid ? 'Paid Orders' : 'Orders',
      showBack: true, // 👈 SECONDARY SCREEN
      child: orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text('No orders found'))
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// HEADER
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Order #${order.id.substring(order.id.length - 6)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                _StatusChip(order.status),
                              ],
                            ),

                            const SizedBox(height: 8),

                            /// PRICE + PAYMENT
                            Text(
                              'Total: ₹${order.totalPrice.toStringAsFixed(0)}',
                            ),
                            Text(
                              'Payment: ${order.paymentStatus.toUpperCase()}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: order.paymentStatus == 'paid'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),

                            const Divider(height: 24),

                            /// ITEMS
                            const Text(
                              'Items',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            ...order.items.map(
                              (i) => Text('• ${i.name} × ${i.quantity}'),
                            ),

                            const SizedBox(height: 12),

                            /// DELIVERY
                            Text(
                              order.deliveryBoyName != null
                                  ? 'Delivery Boy: ${order.deliveryBoyName}'
                                  : 'Delivery Boy: Not assigned',
                              style: TextStyle(
                                color: order.deliveryBoyName != null
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            /// ACTION
                            if (order.deliveryBoyName == null &&
                                (order.status == 'placed' ||
                                    order.status == 'accepted')) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
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
                      );
                    },
                  ),
                ),
    );
  }

  /// ================= ASSIGN DIALOG =================
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
                              orderId, selected!.id);
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

  /// ================= FETCH DELIVERY BOYS =================
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
}

/// ================= STATUS CHIP =================
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'placed':
        color = Colors.grey;
        break;
      case 'assigned':
      case 'out_for_delivery':
        color = Colors.orange;
        break;
      case 'delivered':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

