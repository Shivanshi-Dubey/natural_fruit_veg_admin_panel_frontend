import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../layouts/admin_layout.dart';
import '../providers/supplier_provider.dart';

class PurchaseInvoicesScreen extends StatefulWidget {
  const PurchaseInvoicesScreen({super.key});

  @override
  State<PurchaseInvoicesScreen> createState() =>
      _PurchaseInvoicesScreenState();
}

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

class _PurchaseInvoicesScreenState extends State<PurchaseInvoicesScreen> {
  static const String baseUrl = "https://naturalfruitveg.com/api";

  String? _selectedSupplierId;
  String? _selectedSupplierName;

  final invoiceNumberController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  bool isSaving = false;

  List<_PurchaseInvoicesEntry> _entries = [];
  List<dynamic> existingProducts = [];
  bool loadingProducts = true;

  @override
  void initState() {
    super.initState();
    _loadExistingProducts();
    _entries.add(_PurchaseInvoicesEntry());
    Future.microtask(
        () => context.read<SupplierProvider>().fetchSuppliers());
  }

  @override
  void dispose() {
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
    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a supplier"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
          final res = await http.put(
            Uri.parse("$baseUrl/products/${entry.existingProductId}"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "addstock": entry.quantity,
              "price": entry.sellPrice,
              "buyPrice": entry.buyPrice,
              "supplierId": _selectedSupplierId,
              "supplierName": _selectedSupplierName,
            }),
          );
          if (res.statusCode == 200) {
            updated++;
          } else {
            errors.add("Failed to update ${entry.name}");
          }
        } else {
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
              "supplierId": _selectedSupplierId,
              "supplierName": _selectedSupplierName,
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

    try {
      await http.post(
        Uri.parse("$baseUrl/admin/purchase-invoices"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "invoiceNumber": invoiceNumberController.text,
          "supplierId": _selectedSupplierId,
          "supplierName": _selectedSupplierName,
          "products": _entries
              .map((e) => {
                    "name": e.name,
                    "quantity": e.quantity,
                    "price": e.buyPrice,
                    "unit": e.unit,
                  })
              .toList(),
          "totalAmount": grandTotal,
          "paidAmount": 0,
        }),
      );
    } catch (_) {}

    setState(() => isSaving = false);

    if (!mounted) return;

    if (errors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "✅ Stock updated! $updated products updated, $created new products added"),
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

  void _showSupplierBottomSheet(SupplierProvider supplierProvider) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        bool showAddForm = false;
        bool isSavingSupplier = false;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Select Supplier",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    TextButton.icon(
                      onPressed: () => setModalState(
                          () => showAddForm = !showAddForm),
                      icon: Icon(
                          showAddForm ? Icons.close : Icons.add,
                          color: Colors.green,
                          size: 18),
                      label: Text(
                        showAddForm ? "Cancel" : "+ Add New",
                        style:
                            const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
                if (showAddForm) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: "Supplier Name *",
                            border: OutlineInputBorder(),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: "Phone Number",
                            border: OutlineInputBorder(),
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isSavingSupplier
                                ? null
                                : () async {
                                    if (nameCtrl.text
                                        .trim()
                                        .isEmpty) return;
                                    setModalState(() =>
                                        isSavingSupplier = true);
                                    try {
                                      final res = await http.post(
                                        Uri.parse(
                                            "$baseUrl/admin/suppliers"),
                                        headers: {
                                          "Content-Type":
                                              "application/json"
                                        },
                                        body: jsonEncode({
                                          "name":
                                              nameCtrl.text.trim(),
                                          "phone":
                                              phoneCtrl.text.trim(),
                                          "email": "",
                                          "address": "",
                                          "gstNumber": "",
                                          "isActive": true,
                                        }),
                                      );
                                      if (res.statusCode == 200 ||
                                          res.statusCode == 201) {
                                        await supplierProvider
                                            .fetchSuppliers();
                                        final newSupplier =
                                            supplierProvider.suppliers
                                                .firstWhere(
                                          (s) =>
                                              s.name ==
                                              nameCtrl.text.trim(),
                                          orElse: () =>
                                              supplierProvider
                                                  .suppliers.last,
                                        );
                                        setState(() {
                                          _selectedSupplierId =
                                              newSupplier.id;
                                          _selectedSupplierName =
                                              newSupplier.name;
                                        });
                                        Navigator.pop(ctx);
                                      }
                                    } catch (_) {}
                                    setModalState(() =>
                                        isSavingSupplier = false);
                                  },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            icon: isSavingSupplier
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2))
                                : const Icon(Icons.save_outlined),
                            label: Text(isSavingSupplier
                                ? "Saving..."
                                : "Save Supplier"),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const Text("Or select existing:",
                      style: TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  height: 250,
                  child: supplierProvider.suppliers.isEmpty
                      ? Center(
                          child: Text("No suppliers yet",
                              style: TextStyle(
                                  color: Colors.grey.shade500)))
                      : ListView(
                          children: supplierProvider.suppliers
                              .map((s) => ListTile(
                                    leading: CircleAvatar(
                                      radius: 18,
                                      backgroundColor: const Color(
                                              0xFF2E7D32)
                                          .withOpacity(0.1),
                                      child: Text(
                                        s.name.length >= 2
                                            ? s.name
                                                .substring(0, 2)
                                                .toUpperCase()
                                            : s.name.toUpperCase(),
                                        style: const TextStyle(
                                            color: Color(0xFF2E7D32),
                                            fontSize: 12,
                                            fontWeight:
                                                FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(s.name,
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.w600)),
                                    subtitle: s.phone.isNotEmpty
                                        ? Text(s.phone,
                                            style: const TextStyle(
                                                fontSize: 12))
                                        : null,
                                    trailing:
                                        _selectedSupplierId == s.id
                                            ? const Icon(
                                                Icons.check_circle,
                                                color: Colors.green)
                                            : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedSupplierId = s.id;
                                        _selectedSupplierName =
                                            s.name;
                                      });
                                      Navigator.pop(ctx);
                                    },
                                  ))
                              .toList(),
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
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text("Select Product",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Search product...",
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  onChanged: (v) =>
                      setModalState(() => search = v.toLowerCase()),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 300,
                  child: ListView(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.green, size: 20),
                        ),
                        title: const Text("Create New Product",
                            style: TextStyle(
                                fontWeight: FontWeight.w600)),
                        subtitle:
                            const Text("Add a brand new product"),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _entries[index].isExisting = false;
                            _entries[index].existingProductId =
                                null;
                            _entries[index].name = '';
                          });
                        },
                      ),
                      const Divider(),
                      ...existingProducts
                          .where((p) => (p['name'] ?? '')
                              .toString()
                              .toLowerCase()
                              .contains(search))
                          .map(
                            (p) => ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                    Icons.inventory_2_outlined,
                                    color: Colors.blue,
                                    size: 20),
                              ),
                              title:
                                  Text(p['name']?.toString() ?? ''),
                              subtitle: Text(
                                  "Buy: ₹${p['buyPrice'] ?? 0}  •  Sell: ₹${p['price'] ?? 0}"),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (p['stock'] ?? 0) > 0
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "Stock: ${p['stock'] ?? 0}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: (p['stock'] ?? 0) > 0
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                  ),
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                setState(() {
                                  _entries[index].name =
                                      p['name']?.toString() ?? '';
                                  _entries[index].sellPrice =
                                      (p['price'] as num?)
                                              ?.toDouble() ??
                                          0;
                                  _entries[index].buyPrice =
                                      (p['buyPrice'] as num?)
                                              ?.toDouble() ??
                                          0;
                                  _entries[index].unit =
                                      p['unit']?.toString() ?? 'kg';
                                  _entries[index].isExisting = true;
                                  _entries[index].existingProductId =
                                      p['_id']?.toString();
                                });
                              },
                            ),
                          )
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

                  // ── Invoice Header ──────────────────────────────
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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

                        // Supplier picker
                        Consumer<SupplierProvider>(
                          builder: (context, supplierProvider, _) {
                            if (supplierProvider.isLoading) {
                              return const InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Supplier',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(
                                      Icons.person_outline),
                                ),
                                child: SizedBox(
                                  height: 20,
                                  child: Center(
                                      child:
                                          CircularProgressIndicator(
                                              strokeWidth: 2)),
                                ),
                              );
                            }
                            return GestureDetector(
                              onTap: () => _showSupplierBottomSheet(
                                  supplierProvider),
                              child: AbsorbPointer(
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Supplier Name',
                                    prefixIcon: Icon(
                                        Icons.person_outline),
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(
                                        Icons.arrow_drop_down),
                                  ),
                                  child: Text(
                                    _selectedSupplierName ??
                                        'Select Supplier',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: _selectedSupplierName !=
                                              null
                                          ? Colors.black87
                                          : Colors.grey.shade500,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        // Date Picker
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

                  // ── Items ───────────────────────────────────────
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                      _PurchaseInvoicesEntry())),
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

                  // ── Grand Total ─────────────────────────────────
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

                  if (_selectedSupplierName != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.store_outlined,
                              color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Supplier: $_selectedSupplierName',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Save Button ─────────────────────────────────
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
                        isSaving
                            ? "Saving..."
                            : "Save Invoice & Update Stock",
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
                    ? GestureDetector(
                        onTap: () => _showProductPicker(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius:
                                BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 16,
                                  color: Colors.green),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.name,
                                  style: const TextStyle(
                                      fontWeight:
                                          FontWeight.w600,
                                      fontSize: 14),
                                ),
                              ),
                              const Icon(Icons.edit_outlined,
                                  size: 14,
                                  color: Colors.green),
                            ],
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: () => _showProductPicker(i),
                        child: AbsorbPointer(
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: "Tap to select product",
                              border: const OutlineInputBorder(),
                              isDense: true,
                              suffixIcon: const Icon(
                                  Icons.arrow_drop_down),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            controller: TextEditingController(
                                text: entry.name),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
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
                  controller: TextEditingController(
                      text: entry.buyPrice > 0
                          ? entry.buyPrice.toString()
                          : ''),
                  onChanged: (v) => setState(
                      () => entry.buyPrice =
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
                  onChanged: (v) => setState(
                      () => entry.sellPrice =
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
                  controller: TextEditingController(
                      text: entry.quantity > 0
                          ? entry.quantity.toString()
                          : ''),
                  onChanged: (v) => setState(
                      () => entry.quantity =
                          int.tryParse(v) ?? 0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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