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

class _PurchaseReturnsScreenState extends State<PurchaseReturnsScreen> {
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

                  // ── Header ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Purchase Returns',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('New Return'),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AddPurchaseReturnScreen(),
                            ),
                          );
                          // ✅ Refresh list after coming back
                          if (mounted) {
                            context
                                .read<PurchaseReturnProvider>()
                                .fetchReturns();
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Content ──────────────────────────────────
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border:
                            Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(6),
                      ),

                      // ── Error State ────────────────────────
                      child: provider.error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.wifi_off_outlined,
                                      size: 48,
                                      color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    provider.error!,
                                    style: const TextStyle(
                                        color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Colors.green),
                                    icon: const Icon(Icons.refresh,
                                        color: Colors.white),
                                    label: const Text('Retry',
                                        style: TextStyle(
                                            color: Colors.white)),
                                    onPressed: () => context
                                        .read<PurchaseReturnProvider>()
                                        .fetchReturns(),
                                  ),
                                ],
                              ),
                            )

                          // ── Empty State ────────────────────
                          : provider.returns.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.assignment_return_outlined,
                                        size: 56,
                                        color: Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No purchase returns yet',
                                        style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 15),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Tap "New Return" to add one',
                                        style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                )

                              // ── Data Table ─────────────────
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: DataTable(
                                      headingRowColor:
                                          MaterialStateProperty.all(
                                        const Color(0xFFF9FAFB),
                                      ),
                                      columnSpacing: 24,
                                      columns: const [
                                        DataColumn(
                                            label: Text('Supplier')),
                                        DataColumn(
                                            label: Text('Items')),
                                        DataColumn(
                                            label: Text('Reasons')),
                                        DataColumn(
                                            label: Text('Date')),
                                      ],
                                      rows: provider.returns.map((r) {
                                        // Collect unique reasons
                                        final reasons = r.items
                                            .map((i) => i.reason)
                                            .toSet()
                                            .join(', ');

                                        return DataRow(
                                          cells: [
                                            // Supplier
                                            DataCell(
                                              Text(
                                                r.supplierName,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            ),

                                            // Items count
                                            DataCell(
                                              Container(
                                                padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(6),
                                                ),
                                                child: Text(
                                                  '${r.items.length} item${r.items.length == 1 ? '' : 's'}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // Reasons
                                            DataCell(
                                              Text(
                                                reasons.isEmpty
                                                    ? '—'
                                                    : reasons,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey),
                                              ),
                                            ),

                                            // Date
                                            DataCell(
                                              Text(
                                                r.date
                                                    .toLocal()
                                                    .toString()
                                                    .substring(0, 10),
                                                style: const TextStyle(
                                                    fontSize: 13),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
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