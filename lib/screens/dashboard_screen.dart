import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../providers/product_provider.dart';
import '../providers/order_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    await productProvider.fetchProducts();
    await orderProvider.fetchOrders();
  }

  int getTotalOrders(List<Order> orders) => orders.length;

  int getTotalProducts(List<Product> products) => products.length;

  double getTotalRevenue(List<Order> orders) =>
      orders.fold(0.0, (sum, order) => sum + order.totalPrice);

  int getTotalPurchasedQuantity(List<Order> orders) {
    int totalQty = 0;
    for (final order in orders) {
      for (final product in order.products) {
        totalQty += product.quantity;
      }
    }
    return totalQty;
  }

  List<MapEntry<String, int>> getTopSellingProducts(List<Order> orders) {
    final Map<String, int> productCountMap = {};
    for (final order in orders) {
      for (final product in order.products) {
        productCountMap[product.name] =
            (productCountMap[product.name] ?? 0) + product.quantity;
      }
    }
    final sortedEntries = productCountMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);

    final allProducts = productProvider.products;
    final allOrders = orderProvider.orders;

    final totalRevenue = getTotalRevenue(allOrders);
    final totalPurchasedQty = getTotalPurchasedQuantity(allOrders);
    final topProducts = getTopSellingProducts(allOrders);

    final isLoading = productProvider.isLoading || orderProvider.isLoading;
    final productError = productProvider.errorMessage ?? orderProvider.errorMessage;

    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload Data',
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Refreshing data...')),
              );
              await _loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dashboard updated successfully')),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : productError != null
              ? Center(
                  child: Text(
                    productError,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      // ---- Summary Cards ----
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount:
                            MediaQuery.of(context).size.width > 900 ? 4 : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 3,
                        children: [
                          DashboardCard(
                            title: 'Total Products',
                            value: getTotalProducts(allProducts).toString(),
                            icon: Icons.inventory_2_outlined,
                            color: Colors.orange.shade100,
                            onTap: () => Navigator.pushNamed(context, '/manage-products'),
                          ),
                          DashboardCard(
                            title: 'Total Orders',
                            value: getTotalOrders(allOrders).toString(),
                            icon: Icons.shopping_cart_checkout_rounded,
                            color: Colors.blue.shade100,
                            onTap: () => Navigator.pushNamed(context, '/manage-orders'),
                          ),
                          DashboardCard(
                            title: 'Total Sale',
                            value: '₹${totalRevenue.toStringAsFixed(2)}',
                            icon: Icons.currency_rupee_rounded,
                            color: Colors.green.shade100,
                          ),
                          DashboardCard(
                            title: 'Total Purchase',
                            value: totalPurchasedQty.toString(),
                            icon: Icons.shopping_bag_outlined,
                            color: Colors.purple.shade100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // ---- Sales Overview Chart ----
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Sales Overview",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: LineChart(
                                LineChartData(
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: true)),
                                    bottomTitles: AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: true)),
                                  ),
                                  gridData: FlGridData(
                                      show: true, drawVerticalLine: false),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      isCurved: true,
                                      color: Colors.green.shade700,
                                      spots: allOrders.isEmpty
                                          ? [const FlSpot(0, 0)]
                                          : allOrders
                                              .asMap()
                                              .entries
                                              .map((entry) => FlSpot(
                                                    (entry.key + 1).toDouble(),
                                                    entry.value.totalPrice
                                                        .toDouble(),
                                                  ))
                                              .toList(),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Colors.green.shade100,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ---- Top Selling Products ----
                      const Text(
                        'Top Selling Products',
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (topProducts.isEmpty)
                        const Center(
                            child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text("No product sales data available."),
                        ))
                      else
                        ...topProducts.map(
                          (entry) => ListTile(
                            leading: const Icon(Icons.local_grocery_store),
                            title: Text(entry.key),
                            trailing: Text('Sold: ${entry.value}'),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.black54),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
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
              ),
            ],
          ),
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
          _drawerItem(context, Icons.dashboard, 'Dashboard', () {
            Navigator.pushReplacementNamed(context, '/dashboardScreen');
          }),
          _drawerItem(context, Icons.inventory_2, 'Products', () {
            Navigator.pushNamed(context, '/manage-products');
          }),
          _drawerItem(context, Icons.shopping_cart, 'Orders', () {
            Navigator.pushNamed(context, '/manage-orders');
          }),
          _drawerItem(context, Icons.people, 'Customers', () {}),
          _drawerItem(context, Icons.bar_chart, 'Reports', () {}),
          _drawerItem(context, Icons.settings, 'Settings', () {}),
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
