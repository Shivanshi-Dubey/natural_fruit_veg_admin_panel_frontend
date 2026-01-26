import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
import '../providers/grn_provider.dart';
import '../models/grn_model.dart';

class GrnScreen extends StatefulWidget {
  final String purchaseInvoiceId;

  const GrnScreen({
    super.key,
    required this.purchaseInvoiceId,
  });


  @override
  State<GrnScreen> createState() => _GrnScreenState();
}

class _GrnScreenState extends State<GrnScreen> {
 @override
void initState() {
  super.initState();
  Future.microtask(() {
    context
        .read<GRNProvider>()
        .fetchGRNsByInvoice(widget.purchaseInvoiceId);
  });
}


  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GRNProvider>();

    return AdminLayout(
      title: 'GRN (Goods Receipt Note)',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ===== HEADER =====
            const Text(
              'Goods Receipt Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            /// ===== TABLE =====
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : provider.grns.isEmpty
                        ? const Center(child: Text('No GRNs found'))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor:
                                  MaterialStateProperty.all(
                                const Color(0xFFF9FAFB),
                              ),
                              columns: const [
                                DataColumn(label: Text('GRN No')),
                                DataColumn(label: Text('Supplier')),
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Status')),
                              ],
                              rows: provider.grns.map((GRN g) {
                                return DataRow(
                                  cells: [
                                    /// GRN NUMBER
                                    DataCell(
                                      Text(
                                        g.grnNumber,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),

                                    /// SUPPLIER
                                    DataCell(Text(g.supplierName)),

                                    /// DATE
                                    DataCell(
                                      Text(
                                        g.createdAt
                                            .toLocal()
                                            .toString()
                                            .substring(0, 10),
                                      ),
                                    ),

                                    /// STATUS
                                    DataCell(_statusChip(g.status)),
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

  /// ===== STATUS CHIP =====
  Widget _statusChip(String status) {
    Color color;

    switch (status) {
      case 'received':
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

//
// ================= CREATE GRN SCREEN =================
//

class CreateGrnScreen extends StatelessWidget {
  const CreateGrnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Create GRN',
      showBack: true,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Goods Receipt Note',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              decoration: InputDecoration(
                labelText: 'Supplier',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              decoration: InputDecoration(
                labelText: 'Purchase Invoice',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              decoration: InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('GRN creation coming next phase'),
                  ),
                );
                Navigator.pop(context);
              },
              child: const Text('Save GRN'),
            ),
          ],
        ),
      ),
    );
  }
}
