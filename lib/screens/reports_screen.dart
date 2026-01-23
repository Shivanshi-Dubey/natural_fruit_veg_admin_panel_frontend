import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().orders;

    final totalRevenue =
        orders.fold(0.0, (sum, o) => sum + o.totalPrice);
    final totalOrders = orders.length;
    final paidOrders =
        orders.where((o) => o.paymentStatus == 'paid').length;
    final unpaidOrders = totalOrders - paidOrders;

    return AdminLayout(
      title: 'Reports',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// KPI ROW
            Row(
              children: [
                _Kpi(
                  title: 'Total Revenue',
                  value: '₹${totalRevenue.toStringAsFixed(0)}',
                ),
                _Kpi(
                  title: 'Total Orders',
                  value: totalOrders.toString(),
                ),
                _Kpi(
                  title: 'Paid Orders',
                  value: paidOrders.toString(),
                  color: Colors.green,
                ),
                _Kpi(
                  title: 'Unpaid Orders',
                  value: unpaidOrders.toString(),
                  color: Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 32),

            /// SUMMARY
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Text(
                'Sales and order data is calculated from all completed and active orders.\n'
                'Advanced reports (date filters, exports, invoices) can be added later.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;

  const _Kpi({
    required this.title,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
