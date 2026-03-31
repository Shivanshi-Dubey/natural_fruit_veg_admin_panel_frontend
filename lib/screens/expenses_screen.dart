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

  @override
  void initState() {
    super.initState();
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    final res = await http.get(
      Uri.parse("https://naturalfruitveg.com/api/admin/expenses/today"),
    );

    final data = jsonDecode(res.body);

    setState(() {
      handling = data['handlingTotal'];
      delivery = data['deliveryTotal'];
      total = data['totalProfit'];
      orders = data['totalOrders'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Earnings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            _card("Handling Charges", handling, Colors.blue),
            _card("Delivery Charges", delivery, Colors.orange),
            _card("Total Profit", total, Colors.green),

            const SizedBox(height: 20),

            Text("Orders Today: $orders"),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, double amount, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.currency_rupee, color: color),
        title: Text(title),
        trailing: Text(
          "₹${amount.toStringAsFixed(0)}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}