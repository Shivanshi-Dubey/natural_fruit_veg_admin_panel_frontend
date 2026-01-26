import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
import '../providers/purchase_return_provider.dart';
import '../screens/add_purchase_return_screen.dart';


class PurchaseReturnsScreen extends StatefulWidget {
  const PurchaseReturnsScreen({super.key});

  @override
  State<PurchaseReturnsScreen> createState() =>
      _PurchaseReturnsScreenState();
}

class _PurchaseReturnsScreenState
    extends State<PurchaseReturnsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<PurchaseReturnProvider>().fetchReturns());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PurchaseReturnProvider>();

    return AdminLayout(
      title: 'Purchase Returns',
      child: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Direct Purchase Returns',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('New Return'),
                       onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const AddPurchaseReturnScreen(),
    ),
  );
},

                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: const Color(0xFFE5E7EB)),
                        borderRadius:
                            BorderRadius.circular(6),
                      ),
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Supplier')),
                          DataColumn(label: Text('Date')),
                        ],
                        rows: provider.returns.map((r) {
                          return DataRow(
                            cells: [
                              DataCell(Text(r.supplierName)),
                              DataCell(Text(
                                r.date
                                    .toLocal()
                                    .toString()
                                    .substring(0, 10),
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
