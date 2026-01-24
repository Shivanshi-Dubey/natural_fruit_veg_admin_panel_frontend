import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
import '../models/order_model.dart';
import '../models/delivery_boy.dart';
import '../providers/order_provider.dart';

class OrderDetailsScreen extends StatelessWidget {
  final Order order;

  const OrderDetailsScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<OrderProvider>();

    return AdminLayout(
      title: 'Order Details',
      showBack: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ================= ORDER HEADER =================
            _header(),

            /// ================= STATUS TIMELINE =================
            _section(
              title: 'Order Progress',
              child: _statusTimeline(order.status),
            ),

            /// ================= CUSTOMER =================
            _section(
              title: 'Customer Information',
              child: Column(
                children: [
                  _row('Name', order.customerName),
                  _row('Phone', order.customerPhone ?? '—'),
                  _row('Address', order.deliveryAddress ?? '—'),
                ],
              ),
            ),

            /// ================= ITEMS =================
            _section(
              title: 'Ordered Items',
              child: Column(
                children: order.items.map((i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${i.name} × ${i.quantity}'),
                        Text(
                          '₹${i.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            /// ================= BILL =================
            _section(
              title: 'Billing Summary',
              child: Column(
                children: [
                  _row('Items Total',
                      '₹${order.itemsTotal.toStringAsFixed(0)}'),
                  _row('Delivery Charge',
                      '₹${order.deliveryCharge.toStringAsFixed(0)}'),
                  const Divider(),
                  _row(
                    'Grand Total',
                    '₹${order.totalPrice.toStringAsFixed(0)}',
                    isBold: true,
                  ),
                ],
              ),
            ),

            /// ================= DELIVERY =================
            _section(
              title: 'Delivery',
              child: _row(
                'Delivery Boy',
                order.deliveryBoyName ?? 'Not assigned',
                valueColor: order.deliveryBoyName != null
                    ? Colors.green
                    : Colors.red,
              ),
            ),

            /// ================= ACTIONS =================
            if (order.status == 'placed' ||
                order.status == 'accepted')
              _actionBar(context, provider),
          ],
        ),
      ),
    );
  }

  /* ================= HEADER ================= */

  Widget _header() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Order #${order.id.substring(order.id.length - 6)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Chip(
            label: Text(order.status.toUpperCase()),
            backgroundColor:
                _statusColor(order.status).withOpacity(0.15),
            labelStyle: TextStyle(
              color: _statusColor(order.status),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /* ================= STATUS TIMELINE ================= */

  Widget _statusTimeline(String status) {
    final steps = [
      'placed',
      'accepted',
      'assigned',
      'out_for_delivery',
      'delivered',
    ];

    return Row(
      children: steps.map((s) {
        final active = steps.indexOf(s) <= steps.indexOf(status);
        return Expanded(
          child: Column(
            children: [
              Icon(
                active ? Icons.check_circle : Icons.radio_button_unchecked,
                color: active ? Colors.green : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                s.replaceAll('_', ' ').toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /* ================= ACTION BAR ================= */

  Widget _actionBar(
    BuildContext context,
    OrderProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Wrap(
        spacing: 12,
        children: [
          if (order.status == 'placed')
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Accept Order'),
              onPressed: () async {
                await provider.acceptOrder(order.id);
                await provider.fetchOrders();
                if (context.mounted) Navigator.pop(context);
              },
            ),
          if (order.status == 'accepted')
            OutlinedButton.icon(
              icon: const Icon(Icons.delivery_dining),
              label: const Text('Assign Delivery Boy'),
              onPressed: () =>
                  _showAssignDialog(context, provider),
            ),
        ],
      ),
    );
  }

  /* ================= ASSIGN DELIVERY ================= */

  Future<void> _showAssignDialog(
    BuildContext context,
    OrderProvider provider,
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
              content: DropdownButton<DeliveryBoy>(
                isExpanded: true,
                value: selected,
                hint: const Text('Select delivery boy'),
                items: boys
                    .map(
                      (b) => DropdownMenuItem(
                        value: b,
                        child: Text('${b.name} (${b.phone})'),
                      ),
                    )
                    .toList(),
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
                              order.id, selected!.id);
                          await provider.fetchOrders();
                          if (context.mounted)
                            Navigator.pop(context);
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

  /* ================= UI HELPERS ================= */

  Widget _section({
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight:
                  isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _box() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      );

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
      default:
        return Colors.grey;
    }
  }
}
