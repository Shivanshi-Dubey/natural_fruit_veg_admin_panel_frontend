import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/delivery_boy.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<OrderProvider>().fetchOrders(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Manage Orders'),
            backgroundColor: Colors.green.shade700,
          ),
          body: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : provider.errorMessage != null
                  ? Center(
                      child: Text(
                        provider.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: provider.fetchOrders,
                      child: provider.orders.isEmpty
                          ? const Center(child: Text('No orders found'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: provider.orders.length,
                              itemBuilder: (context, index) {
                                return _OrderTile(
                                  order: provider.orders[index],
                                );
                              },
                            ),
                    ),
        );
      },
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Order order;
  const _OrderTile({required this.order});

  Color _statusColor(String status) {
    switch (status) {
      case 'placed':
        return Colors.grey;
      case 'accepted':
        return Colors.blue;
      case 'assigned':
      case 'out_for_delivery':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OrderProvider>();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(order.id.length - 6)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Chip(
                  label: Text(order.status),
                  backgroundColor:
                      _statusColor(order.status).withOpacity(0.15),
                  labelStyle: TextStyle(
                    color: _statusColor(order.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Text('Customer: ${order.customerName}'),

            const SizedBox(height: 6),
            Text(
              'Total: ₹${order.totalPrice.toStringAsFixed(0)} '
              '(Items ₹${order.itemsTotal.toStringAsFixed(0)} + '
              'Delivery ₹${order.deliveryCharge.toStringAsFixed(0)})',
            ),

            const SizedBox(height: 6),
            Text(
              'Payment: ${order.paymentStatus}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: order.paymentStatus == 'paid'
                    ? Colors.green
                    : Colors.orange,
              ),
            ),

            const SizedBox(height: 6),
            Text(
              'Delivery Boy: ${order.deliveryBoyName ?? 'Not assigned'}',
            ),

            const SizedBox(height: 10),

            /// 📦 ORDER ITEMS
            const Text(
              'Items:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: order.items.map((item) {
                return Text('• ${item.name} × ${item.quantity}');
              }).toList(),
            ),

            const Divider(height: 24),

            /// ACTION BUTTONS
            Wrap(
              spacing: 10,
              children: [
                if (order.status == 'placed')
                  ElevatedButton(
                    onPressed: () async {
                      await provider.acceptOrder(order.id);
                      await provider.fetchOrders();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                    ),
                    child: const Text('Accept Order'),
                  ),

                if (order.status == 'accepted')
                  OutlinedButton(
                    onPressed: () => _showAssignDialog(
                      context,
                      provider,
                      order.id,
                    ),
                    child: const Text('Assign Delivery Boy'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 👤 ASSIGN DELIVERY BOY
  Future<void> _showAssignDialog(
    BuildContext context,
    OrderProvider provider,
    String orderId,
  ) async {
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
              content: boys.isEmpty
                  ? const Text('No delivery boys available')
                  : DropdownButton<DeliveryBoy>(
                      isExpanded: true,
                      value: selected,
                      hint: const Text('Select delivery boy'),
                      items: boys.map((b) {
                        return DropdownMenuItem(
                          value: b,
                          child: Text('${b.name} (${b.phone})'),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => selected = val),
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

  /// 🌐 FETCH DELIVERY BOYS
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

