import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  double handling = 0;
  double delivery = 0;
  double total = 0;
  int orders = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    try {
      final res = await http.get(
        Uri.parse("https://naturalfruitveg.com/api/admin/expenses/today"),
      );

      final data = jsonDecode(res.body);

      setState(() {
        handling = (data['handlingTotal'] ?? 0).toDouble();
        delivery = (data['deliveryTotal'] ?? 0).toDouble();
        total = (data['totalProfit'] ?? 0).toDouble();
        orders = data['totalOrders'] ?? 0;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Expenses Dashboard"),
        automaticallyImplyLeading: false, // ❌ remove back button
        elevation: 0,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// 🔥 HEADER
                  const Text(
                    "Today's Earnings",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Overview of your daily revenue",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 20),

                  /// 🔥 CARDS GRID
                  Row(
                    children: [
                      Expanded(
                        child: _dashboardCard(
                          title: "Handling",
                          amount: handling,
                          color: Colors.blue,
                          icon: Icons.inventory,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dashboardCard(
                          title: "Delivery",
                          amount: delivery,
                          color: Colors.orange,
                          icon: Icons.delivery_dining,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  /// TOTAL CARD
                  _dashboardCard(
                    title: "Total Profit",
                    amount: total,
                    color: Colors.green,
                    icon: Icons.trending_up,
                    big: true,
                  ),

                  const SizedBox(height: 20),

                  /// ORDERS CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shopping_bag),
                        const SizedBox(width: 10),
                        Text(
                          "Orders Today: $orders",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// 🔥 MODERN CARD
  Widget _dashboardCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
    bool big = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),

          const SizedBox(height: 10),

          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "₹${amount.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: big ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}