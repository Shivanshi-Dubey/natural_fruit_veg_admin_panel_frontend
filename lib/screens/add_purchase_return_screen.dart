import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../layouts/admin_layout.dart';
import '../providers/supplier_provider.dart';
import '../providers/purchase_return_provider.dart';

class _ReturnItem {
  String productId;
  String productName;
  int quantity;
  String reason;

  _ReturnItem({
    this.productId = '',
    this.productName = '',
    this.quantity = 1,
    this.reason = 'Damaged',
  });
}

class AddPurchaseReturnScreen extends StatefulWidget {
  const AddPurchaseReturnScreen({super.key});

  @override
  State<AddPurchaseReturnScreen> createState() =>
      _AddPurchaseReturnScreenState();
}

class _AddPurchaseReturnScreenState
    extends State<AddPurchaseReturnScreen> {
  static const String baseUrl = 'https://naturalfruitveg.com/api';

  String? _selectedSupplierId;
  String? _selectedSupplierName;
  bool isSubmitting = false;

  List<_ReturnItem> _items = [_ReturnItem()];
  List<dynamic> _allProducts = [];
  bool _loadingProducts = true;

  final List<String> _reasons = [
    'Damaged',
    'Expired',
    'Wrong Item',
    'Quality Issue',
    'Excess Quantity',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    Future.microtask(() =>
        context.read<SupplierProvider>().fetchSuppliers());
  }

  Future<void> _loadProducts() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/products'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _allProducts = data is List ? data : (data['products'] ?? []);
          _loadingProducts = false;
        });
      } else {
        setState(() => _loadingProducts = false);
      }
    } catch (e) {
      setState(() => _loadingProducts = false);
    }
  }

  void _showProductPicker(int index) {
    String search = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select Product',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search product...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) =>
                    setModal(() => search = v.toLowerCase()),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 300,
                child: ListView(
                  children: _allProducts
                      .where((p) => (p['name'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(search))
                      .map((p) => ListTile(
                            title: Text(p['name'] ?? ''),
                            subtitle: Text(
                                '₹${p['price']} • Stock: ${p['stock'] ?? 0}'),
                            onTap: () {
                              Navigator.pop(context);
                              setState(() {
                                _items[index].productId =
                                    p['_id']?.toString() ?? '';
                                _items[index].productName =
                                    p['name']?.toString() ?? '';
                              });
                            },
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a supplier'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_items.any((i) => i.productId.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a product for each item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/admin/purchase-returns'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'supplierName': _selectedSupplierName,
          'supplierId': _selectedSupplierId,
          'items': _items
              .map((i) => {
                    'productId': i.productId,
                    'productName': i.productName,
                    'quantity': i.quantity,
                    'reason': i.reason,
                  })
              .toList(),
        }),
      );

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        // ✅ Refresh list
        await context.read<PurchaseReturnProvider>().fetchReturns();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Purchase return saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save return (${res.statusCode})'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'New Purchase Return',
      showBack: true,
      child: _loadingProducts
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Supplier Dropdown ──────────────────────────
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Return Details',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 14),
                        Consumer<SupplierProvider>(
                          builder: (ctx, supplierProvider, _) {
                            final suppliers =
                                supplierProvider.suppliers;
                            if (supplierProvider.isLoading) {
                              return const CircularProgressIndicator();
                            }
                            return DropdownButtonFormField<String>(
                              value: _selectedSupplierId,
                              decoration: const InputDecoration(
                                labelText: 'Select Supplier',
                                prefixIcon:
                                    Icon(Icons.person_outline),
                                border: OutlineInputBorder(),
                              ),
                              hint: const Text('Select Supplier'),
                              items: suppliers
                                  .map((s) => DropdownMenuItem(
                                        value: s.id,
                                        child: Text(s.name),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedSupplierId = val;
                                  _selectedSupplierName = suppliers
                                      .firstWhere((s) => s.id == val)
                                      .name;
                                });
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Items ──────────────────────────────────────
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Return Items',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            TextButton.icon(
                              onPressed: () => setState(
                                  () => _items.add(_ReturnItem())),
                              icon: const Icon(Icons.add,
                                  color: Colors.green),
                              label: const Text('Add Item',
                                  style: TextStyle(
                                      color: Colors.green)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._items.asMap().entries.map((e) =>
                            _buildItemRow(e.key, e.value)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Submit Button ──────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                      ),
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        isSubmitting ? 'Saving...' : 'Save Return',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildItemRow(int i, _ReturnItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product picker row
          Row(
            children: [
              Expanded(
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Product',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  child: Text(
                    item.productName.isEmpty
                        ? 'Tap Pick to select'
                        : item.productName,
                    style: TextStyle(
                      fontSize: 14,
                      color: item.productName.isEmpty
                          ? Colors.grey
                          : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _showProductPicker(i),
                child: const Text('Pick'),
              ),
              const SizedBox(width: 4),
              if (_items.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red),
                  onPressed: () =>
                      setState(() => _items.removeAt(i)),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Qty + Reason row
          Row(
            children: [
              // Qty
              SizedBox(
                width: 90,
                child: TextFormField(
                  initialValue: item.quantity.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(
                      () => item.quantity = int.tryParse(v) ?? 1),
                ),
              ),
              const SizedBox(width: 10),

              // Reason dropdown
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: item.reason,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _reasons
                      .map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r,
                                style: const TextStyle(fontSize: 13)),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => item.reason = v ?? 'Damaged'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }
}