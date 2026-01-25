import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
import '../providers/purchase_invoice_provider.dart';

class PurchaseInvoicesScreen extends StatefulWidget {
  const PurchaseInvoicesScreen({super.key});

  @override
  State<PurchaseInvoicesScreen> createState() =>
      _PurchaseInvoicesScreenState();
}

class _PurchaseInvoicesScreenState
    extends State<PurchaseInvoicesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<PurchaseInvoiceProvider>().fetchInvoices());
  }

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<PurchaseInvoiceProvider>();

    return AdminLayout(
      title: 'Purchase Invoices',
      child: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text(provider.error!))
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// HEADER
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Purchase Invoice List',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Create Invoice'),
                            onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const CreatePurchaseInvoiceScreen(),
    ),
  );
},

                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      /// TABLE
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                                color: const Color(0xFFE5E7EB)),
                            borderRadius:
                                BorderRadius.circular(6),
                          ),
                          child: provider.invoices.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No purchase invoices found',
                                    style: TextStyle(
                                        color: Colors.grey),
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: DataTable(
                                    headingRowColor:
                                        MaterialStateProperty.all(
                                      const Color(0xFFF9FAFB),
                                    ),
                                    columns: const [
                                      DataColumn(
                                          label: Text('Invoice')),
                                      DataColumn(
                                          label: Text('Supplier')),
                                      DataColumn(
                                          label: Text('Amount')),
                                      DataColumn(
                                          label: Text('Status')),
                                      DataColumn(
                                          label: Text('Date')),
                                    ],
                                    rows: provider.invoices.map((i) {
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                              Text(i.invoiceNumber)),
                                          DataCell(
                                              Text(i.supplierName)),
                                          DataCell(Text(
                                              '₹${i.totalAmount.toStringAsFixed(0)}')),
                                          DataCell(_statusChip(i.status)),
                                          DataCell(Text(
                                            '${i.createdAt.day}/${i.createdAt.month}/${i.createdAt.year}',
                                          )),
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

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'approved':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
