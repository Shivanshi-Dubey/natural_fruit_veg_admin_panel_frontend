import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LowStockProductsScreen extends StatefulWidget {
  const LowStockProductsScreen({super.key});

  @override
  State<LowStockProductsScreen> createState() =>
      _LowStockProductsScreenState();
}

class _LowStockProductsScreenState extends State<LowStockProductsScreen> {
  bool isLoading = true;
  List products = [];

  @override
  void initState() {
    super.initState();
    fetchLowStockProducts();
  }

  Future<void> fetchLowStockProducts() async {
    try {
      final res = await http.get(
        Uri.parse(
            'https://naturalfruitveg.com/api/admin/analytics/low-stock'),
      );

      final data = jsonDecode(res.body);
      setState(() {
        products = data['products'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Low stock error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Low Stock Products'),
        backgroundColor: Colors.orange,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(child: Text("No low stock products 🎉"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: products.length,
                  itemBuilder: (_, i) {
                    final p = products[i];
                    final stock = p['stock'] ?? 0;

                    return Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.warning,
                          color: stock <= 2
                              ? Colors.red
                              : Colors.orange,
                        ),
                        title: Text(p['name']),
                        subtitle: Text(
                            "Stock left: $stock • ₹${p['price']}"),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            // future: restock action
                          },
                          child: const Text("Restock"),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
