import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../providers/product_provider.dart';
import '../providers/order_provider.dart';
import 'order_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      print("📦 Fetching products and orders...");
      await productProvider.fetchProducts();
      await orderProvider.fetchOrders();

      print("✅ Products fetched: ${productProvider.products.length}");
      print("✅ Orders fetched: ${orderProvider.orders.length}");
    });
  }

  double getTotalRevenue(List<Order> orders) {
    double total = 0.0;
    for (var order in orders) {
      for (var p in order.products) {
        total += (p.price * p.quantity);
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);

    final products = productProvider.products;
    final orders = orderProvider.orders;
    final totalRevenue = getTotalRevenue(orders);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.green.shade700,
      ),
      body: productProvider.isLoading || orderProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : productProvider.errorMessage != null
              ? Center(child: Text(productProvider.errorMessage!))
              : orderProvider.errorMessage != null
                  ? Center(child: Text(orderProvider.errorMessage!))
                  : Padding(
                      padding: const EdgeInsets.all(16),
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
                                value: products.length.toString(),
                                icon: Icons.inventory_2_outlined,
                                color: Colors.orange.shade100,
                              ),
                              DashboardCard(
                                title: 'Total Orders',
                                value: orders.length.toString(),
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
                          const SizedBox(height: 20),
                          const Text(
                            "Recent Orders",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          if (orders.isEmpty)
                            const Text("No orders yet.")
                          else
                            Column(
                              children: orders.map((o) {
                                return ListTile(
                                  title: Text("Order ID: ${o.id}"),
                                  subtitle: Text("Status: ${o.status}"),
                                  trailing: Text("Items: ${o.products.length}"),
                                );
                              }).toList(),
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
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
