import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
import '../providers/supplier_provider.dart';
import 'add_supplier_screen.dart'; // uncomment when screen is ready
// import 'supplier_details_screen.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<SupplierProvider>().fetchSuppliers(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SupplierProvider>();

    return AdminLayout(
      title: 'Suppliers',
      child: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(
                  child: Text(
                    provider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ================= HEADER =================
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Suppliers List',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Supplier'),
                            onPressed: () {
              
                               Navigator.push(
                                 context,
                                 MaterialPageRoute(
                                   builder: (_) => const AddSupplierScreen(),
                                 ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ================= TABLE =================
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor:
                                  MaterialStateProperty.all(
                                const Color(0xFFF9FAFB),
                              ),
                              columns: const [
                                DataColumn(label: Text('Supplier Name')),
                                DataColumn(label: Text('Phone')),
                                DataColumn(label: Text('GST Number')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: provider.suppliers.map((s) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        s.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(s.phone)),
                                    DataCell(
                                      Text(
                                        s.gstNumber.isEmpty
                                            ? '—'
                                            : s.gstNumber,
                                      ),
                                    ),
                                    DataCell(_statusChip(s.isActive)),
                                    DataCell(
                                      Row(
                                        children: [
                                          IconButton(
                                            tooltip: 'View',
                                            icon: const Icon(
                                              Icons.visibility,
                                              size: 18,
                                            ),
                                            onPressed: () {
                                              // TODO: SupplierDetailsScreen
                                            },
                                          ),
                                          IconButton(
                                            tooltip: 'Delete',
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 18,
                                            ),
                                            onPressed: () async {
                                              final confirm =
                                                  await _confirmDelete(
                                                      context);
                                              if (confirm) {
                                                await provider
                                                    .deleteSupplier(s.id);
                                              }
                                            },
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

  // ================= STATUS CHIP =================
  Widget _statusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.12)
            : Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  // ================= CONFIRM DELETE =================
  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete Supplier'),
            content: const Text(
                'Are you sure you want to delete this supplier?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
