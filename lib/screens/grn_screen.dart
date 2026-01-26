import 'package:flutter/material.dart';

import '../layouts/admin_layout.dart';

class GrnScreen extends StatelessWidget {
  const GrnScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('GRN No')),
                    DataColumn(label: Text('Supplier')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: const [
                    /// Dummy row (safe placeholder)
                    DataRow(
                      cells: [
                        DataCell(Text('GRN-001')),
                        DataCell(Text('Fresh Farm Supplier')),
                        DataCell(Text('2026-01-26')),
                        DataCell(
                          Text(
                            'Received',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ],
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

            /// ===== SUPPLIER =====
            TextField(
              decoration: InputDecoration(
                labelText: 'Supplier Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// ===== INVOICE =====
            TextField(
              decoration: InputDecoration(
                labelText: 'Purchase Invoice No',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// ===== DATE =====
            TextField(
              decoration: InputDecoration(
                labelText: 'Received Date',
                hintText: 'YYYY-MM-DD',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            const SizedBox(height: 32),

            /// ===== ACTION =====
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('GRN created (placeholder)'),
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
