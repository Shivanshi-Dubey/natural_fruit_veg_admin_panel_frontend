import 'package:flutter/material.dart';

import '../layouts/admin_layout.dart';
import '../services/admin_analytics_service.dart';

class DeadProductsScreen extends StatefulWidget {
  const DeadProductsScreen({super.key});

  @override
  State<DeadProductsScreen> createState() =>
      _DeadProductsScreenState();
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
    return AdminLayout(
      title: 'Dead Products',
      showBack: true,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(
                  child: Text(
                    '🎉 No dead products',
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
                        'Products Never Sold',
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
                                DataColumn(label: Text('Stock')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Action')),
                              ],
                              rows: products.map((p) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        p['name'] ?? 'Unknown',
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.w600),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                          p['stock']?.toString() ??
                                              '0'),
                                    ),
                                    DataCell(
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange
                                              .withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'DEAD',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight.w600,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Row(
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              // Future: discount / re-activate product
                                            },
                                            child:
                                                const Text('Revive'),
                                          ),
                                        ],
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
