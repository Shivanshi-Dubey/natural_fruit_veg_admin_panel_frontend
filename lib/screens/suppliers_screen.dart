import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../layouts/admin_layout.dart';
import '../providers/supplier_provider.dart';
import 'add_supplier_screen.dart';
import 'supplier_detail_screen.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  String searchQuery = '';

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

    final filtered = provider.suppliers
        .where((s) =>
            s.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            s.phone.contains(searchQuery))
        .toList();

    return AdminLayout(
      title: 'Suppliers',
      child: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? _errorView(provider)
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /* =========================
                         🔝 HEADER
                      ========================= */
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Suppliers',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "${provider.suppliers.length} supplier${provider.suppliers.length == 1 ? '' : 's'}",
                                style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Supplier'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const AddSupplierScreen(),
                                ),
                              ).then((_) => provider
                                  .fetchSuppliers());
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      /* =========================
                         🔍 SEARCH
                      ========================= */
                      TextField(
                        decoration: InputDecoration(
                          hintText:
                              'Search by name or phone...',
                          prefixIcon:
                              const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 16),
                        ),
                        onChanged: (v) =>
                            setState(() => searchQuery = v),
                      ),

                      const SizedBox(height: 16),

                      /* =========================
                         📊 SUMMARY CARDS
                      ========================= */
                      Row(
                        children: [
                          _summaryCard(
                            "Total",
                            provider.suppliers.length
                                .toString(),
                            Icons.people_outline,
                            Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          _summaryCard(
                            "Active",
                            provider.suppliers
                                .where((s) => s.isActive)
                                .length
                                .toString(),
                            Icons.check_circle_outline,
                            Colors.green,
                          ),
                          const SizedBox(width: 12),
                          _summaryCard(
                            "Inactive",
                            provider.suppliers
                                .where((s) => !s.isActive)
                                .length
                                .toString(),
                            Icons.cancel_outlined,
                            Colors.red,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      /* =========================
                         📋 SUPPLIER LIST
                      ========================= */
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () =>
                              provider.fetchSuppliers(),
                          child: filtered.isEmpty
                              ? _emptyState()
                              : ListView.builder(
                                  itemCount: filtered.length,
                                  itemBuilder: (_, i) =>
                                      _buildSupplierCard(
                                          filtered[i],
                                          provider),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  /* =========================
     🧩 SUPPLIER CARD
  ========================= */
 Widget _buildSupplierCard(dynamic s, SupplierProvider provider) {
    final initials = s.name.length >= 2
        ? s.name.substring(0, 2).toUpperCase()
        : s.name.toUpperCase();

    return GestureDetector(
      // ✅ Now navigates to SupplierDetailScreen instead of bottom sheet
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SupplierDetailScreen(supplier: s),
        ),
      ).then((_) => provider.fetchSuppliers()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 6)
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  const Color(0xFF2E7D32).withOpacity(0.1),
              child: Text(initials,
                  style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.phone,
                        size: 13, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(s.phone,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ]),
                  if (s.gstNumber.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.receipt_outlined,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text("GST: ${s.gstNumber}",
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                    ]),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _statusChip(s.isActive),
                const SizedBox(height: 8),
                const Icon(Icons.chevron_right,
                    color: Colors.grey, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }


  /* =========================
     📄 SUPPLIER DETAILS BOTTOM SHEET
  ========================= */
  void _showSupplierDetails(
      dynamic s, SupplierProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF2E7D32)
                        .withOpacity(0.1),
                    child: Text(
                      s.name.length >= 2
                          ? s.name
                              .substring(0, 2)
                              .toUpperCase()
                          : s.name.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _statusChip(s.isActive),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Details
              _detailRow(Icons.phone, "Phone", s.phone),
              const SizedBox(height: 12),

              if (s.gstNumber.isNotEmpty) ...[
                _detailRow(Icons.receipt_outlined, "GST Number",
                    s.gstNumber),
                const SizedBox(height: 12),
              ],

              if ((s.address ?? '').isNotEmpty) ...[
                _detailRow(Icons.location_on_outlined,
                    "Address", s.address),
                const SizedBox(height: 12),
              ],

              if ((s.email ?? '').isNotEmpty) ...[
                _detailRow(
                    Icons.email_outlined, "Email", s.email),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddSupplierScreen(
                              supplier: s,
                            ),
                          ),
                        ).then((_) =>
                            provider.fetchSuppliers());
                      },
                      icon: const Icon(Icons.edit_outlined,
                          size: 16),
                      label: const Text("Edit"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        final confirm =
                            await _confirmDelete(context);
                        if (confirm) {
                          await provider.deleteSupplier(s.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Supplier deleted"),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.delete_outline,
                          size: 16),
                      label: const Text("Delete"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /* =========================
     🧩 UI HELPERS
  ========================= */
  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(bool isActive) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.12)
            : Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            searchQuery.isNotEmpty
                ? "No suppliers match \"$searchQuery\""
                : "No suppliers yet",
            style: const TextStyle(color: Colors.grey),
          ),
          if (searchQuery.isEmpty) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32)),
              icon: const Icon(Icons.add),
              label: const Text("Add Supplier"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddSupplierScreen()),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _errorView(SupplierProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              color: Colors.red, size: 56),
          const SizedBox(height: 16),
          Text(provider.error!,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32)),
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            onPressed: () => provider.fetchSuppliers(),
          ),
        ],
      ),
    );
  }

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
                    backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}