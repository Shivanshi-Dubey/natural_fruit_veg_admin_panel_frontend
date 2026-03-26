import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/product_model.dart';
import '../models/order_model.dart';
import '../providers/product_provider.dart';
import '../providers/order_provider.dart';
import '../layouts/admin_layout.dart';

/// =======================================================
/// ERP-STYLE DASHBOARD
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

  /// ================= FIXED SALES SPOTS =================
  List<FlSpot> salesSpots(List<Order> orders) {
    final now = DateTime.now();

    // ✅ Respect dropdown filter
    int days = 7;
    if (_salesFilter == 'Today') days = 1;
    if (_salesFilter == 'Last 30 Days') days = 30;

    // ✅ Initialize all days to 0
    final Map<int, double> dailyRevenue = {};
    for (int i = 0; i < days; i++) {
      dailyRevenue[i] = 0.0;
    }

    // ✅ Group orders by day
    for (final order in orders) {
      final diff = now
          .difference(order.createdAt)
          .inDays;
      if (diff >= 0 && diff < days) {
        final key = days - 1 - diff; // left = oldest, right = newest
        dailyRevenue[key] = (dailyRevenue[key] ?? 0) + order.totalPrice;
      }
    }

    // ✅ Convert to FlSpot list sorted by x
    return dailyRevenue.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  /// ================= X AXIS DATE LABEL =================
  String _dayLabel(int index) {
    int days = 7;
    if (_salesFilter == 'Today') days = 1;
    if (_salesFilter == 'Last 30 Days') days = 30;

    final date = DateTime.now()
        .subtract(Duration(days: days - 1 - index));
    return '${date.day}/${date.month}';
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
                  /// ================= KPI CARDS =================
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
                        value: '₹${totalRevenue(orders).toStringAsFixed(0)}',
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
                          if (v != null) setState(() => _salesFilter = v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  /// ================= LINE CHART =================
                  Container(
                    height: 280,
                    padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                    decoration: _box(),
                    child: salesSpots(orders).isEmpty ||
                            salesSpots(orders)
                                .every((s) => s.y == 0)
                        ? const Center(
                            child: Text(
                              'No sales data for this period',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : LineChart(
                            LineChartData(
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: AdminColors.border,
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                // ✅ LEFT — Revenue labels
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 48,
                                    getTitlesWidget: (value, meta) => Text(
                                      '₹${value.toInt()}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                // ✅ BOTTOM — Date labels
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 28,
                                    getTitlesWidget: (value, meta) {
                                      final label =
                                          _dayLabel(value.toInt());
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            top: 6),
                                        child: Text(
                                          label,
                                          style: const TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                rightTitles: AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                topTitles: AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: salesSpots(orders),
                                  isCurved: true,
                                  color: AdminColors.primary,
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AdminColors.primary
                                        .withOpacity(0.08),
                                  ),
                                ),
                              ],
                              // ✅ Tooltip showing ₹ value on tap
                              lineTouchData: LineTouchData(
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipItems: (spots) => spots
                                      .map(
                                        (s) => LineTooltipItem(
                                          '₹${s.y.toStringAsFixed(0)}',
                                          const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                            ),
                          ),
                  ),

                  const SizedBox(height: 32),

                  /// ================= RECENT ORDERS =================
                  const _SectionTitle('Recent Orders'),
                  const SizedBox(height: 12),

                  Container(
                    decoration: _box(),
                    child: orders.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No orders yet',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : Column(
                            children: orders.take(5).map((o) {
                              return ListTile(
                                title: Text(
                                  'Order #${o.id.length > 10 ? o.id.substring(o.id.length - 10) : o.id}',
                                ),
                                subtitle: Text(
                                    '₹${o.totalPrice.toStringAsFixed(0)} • ${o.customerName}'),
                                trailing: Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(o.status)
                                        .withOpacity(0.1),
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    o.status.toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                      color: _statusColor(o.status),
                                    ),
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
                        const Divider(),
                        _AnalyticsRow(
                          title: 'Pending Payments',
                          subtitle: 'COD orders not yet collected',
                          color: AdminColors.danger,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'placed':
        return AdminColors.warning;
      case 'delivered':
        return AdminColors.success;
      case 'cancelled':
        return AdminColors.danger;
      default:
        return Colors.blueGrey;
    }
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
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                style:
                    const TextStyle(fontSize: 13, color: Colors.grey)),
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
              style:
                  const TextStyle(fontSize: 12, color: Colors.grey),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
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
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13)),
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
      ),
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
