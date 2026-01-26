import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
import '../providers/grn_provider.dart';
import '../models/grn_model.dart';

class GrnScreen extends StatefulWidget {
  const GrnScreen({super.key});

  @override
  State<GrnScreen> createState() => _GrnScreenState();
}

class _GrnScreenState extends State<GrnScreen> {
  @override
  void initState() {
    super.initState();

    /// Load GRNs from backend
    Future.microtask(() {
      context.read<GRNProvider>().fetchGRNs();
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Goods Receipt Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create GRN'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateGrnScreen(),
                      ),
                    );
                  },
                ),
              ],
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
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('GRN No')),
                                DataColumn(label: Text('Supplier')),
                                DataColumn(label: Text('Date')),
                                DataColumn(label: Text('Status')),
                              ],
                              rows: provider.grns.map((GRN g) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        g.grnNumber,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    DataCell(Text(g.supplierName)),
                                    DataCell(
                                      Text(
                                        g.createdAt
                                            .toLocal()
                                            .toString()
                                            .substring(0, 10),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        g.status,
                                        style: TextStyle(
                                          color: g.status == 'Received'
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
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
