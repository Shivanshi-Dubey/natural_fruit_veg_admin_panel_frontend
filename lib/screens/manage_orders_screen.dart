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
      () => Provider.of<OrderProvider>(context, listen: false).fetchOrders(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          return Center(
            child: Text(
              provider.errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final orders = provider.orders;

        return Scaffold(
          body: orders.isEmpty
              ? const Center(child: Text('No orders found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _OrderTile(order: order);
                  },
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
    final provider = Provider.of<OrderProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
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

            const SizedBox(height: 6),
            Text('Customer: ${order.customerName}'),
            const SizedBox(height: 4),

            Text(
              'Total: ₹${order.totalPrice.toStringAsFixed(0)} '
              '(Items: ₹${order.itemsTotal.toStringAsFixed(0)} + '
              'Delivery: ₹${order.deliveryCharge.toStringAsFixed(0)})',
            ),

            const SizedBox(height: 4),
            Text(
              'Payment: ${order.paymentStatus}',
              style: TextStyle(
                color: order.paymentStatus == 'paid'
                    ? Colors.green
                    : Colors.orange,
              ),
            ),

            const SizedBox(height: 4),
            Text(
              'Delivery Boy: ${order.deliveryBoyName ?? 'Not assigned'}',
            ),

            const Divider(height: 20),

            /// ACTION BUTTONS
            Wrap(
              spacing: 8,
              children: [
            if (order.status == 'placed')
  ElevatedButton(
    onPressed: () async {
      await provider.acceptOrder(order.id);
      await provider.fetchOrders(); // 🔥 THIS LINE IS CRITICAL
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green.shade700,
    ),
    child: const Text('Accept Order'),
  ),

if (order.status == 'accepted')
  OutlinedButton(
    onPressed: () =>
        _showAssignDialog(context, provider, order.id),
    child: const Text('Assign Delivery Boy'),
  ),

              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ASSIGN DELIVERY BOY DIALOG
  Future<void> _showAssignDialog(
    BuildContext context,
    OrderProvider provider,
    String orderId,
  ) async {
    DeliveryBoy? selected;
    final List<DeliveryBoy> boys = await _fetchDeliveryBoys();

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Assign Delivery Boy'),
          content: boys.isEmpty
              ? const Text('No delivery boys available')
              : StatefulBuilder(
                  builder: (context, setState) {
                    return DropdownButton<DeliveryBoy>(
                      isExpanded: true,
                      value: selected,
                      hint: const Text('Select delivery boy'),
                      items: boys.map((b) {
                        return DropdownMenuItem<DeliveryBoy>(
                          value: b,
                          child: Text('${b.name} (${b.phone})'),
                        );
                      }).toList(),
                      onChanged: (DeliveryBoy? val) {
                        setState(() {
                          selected = val;
                        });
                      },
                    );
                  },
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
          // 🔥 FORCE LOG
          debugPrint('Selected delivery boy id: ${selected!.id}');

          await provider.assignDeliveryBoy(
            orderId,
            selected!.id,
          );

          if (context.mounted) Navigator.pop(context);
        },
  child: const Text('Assign'),
),

          ],
        );
      },
    );
  }

  /// FETCH DELIVERY BOYS
  Future<List<DeliveryBoy>> _fetchDeliveryBoys() async {
    final uri = Uri.parse(
      'https://naturalfruitveg.com/api/delivery-boys?onlyAvailable=true',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body) as List;
      return data.map((e) => DeliveryBoy.fromJson(e)).toList();
    }
    return [];
  }
}

