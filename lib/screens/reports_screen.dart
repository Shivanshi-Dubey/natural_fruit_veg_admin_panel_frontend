import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

enum ReportRange { today, week, month, all }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportRange _range = ReportRange.all;

  @override
  Widget build(BuildContext context) {
    final allOrders = context.watch<OrderProvider>().orders;
    final orders = _filteredOrders(allOrders);

    final totalRevenue =
        orders.fold(0.0, (sum, o) => sum + o.totalPrice);

    final totalOrders = orders.length;
    final paidOrders =
        orders.where((o) => o.paymentStatus == 'paid').length;
    final deliveredOrders =
        orders.where((o) => o.status == 'delivered').length;
    final cancelledOrders =
        orders.where((o) => o.status == 'cancelled').length;

    final topProducts = _topSellingProducts(orders);

    return AdminLayout(
      title: 'Reports',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ================= FILTER =================
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                DropdownButton<ReportRange>(
                  value: _range,
                  onChanged: (v) => setState(() => _range = v!),
                  items: const [
                    DropdownMenuItem(
                        value: ReportRange.today,
                        child: Text('Today')),
                    DropdownMenuItem(
                        value: ReportRange.week,
                        child: Text('This Week')),
                    DropdownMenuItem(
                        value: ReportRange.month,
                        child: Text('This Month')),
                    DropdownMenuItem(
                        value: ReportRange.all,
                        child: Text('All Time')),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// ================= KPI ROW =================
            Row(
              children: [
                _Kpi(
                  title: 'Revenue',
                  value: '₹${totalRevenue.toStringAsFixed(0)}',
                ),
                _Kpi(
                  title: 'Orders',
                  value: totalOrders.toString(),
                ),
                _Kpi(
                  title: 'Paid',
                  value: paidOrders.toString(),
                  color: Colors.green,
                ),
                _Kpi(
                  title: 'Delivered',
                  value: deliveredOrders.toString(),
                  color: Colors.blue,
                ),
                _Kpi(
                  title: 'Cancelled',
                  value: cancelledOrders.toString(),
                  color: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 32),

            /// ================= TOP PRODUCTS =================
            _section(
              title: 'Top Selling Products',
              child: topProducts.isEmpty
                  ? const Text('No data available')
                  : Column(
                      children: topProducts.map((e) {
                        return Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key),
                              Text(
                                '${e.value} sold',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),

            /// ================= NOTE =================
            _section(
              title: 'Report Notes',
              child: const Text(
                'Data is generated from order records.\n'
                'Advanced exports, charts, and GST reports can be added later.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ================= HELPERS ================= */

  List<Order> _filteredOrders(List<Order> orders) {
    if (_range == ReportRange.all) return orders;

    final now = DateTime.now();
    return orders.where((o) {
      final date = o.createdAt;
      if (date == null) return false;

      switch (_range) {
        case ReportRange.today:
          return date.day == now.day &&
              date.month == now.month &&
              date.year == now.year;
        case ReportRange.week:
          return now.difference(date).inDays <= 7;
        case ReportRange.month:
          return date.month == now.month &&
              date.year == now.year;
        case ReportRange.all:
          return true;
      }
    }).toList();
  }

  List<MapEntry<String, int>> _topSellingProducts(
      List<Order> orders) {
    final Map<String, int> map = {};

    for (final o in orders) {
      for (final i in o.items) {
        map[i.name] = (map[i.name] ?? 0) + i.quantity;
      }
    }

    final list = map.entries.toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list.take(5).toList();
  }

  Widget _section({
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
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
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const Divider(height: 24),
          child,
        ],
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
