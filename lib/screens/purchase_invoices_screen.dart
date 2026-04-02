import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../layouts/admin_layout.dart';

class PurchaseInvoicesScreen extends StatefulWidget {
  const PurchaseInvoicesScreen({super.key});

  @override
  State<PurchaseInvoicesScreen> createState() =>
      _PurchaseInvoicesScreenState(); // ✅ FIXED
}

// ✅ FIXED — consistent class name
class _PurchaseInvoicesEntry {
  String name;
  double buyPrice;
  double sellPrice;
  int quantity;
  String unit;
  bool isExisting;
  String? existingProductId;

  _PurchaseInvoicesEntry({
    this.name = '',
    this.buyPrice = 0,
    this.sellPrice = 0,
    this.quantity = 0,
    this.unit = 'kg',
    this.isExisting = false,
    this.existingProductId,
  });
}

class _PurchaseInvoicesScreenState
    extends State<PurchaseInvoicesScreen> {
  static const String baseUrl = "https://naturalfruitveg.com/api";

  final supplierController = TextEditingController();
  final invoiceNumberController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  bool isSaving = false;

  // ✅ FIXED — renamed to _entries so picker references work
  List<_PurchaseInvoicesEntry> _entries = [];
  List<dynamic> existingProducts = [];
  bool loadingProducts = true;

  @override
  void initState() {
    super.initState();
    _loadExistingProducts();
    _entries.add(_PurchaseInvoicesEntry()); // ✅ FIXED
  }

  @override
  void dispose() {
    supplierController.dispose();
    invoiceNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProducts() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/products"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          existingProducts =
              data is List ? data : (data['products'] ?? []);
          loadingProducts = false;
        });
      }
    } catch (e) {
      setState(() => loadingProducts = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  double get grandTotal =>
      _entries.fold(0, (sum, e) => sum + e.buyPrice * e.quantity);

  Future<void> _save() async {
    if (_entries.any((e) => e.name.isEmpty || e.quantity == 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Fill all item details"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    int updated = 0;
    int created = 0;
    List<String> errors = [];

    for (final entry in _entries) {
      try {
        if (entry.isExisting && entry.existingProductId != null) {
          // ✅ Update existing product stock
          final res = await http.put(
            Uri.parse("$baseUrl/products/${entry.existingProductId}"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "stock": entry.quantity,
              "price": entry.sellPrice,
              "buyPrice": entry.buyPrice,
            }),
          );
          if (res.statusCode == 200) {
            updated++;
          } else {
            errors.add("Failed to update ${entry.name}");
          }
        } else {
          // ✅ Create new product
          final res = await http.post(
            Uri.parse("$baseUrl/products"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "name": entry.name,
              "price": entry.sellPrice,
              "mrp": entry.sellPrice,
              "buyPrice": entry.buyPrice,
              "stock": entry.quantity,
              "unit": entry.unit,
              "category": "General",
              "imagePath": "",
              "description": "",
            }),
          );
          if (res.statusCode == 201 || res.statusCode == 200) {
            created++;
          } else {
            errors.add("Failed to create ${entry.name}");
          }
        }
      } catch (e) {
        errors.add("Error: ${entry.name}");
      }
    }

    setState(() => isSaving = false);

    if (!mounted) return;

    if (errors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "✅ $updated updated, $created created successfully"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("⚠️ Some items failed: ${errors.join(', ')}"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showProductPicker(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        String search = '';
        return StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Select Existing Product",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    hintText: "Search product...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setModalState(
                      () => search = v.toLowerCase()),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 300,
                  child: ListView(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.add,
                            color: Colors.green),
                        title: const Text("Create New Product"),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _entries[index].isExisting =
                                false; // ✅ FIXED
                            _entries[index].existingProductId =
                                null; // ✅ FIXED
                          });
                        },
                      ),
                      const Divider(),
                      ...existingProducts
                          .where((p) => (p['name'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains(search))
                          .map((p) => ListTile(
                                title: Text(
                                    p['name']?.toString() ?? ''),
                                subtitle: Text(
                                    "₹${p['price']} • Stock: ${p['stock'] ?? 0}"),
                                onTap: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _entries[index].name = p['name']
                                            ?.toString() ??
                                        ''; // ✅ FIXED
                                    _entries[index].sellPrice =
                                        (p['price'] as num?)
                                                ?.toDouble() ??
                                            0; // ✅ FIXED
                                    _entries[index].isExisting =
                                        true; // ✅ FIXED
                                    _entries[index]
                                            .existingProductId =
                                        p['_id']
                                            ?.toString(); // ✅ FIXED
                                  });
                                },
                              ))
                          .toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: "Purchase Invoice",
      showBack: true,
      child: loadingProducts
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /* =========================
                     📋 INVOICE HEADER
                  ========================= */
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text("Invoice Details",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 14),
                        TextField(
                          controller: invoiceNumberController,
                          decoration: const InputDecoration(
                            labelText: "Invoice Number",
                            prefixIcon:
                                Icon(Icons.receipt_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: supplierController,
                          decoration: const InputDecoration(
                            labelText: "Supplier Name",
                            prefixIcon:
                                Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: "Invoice Date",
                              prefixIcon:
                                  Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              DateFormat('dd MMM yyyy')
                                  .format(selectedDate),
                              style:
                                  const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  /* =========================
                     📦 ITEMS
                  ========================= */
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Items",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            TextButton.icon(
                              onPressed: () => setState(() =>
                                  _entries.add(
                                      _PurchaseInvoicesEntry())), // ✅ FIXED
                              icon: const Icon(Icons.add,
                                  color: Colors.green),
                              label: const Text("Add Item",
                                  style: TextStyle(
                                      color: Colors.green)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._entries.asMap().entries.map((e) {
                          final i = e.key;
                          final entry = e.value;
                          return _buildEntryRow(i, entry);
                        }).toList(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  /* =========================
                     💰 GRAND TOTAL
                  ========================= */
                  _sectionCard(
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Purchase Amount",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        Text(
                          "₹${grandTotal.toStringAsFixed(0)}",
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /* =========================
                     💾 SAVE BUTTON
                  ========================= */
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
                      ),
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        isSaving ? "Saving..." : "Save Invoice",
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

  Widget _buildEntryRow(int i, _PurchaseInvoicesEntry entry) {
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
          Row(
            children: [
              Expanded(
                child: entry.isExisting
                    ? InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Product",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        child: Text(entry.name,
                            style:
                                const TextStyle(fontSize: 14)),
                      )
                    : TextField(
                        decoration: const InputDecoration(
                          labelText: "Product Name",
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (v) =>
                            setState(() => entry.name = v),
                      ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => _showProductPicker(i),
                child: const Text("Pick"),
              ),
              const SizedBox(width: 4),
              if (_entries.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red),
                  onPressed: () =>
                      setState(() => _entries.removeAt(i)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: "Buy Price ₹",
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() =>
                      entry.buyPrice =
                          double.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: "Sell Price ₹",
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(
                      text: entry.sellPrice > 0
                          ? entry.sellPrice.toString()
                          : ''),
                  onChanged: (v) => setState(() =>
                      entry.sellPrice =
                          double.tryParse(v) ?? 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: "Qty",
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() =>
                      entry.quantity =
                          int.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<String>(
                value: entry.unit,
                isDense: true,
                items: ['kg', 'g', 'pcs', 'dozen', 'ltr', 'box']
                    .map((u) => DropdownMenuItem(
                        value: u, child: Text(u)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => entry.unit = v ?? 'kg'),
              ),
              Text(
                "Subtotal: ₹${(entry.buyPrice * entry.quantity).toStringAsFixed(0)}",
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green),
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
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6)
        ],
      ),
      child: child,
    );
  }
}