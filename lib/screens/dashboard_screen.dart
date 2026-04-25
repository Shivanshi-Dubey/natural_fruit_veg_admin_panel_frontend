import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
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
  double _upiRevenue = 0;
double _codRevenue = 0;
int _upiOrders = 0;
int _codOrders = 0;

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
     _fetchAnalytics();
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

  /// ================= BOTTOM SHEETS =================

  void _showDeadProducts(List<Product> products, List<Order> orders) {
    // Products that have stock but never appear in any order
    final soldProductIds = <String>{};
    for (final o in orders) {
      for (final i in o.items) {
        soldProductIds.add(i.name); // using name as identifier
      }
    }
    final dead = products
        .where((p) => p.stock > 0 && !soldProductIds.contains(p.name))
        .toList();

    _showBottomSheet(
      title: '🪦 Dead Products',
      subtitle: 'Stock available but never sold',
      color: AdminColors.danger,
      child: dead.isEmpty
          ? const _EmptyState(message: 'No dead products found 🎉')
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dead.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = dead[i];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEEEE),
                    child: Icon(Icons.inventory_2, color: AdminColors.danger, size: 18),
                  ),
                  title: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Stock: ${p.stock} units'),
                  trailing: Text(
                    '₹${p.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: AdminColors.danger, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _fetchAnalytics() async {
  try {
    final res = await http.get(
      Uri.parse('https://naturalfruitveg.com/api/admin/analytics/summary'),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      setState(() {
        _upiRevenue = (data['upiRevenue'] ?? 0).toDouble();
        _codRevenue = (data['codRevenue'] ?? 0).toDouble();
        _upiOrders = (data['upiOrders'] ?? 0);
        _codOrders = (data['codOrders'] ?? 0);
      });
    }
  } catch (e) {
    debugPrint("Analytics error: $e");
  }
}

  void _showLowStockProducts(List<Product> products) {
    final low = products.where((p) => p.stock <= 5).toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));

    _showBottomSheet(
      title: '⚠️ Low Stock Products',
      subtitle: 'Items with stock ≤ 5',
      color: AdminColors.warning,
      child: low.isEmpty
          ? const _EmptyState(message: 'All products are well stocked 🎉')
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: low.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = low[i];
                final isOut = p.stock == 0;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isOut
                        ? const Color(0xFFFFEEEE)
                        : const Color(0xFFFFF8E1),
                    child: Text(
                      '${p.stock}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOut ? AdminColors.danger : AdminColors.warning,
                      ),
                    ),
                  ),
                  title: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(isOut ? 'Out of stock!' : '${p.stock} units left'),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isOut ? AdminColors.danger : AdminColors.warning)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isOut ? 'OUT' : 'LOW',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color:
                            isOut ? AdminColors.danger : AdminColors.warning,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showPendingPayments(List<Order> orders) {
    final pending = orders
        .where((o) =>
            o.paymentMethod == 'cod' &&
            !o.cashDepositedToAdmin &&
            o.orderStatus == 'delivered')
        .toList();

    final totalPending =
        pending.fold<double>(0, (sum, o) => sum + o.totalPrice);

    _showBottomSheet(
      title: '💰 Pending Payments',
      subtitle: 'COD orders not yet deposited to admin',
      color: AdminColors.danger,
      headerExtra: pending.isEmpty
          ? null
          : Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Pending',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '₹${totalPending.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AdminColors.danger,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
      child: pending.isEmpty
          ? const _EmptyState(message: 'No pending payments 🎉')
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pending.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final o = pending[i];
                final shortId = o.id.length > 10
                    ? o.id.substring(o.id.length - 10)
                    : o.id;
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFEEEE),
                    child: Icon(Icons.money_off,
                        color: AdminColors.danger, size: 18),
                  ),
                  title: Text('Order #$shortId',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(o.customerName),
                  trailing: Text(
                    '₹${o.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: AdminColors.danger,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                );
              },
            ),
    );
  }

  void _showBottomSheet({
    required String title,
    required String subtitle,
    required Color color,
    required Widget child,
    Widget? headerExtra,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, controller) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 13)),
                  if (headerExtra != null) ...[
                    const SizedBox(height: 12),
                    headerExtra,
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  List<Map<String, dynamic>> _topSellingProducts(
    List<Order> orders, List<Product> products) {
  final Map<String, int> qtySold = {};

  for (final order in orders) {
    for (final item in order.items) {
      qtySold[item.name] = (qtySold[item.name] ?? 0) + item.quantity;
    }
  }

  final sorted = qtySold.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sorted.take(5).map((e) => {
    'name': e.key,
    'qty': e.value,
  }).toList();
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

                  const SizedBox(height: 16),

                  // ✅ UPI vs COD Revenue Cards
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.purple.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.qr_code, color: Colors.purple.shade400, size: 18),
                                  const SizedBox(width: 6),
                                  Text("UPI / Online",
                                      style: TextStyle(color: Colors.purple.shade400, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "₹${_upiRevenue.toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$_upiOrders orders this month",
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.money, color: Colors.green.shade400, size: 18),
                                  const SizedBox(width: 6),
                                  Text("Cash on Delivery",
                                      style: TextStyle(color: Colors.green.shade400, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "₹${_codRevenue.toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$_codOrders orders this month",
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

/// ================= TOP SELLING PRODUCTS =================
const _SectionTitle('Top Selling Products'),
const SizedBox(height: 12),

Container(
  decoration: _box(),
  padding: const EdgeInsets.all(16),
  child: _topSellingProducts(orders, products).isEmpty
      ? const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No sales data yet', style: TextStyle(color: Colors.grey)),
        )
      : Column(
          children: _topSellingProducts(orders, products)
              .asMap()
              .entries
              .map((entry) {
            final i = entry.key;
            final item = entry.value;
            final colors = [
              AdminColors.warning,
              Colors.blueGrey,
              Colors.brown,
              AdminColors.success,
              AdminColors.primary,
            ];
            final color = colors[i % colors.length];
            final maxQty = _topSellingProducts(orders, products).first['qty'] as int;
            final qty = item['qty'] as int;
            final pct = maxQty > 0 ? qty / maxQty : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  // Rank badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: i < 3 ? color.withOpacity(0.15) : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '#${i + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: i < 3 ? color : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name + bar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item['name'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            Text(
                              '${item['qty']} sold',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: Colors.grey.shade100,
                            color: color,
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
),



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
                          onTap: () => _showDeadProducts(products, orders),
                        ),
                        const Divider(),
                        _AnalyticsRow(
                          title: 'Low Stock Products',
                          subtitle: 'Items ≤ 5 (${lowStockCount(products)})',
                          color: AdminColors.warning,
                          onTap: () => _showLowStockProducts(products),
                        ),
                        const Divider(),
                        _AnalyticsRow(
                          title: 'Pending Payments',
                          subtitle: 'COD orders not yet deposited',
                          color: AdminColors.danger,
                          onTap: () => _showPendingPayments(orders),
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
  final VoidCallback onTap;

  const _AnalyticsRow({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            Row(
              children: [
                Text(
                  'View',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: color, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= EMPTY STATE =================
class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.grey, fontSize: 15),
          textAlign: TextAlign.center,
        ),
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
