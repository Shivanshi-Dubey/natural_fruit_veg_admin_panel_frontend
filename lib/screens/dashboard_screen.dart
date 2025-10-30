import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/product_provider.dart';
import '../providers/order_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);

    final totalProducts = productProvider.products.length;
    final totalOrders = orderProvider.orders.length;
    final totalSale = orderProvider.orders.fold<double>(
      0.0,
      (sum, order) => sum + order.totalAmount,
    );
    final totalPurchase = 0.0; // You can link to purchase data later

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Top Info Cards ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoCard(
                  context,
                  title: "Total Products",
                  value: "$totalProducts",
                  icon: Icons.inventory_2_outlined,
                  color: Colors.orange[100]!,
                  onTap: () => Navigator.pushNamed(context, '/manage-products'),
                ),
                _buildInfoCard(
                  context,
                  title: "Total Orders",
                  value: "$totalOrders",
                  icon: Icons.shopping_cart_outlined,
                  color: Colors.blue[100]!,
                  onTap: () => Navigator.pushNamed(context, '/manage-orders'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoCard(
                  context,
                  title: "Total Sale",
                  value: "₹${totalSale.toStringAsFixed(2)}",
                  icon: Icons.currency_rupee,
                  color: Colors.green[100]!,
                ),
                _buildInfoCard(
                  context,
                  title: "Total Purchase",
                  value: totalPurchase.toStringAsFixed(0),
                  icon: Icons.shopping_bag_outlined,
                  color: Colors.purple[100]!,
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- Sales Chart ---
            const Text(
              "Sales Overview",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 250,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(show: true),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: orderProvider.orders.isEmpty
                          ? [const FlSpot(0, 0)]
                          : orderProvider.orders
                              .asMap()
                              .entries
                              .map((e) => FlSpot(
                                    (e.key + 1).toDouble(),
                                    e.value.totalAmount.toDouble(),
                                  ))
                              .toList(),
                      isCurved: true,
                      color: Colors.green,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.3),
                      ),
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widget for Dashboard Info Cards ---
  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(2, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: Colors.black54),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
