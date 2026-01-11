import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/product_model.dart';
import '../models/order_model.dart';
import '../providers/product_provider.dart';
import '../providers/order_provider.dart';

import 'products_screen.dart';
import 'orders_screen.dart';
import 'customers_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'dead_products_screen.dart';
import 'low_stock_products_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();

    /// 🔄 AUTO REFRESH EVERY 30 SECONDS
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadData();
    });
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

  /// ================== HELPERS ==================
  int totalProducts(List<Product> p) => p.length;
  int totalOrders(List<Order> o) => o.length;

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

  /// 📈 SALES GRAPH (LAST 6 ORDERS)
  List<FlSpot> salesSpots(List<Order> orders) {
    final recent = orders.reversed.take(6).toList();
    return List.generate(
      recent.length,
      (i) => FlSpot(i.toDouble(), recent[i].totalPrice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final orderProvider = context.watch<OrderProvider>();

    final products = productProvider.products;
    final orders = orderProvider.orders;

    final loading = productProvider.isLoading || orderProvider.isLoading;

    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.green.shade700,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  /// ================= SUMMARY CARDS =================
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 900 ? 4 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 3,
                    children: [
                      _navCard(
                        context,
                        title: 'Products',
                        value: totalProducts(products).toString(),
                        icon: Icons.inventory_2,
                        color: Colors.orange.shade100,
                        screen: const ProductsScreen(),
                      ),

                      /// 🔴 NEW ORDERS
                      _badgeCard(
                        context,
                        title: 'New Orders',
                        value: pendingOrders(orders).toString(),
                        badge: pendingOrders(orders),
                        icon: Icons.notifications_active,
                        color: Colors.red.shade100,
                        screen: const OrdersScreen(),
                      ),

                      _navCard(
                        context,
                        title: 'Revenue',
                        value: '₹${totalRevenue(orders).toStringAsFixed(0)}',
                        icon: Icons.currency_rupee,
                        color: Colors.green.shade100,
                        screen: const OrdersScreen(showOnlyPaid: true),
                      ),

                      _navCard(
                        context,
                        title: 'Items Sold',
                        value: totalItemsSold(orders).toString(),
                        icon: Icons.shopping_bag,
                        color: Colors.purple.shade100,
                        screen: const OrdersScreen(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  /// ================= SALES GRAPH =================
                  _sectionTitle('Sales Overview'),
                  SizedBox(
                    height: 220,
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
                            color: Colors.green.shade700,
                            barWidth: 3,
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.green.withOpacity(0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// ================= ADMIN ANALYTICS =================
                  _sectionTitle('Admin Analytics'),

                  _analyticsTile(
                    context,
                    icon: Icons.warning,
                    color: Colors.red,
                    title: 'Dead Products',
                    subtitle: 'Stock but never sold',
                    screen: const DeadProductsScreen(),
                  ),

                  _analyticsTile(
                    context,
                    icon: Icons.inventory,
                    color: Colors.orange,
                    title: 'Low Stock Products',
                    subtitle:
                        'Items ≤ 5 (${lowStockCount(products)})',
                    screen: const LowStockProductsScreen(),
                  ),
                ],
              ),
            ),
    );
  }

  /// ================= UI HELPERS =================
  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _navCard(BuildContext context,
      {required String title,
      required String value,
      required IconData icon,
      required Color color,
      required Widget screen}) {
    return InkWell(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      child: DashboardCard(
        title: title,
        value: value,
        icon: icon,
        color: color,
      ),
    );
  }

  Widget _badgeCard(BuildContext context,
      {required String title,
      required String value,
      required int badge,
      required IconData icon,
      required Color color,
      required Widget screen}) {
    return Stack(
      children: [
        _navCard(context,
            title: title,
            value: value,
            icon: icon,
            color: color,
            screen: screen),
        if (badge > 0)
          Positioned(
            right: 12,
            top: 12,
            child: CircleAvatar(
              radius: 10,
              backgroundColor: Colors.red,
              child: Text(
                badge.toString(),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          )
      ],
    );
  }

  Widget _analyticsTile(BuildContext context,
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      required Widget screen}) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      ),
    );
  }
}

/// ================= CARD =================
class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const DashboardCard(
      {super.key,
      required this.title,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 40),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.green.shade700),
            child: const Text(
              'Admin Panel',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          _drawerItem(
            context,
            Icons.inventory_2,
            'Products',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductsScreen()),
              );
            },
          ),
          _drawerItem(
            context,
            Icons.shopping_cart,
            'Orders',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdersScreen()),
              );
            },
          ),
          _drawerItem(
            context,
            Icons.people,
            'Customers',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomersScreen()),
              );
            },
          ),
          _drawerItem(
            context,
            Icons.bar_chart,
            'Reports',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportsScreen()),
              );
            },
          ),
          _drawerItem(
            context,
            Icons.settings,
            'Settings',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
      BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.green.shade700),
      title: Text(title),
      onTap: onTap,
    );
  }
}
