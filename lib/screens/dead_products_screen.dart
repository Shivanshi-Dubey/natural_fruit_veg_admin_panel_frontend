import 'package:flutter/material.dart';
import '../../services/admin_analytics_service.dart';

class DeadProductsScreen extends StatefulWidget {
  const DeadProductsScreen({super.key});

  @override
  State<DeadProductsScreen> createState() => _DeadProductsScreenState();
}

class _DeadProductsScreenState extends State<DeadProductsScreen> {
  bool isLoading = true;
  List<dynamic> products = [];

  @override
  void initState() {
    super.initState();
    loadDeadProducts();
  }

  Future<void> loadDeadProducts() async {
    final data = await AdminAnalyticsService.fetchDeadProducts();
    setState(() {
      products = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dead Products"),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(child: Text("🎉 No dead products"))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (_, i) {
                    final p = products[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.warning,
                            color: Colors.orange),
                        title: Text(p['name'] ?? 'Unknown'),
                        subtitle: Text("Stock: ${p['stock']}"),
                      ),
                    );
                  },
                ),
    );
  }
}
