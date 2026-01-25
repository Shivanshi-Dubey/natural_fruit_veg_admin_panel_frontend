import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/product_model.dart';
import '../models/order_model.dart';
import '../providers/product_provider.dart';
import '../providers/order_provider.dart';
import '../layouts/admin_layout.dart';
import '../widgets/kpi_card.dart';
import '../widgets/revenue_line_chart.dart';
import '../widgets/order_status_pie_chart.dart';

/// =======================================================
/// ERP-STYLE DASHBOARD (RUJUL DETAILED)
/// =======================================================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _autoRefreshTimer;
  String _salesFilter = 'Last 7 Days';

  @override
  void initState() {
    super.initState();
    _loadData();
    _autoRefreshTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _loadData());
  }

  void _loadData() {
    context.read<ProductProvider>().fetchProducts();
    context.read<OrderProvider>().fetchOrders();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  /// ================= METRICS =================
  int totalProducts(List<Product> p) => p.length;

  int pendingOrders(List<Order> orders) =>
      orders.where((o) => o.status == 'placed').length;

  double totalRevenue(List<Order> orders) =>
      orders.fold(0, (sum, o) => sum + o.totalPrice);

  int totalItemsSold(List<Order> orders) {
    int total = 0;
    for (final o in orders) {
      for (final i in o.items) {
        total += i.quantity;
      }
    }
    return total;
  }

  int lowStockCount(List<Product> products) =>
      products.where((p) => p.stock <= 5).length;

  List<FlSpot> salesSpots(List<Order> orders) {
    final recent = orders.reversed.take(6).toList();
    return List.generate(
      recent.length,
      (i) => FlSpot(i.toDouble(), recent[i].totalPrice),
    );
  }

  /// ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final orderProvider = context.watch<OrderProvider>();

    final products = productProvider.products;
    final orders = orderProvider.orders;

    final loading = productProvider.isLoading || orderProvider.isLoading;

    return AdminLayout(
      title: 'Dashboard',
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// ================= KPI =================
                  Row(
                    children: [
                      _KpiCard(
                        label: 'Total Products',
                        value: totalProducts(products).toString(),
                        hint: 'Active inventory items',
                      ),
                      _KpiCard(
                        label: 'New Orders',
                        value: pendingOrders(orders).toString(),
                        hint: 'Orders awaiting processing',
                        highlight: AdminColors.warning,
                      ),
                      _KpiCard(
                        label: 'Revenue',
                        value:
                            '₹${totalRevenue(orders).toStringAsFixed(0)}',
                        hint: 'Total sales value',
                      ),
                      _KpiCard(
                        label: 'Items Sold',
                        value: totalItemsSold(orders).toString(),
                        hint: 'Total quantity sold',
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  /// ================= SALES OVERVIEW =================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionTitle('Sales Overview'),
                      DropdownButton<String>(
                        value: _salesFilter,
                        items: const [
                          DropdownMenuItem(
                              value: 'Today', child: Text('Today')),
                          DropdownMenuItem(
                              value: 'Last 7 Days',
                              child: Text('Last 7 Days')),
                          DropdownMenuItem(
                              value: 'Last 30 Days',
                              child: Text('Last 30 Days')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setState(() => _salesFilter = v);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    height: 260,
                    padding: const EdgeInsets.all(16),
                    decoration: _box(),
                    child: LineChart(
                      LineChartData(
                        borderData: FlBorderData(show: false),
                        gridData:
                            FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: salesSpots(orders),
                            isCurved: true,
                            color: AdminColors.primary,
                            barWidth: 3,
                            belowBarData: BarAreaData(
                              show: true,
                              color:
                                  AdminColors.primary.withOpacity(0.08),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// ================= RECENT ORDERS =================
                  const _SectionTitle('Recent Orders'),
                  const SizedBox(height: 12),

                  Container(
                    decoration: _box(),
                    child: Column(
                      children: orders.take(5).map((o) {
                        return ListTile(
                          title: Text('Order #${o.id}'),
                          subtitle: Text(
                              '₹${o.totalPrice.toStringAsFixed(0)}'),
                          trailing: Text(
                            o.status.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: o.status == 'placed'
                                  ? AdminColors.warning
                                  : AdminColors.success,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// ================= ADMIN ANALYTICS =================
                  const _SectionTitle('Admin Analytics'),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _box(),
                    child: Column(
                      children: [
                        _AnalyticsRow(
                          title: 'Dead Products',
                          subtitle: 'Stock available but never sold',
                          color: AdminColors.danger,
                        ),
                        const Divider(),
                        _AnalyticsRow(
                          title: 'Low Stock Products',
                          subtitle:
                              'Items ≤ 5 (${lowStockCount(products)})',
                          color: AdminColors.warning,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  static BoxDecoration _box() => BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AdminColors.border),
      );
}

/// ================= COMPONENTS =================

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style:
          const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final Color? highlight;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.hint,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: _DashboardScreenState._box(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: highlight,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              hint,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const _AnalyticsRow({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
        Text(
          'View',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// ================= COLORS =================

class AdminColors {
  static const bg = Color(0xFFF8FAFC);
  static const card = Colors.white;
  static const border = Color(0xFFE5E7EB);
  static const primary = Color(0xFF1E293B);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);
}
