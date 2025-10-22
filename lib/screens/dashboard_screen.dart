import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

    // ✅ Fetch data only once when the screen is opened
    Future.microtask(() {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      Provider.of<OrderProvider>(context, listen: false).fetchOrders();
    });
  }

  int getTotalOrders(List<Order> orders) => orders.length;

  int getTotalProducts(List<Product> products) => products.length;

  double getTotalRevenue(List<Order> orders) {
    return orders.fold(0.0, (sum, order) => sum + order.totalPrice);
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
    final topProducts = getTopSellingProducts(allOrders);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.green.shade700,
      ),
      body: productProvider.isLoading || orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 600 ? 3 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 3,
                    children: [
                      DashboardCard(
                        title: 'Total Products',
                        value: getTotalProducts(allProducts).toString(),
                        icon: Icons.inventory_2_outlined,
                        color: Colors.orange.shade100,
                      ),
                      DashboardCard(
                        title: 'Total Orders',
                        value: getTotalOrders(allOrders).toString(),
                        icon: Icons.shopping_cart_checkout_rounded,
                        color: Colors.blue.shade100,
                      ),
                      DashboardCard(
                        title: 'Revenue',
                        value: '₹${totalRevenue.toStringAsFixed(2)}',
                        icon: Icons.currency_rupee_rounded,
                        color: Colors.green.shade100,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Top Selling Products',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  topProducts.isEmpty
                      ? const Text('No top-selling products yet.')
                      : Column(
                          children: topProducts.map(
                            (entry) => ListTile(
                              leading: const Icon(Icons.local_grocery_store),
                              title: Text(entry.key),
                              trailing: Text('Sold: ${entry.value}'),
                            ),
                          ).toList(),
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

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 30, color: Colors.black54),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
