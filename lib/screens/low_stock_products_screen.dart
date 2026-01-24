import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../layouts/admin_layout.dart';

class LowStockProductsScreen extends StatefulWidget {
  const LowStockProductsScreen({super.key});

  @override
  State<LowStockProductsScreen> createState() =>
      _LowStockProductsScreenState();
}

class _LowStockProductsScreenState
    extends State<LowStockProductsScreen> {
  bool isLoading = true;
  List<dynamic> products = [];

  @override
  void initState() {
    super.initState();
    fetchLowStockProducts();
  }

  Future<void> fetchLowStockProducts() async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://naturalfruitveg.com/api/admin/analytics/low-stock',
        ),
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
    return AdminLayout(
      title: 'Low Stock Products',
      showBack: true,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(
                  child: Text(
                    'No low stock products 🎉',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// ================= HEADER =================
                      const Text(
                        'Inventory Alerts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      /// ================= TABLE =================
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                                color: const Color(0xFFE5E7EB)),
                            borderRadius:
                                BorderRadius.circular(6),
                          ),
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowColor:
                                  MaterialStateProperty.all(
                                      const Color(0xFFF9FAFB)),
                              columns: const [
                                DataColumn(label: Text('Product')),
                                DataColumn(label: Text('Price')),
                                DataColumn(label: Text('Stock')),
                                DataColumn(label: Text('Severity')),
                                DataColumn(label: Text('Action')),
                              ],
                              rows: products.map((p) {
                                final int stock = p['stock'] ?? 0;
                                final bool critical = stock <= 2;

                                return DataRow(
                                  cells: [
                                    DataCell(Text(p['name'] ?? '—')),
                                    DataCell(
                                      Text('₹${p['price'] ?? 0}'),
                                    ),
                                    DataCell(Text(stock.toString())),
                                    DataCell(
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4),
                                        decoration: BoxDecoration(
                                          color: critical
                                              ? Colors.red
                                                  .withOpacity(0.1)
                                              : Colors.orange
                                                  .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          critical
                                              ? 'CRITICAL'
                                              : 'LOW',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight.w600,
                                            color: critical
                                                ? Colors.red
                                                : Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      TextButton(
                                        onPressed: () {
                                          // Future: navigate to edit product / restock
                                        },
                                        child:
                                            const Text('Restock'),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
