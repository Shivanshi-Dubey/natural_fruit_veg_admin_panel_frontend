import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../layouts/admin_layout.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';
import '../utils/invoice_generator.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() =>
      _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  static const String baseUrl = "https://naturalfruitveg.com/api";

  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final itemNameController = TextEditingController();
  final priceController = TextEditingController();
  final qtyController = TextEditingController();

  List<OrderItem> items = [];
  DateTime selectedDate = DateTime.now();
  String paymentMethod = "cash";
  bool isSaving = false;

  List<dynamic> products = [];
  bool loadingProducts = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    itemNameController.dispose();
    priceController.dispose();
    qtyController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/products"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          products = data is List ? data : (data['products'] ?? []);
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

  double get total =>
      items.fold(0, (sum, i) => sum + i.price * i.quantity);

  String _generateInvoiceNumber() {
    final now = DateTime.now();
    final datePart = DateFormat('yyyyMMdd').format(now);
    final seq = now.millisecond.toString().padLeft(3, '0');
    return "INV-$datePart-$seq";
  }

  void _addItem() {
    if (itemNameController.text.isEmpty ||
        priceController.text.isEmpty ||
        qtyController.text.isEmpty) return;

    setState(() {
      items.add(OrderItem(
        name: itemNameController.text.trim(),
        price: double.tryParse(priceController.text) ?? 0,
        quantity: int.tryParse(qtyController.text) ?? 1,
      ));
    });

    itemNameController.clear();
    priceController.clear();
    qtyController.clear();
  }

  void _pickFromProducts() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                const Text("Pick Product",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                TextField(
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: "Search...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) =>
                      setModalState(() => search = v.toLowerCase()),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 300,
                  child: ListView(
                    children: products
                        .where((p) => (p['name'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(search))
                        .map((p) => ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                    Icons.inventory_2_outlined,
                                    color: Colors.green,
                                    size: 18),
                              ),
                              title:
                                  Text(p['name']?.toString() ?? ''),
                              subtitle: Text(
                                  "₹${p['price']} • Stock: ${p['stock'] ?? 0}"),
                              trailing: (p['stock'] ?? 0) <= 0
                                  ? Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: const Text("Out of Stock",
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.red)),
                                    )
                                  : null,
                              onTap: () {
                                Navigator.pop(context);
                                setState(() {
                                  itemNameController.text =
                                      p['name']?.toString() ?? '';
                                  priceController.text =
                                      p['price']?.toString() ?? '';
                                  qtyController.text = '1';
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
        );
      },
    );
  }

  Future<void> _saveOrder() async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Add at least one item"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    final invoiceNumber = _generateInvoiceNumber();

    final orderData = {
      "customerName": nameController.text.trim().isEmpty
          ? "Walk-in Customer"
          : nameController.text.trim(),
      "phone": phoneController.text.trim(),
      "products": items
          .map((i) => {
                "name": i.name,
                "price": i.price,
                "quantity": i.quantity,
              })
          .toList(),
      "paymentMethod": paymentMethod,
      "paymentStatus": "paid",
      "deliveryCharge": 0,
      "handlingCharge": 0,
      "createdAt": selectedDate.toIso8601String(),
      "invoiceNumber": invoiceNumber,
    };

    try {
      // ✅ Save order and get back the created order object
      final createdOrder =
          await context.read<OrderProvider>().createOrder(orderData);

      setState(() => isSaving = false);

      if (!mounted) return;

      // ✅ Show invoice screen immediately after saving
      if (createdOrder != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => InvoicePreviewScreen(order: createdOrder),
          ),
        );
      } else {
        // Fallback — go back if order object not returned
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ Order saved — Invoice: $invoiceNumber"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Failed to create order"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: "Create Sale",
      showBack: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Invoice Number Banner ───────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long,
                      color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Invoice No: ${_generateInvoiceNumber()}",
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Date ────────────────────────────────────────
            _card(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd MMM yyyy').format(selectedDate),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text("Change Date"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Customer ─────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Customer",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Customer Name",
                      hintText: "Walk-in Customer",
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Phone (optional)",
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Payment Method ───────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Payment Method",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Row(
                    children: ["cash", "upi", "cod"]
                        .map((method) => Padding(
                              padding:
                                  const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(method.toUpperCase()),
                                selected: paymentMethod == method,
                                selectedColor: Colors.green[100],
                                onSelected: (_) => setState(
                                    () => paymentMethod = method),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Add Items ────────────────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Items",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      TextButton.icon(
                        onPressed:
                            loadingProducts ? null : _pickFromProducts,
                        icon: const Icon(Icons.inventory_2_outlined,
                            color: Colors.green),
                        label: const Text("From Products",
                            style: TextStyle(color: Colors.green)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: itemNameController,
                          decoration: const InputDecoration(
                            labelText: "Item",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Price ₹",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Qty",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: Colors.green, size: 28),
                        onPressed: _addItem,
                      ),
                    ],
                  ),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    ...items.asMap().entries.map((e) {
                      final i = e.key;
                      final item = e.value;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(item.name),
                        subtitle: Text(
                            "Qty: ${item.quantity} × ₹${item.price.toStringAsFixed(0)}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "₹${(item.price * item.quantity).toStringAsFixed(0)}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red, size: 18),
                              onPressed: () =>
                                  setState(() => items.removeAt(i)),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Total ────────────────────────────────────────
            _card(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Amount",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    "₹${total.toStringAsFixed(0)}",
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Save Button ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : _saveOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  isSaving ? "Saving..." : "Save & Generate Invoice",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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

// ============================================================
// ✅ INVOICE PREVIEW SCREEN
// Opens automatically after saving a sale
// User can Download, Share, or go to Sale List
// ============================================================
class InvoicePreviewScreen extends StatelessWidget {
  final Order order;
  const InvoicePreviewScreen({super.key, required this.order});

  static const _green = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final invoiceId =
        order.id.substring(order.id.length >= 6 ? order.id.length - 6 : 0)
            .toUpperCase();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        title: const Text("Invoice Generated",
            style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () =>
                Navigator.pushNamedAndRemoveUntil(
                    context, '/sale-list', (r) => r.isFirst),
            icon: const Icon(Icons.list_alt, color: Colors.white, size: 18),
            label: const Text("Sale List",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Success Banner ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: _green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  const Text("Sale Saved Successfully!",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _green)),
                  const SizedBox(height: 4),
                  Text(
                    "Invoice #$invoiceId",
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Invoice Summary Card ────────────────────────
            Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.customerName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const SizedBox(height: 2),
                          Text("Invoice #$invoiceId",
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12)),
                        ],
                      ),
                      Text(
                        "₹${order.itemsTotal.toStringAsFixed(0)}",
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _green),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy • hh:mm a')
                        .format(order.createdAt),
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),

                  const Divider(height: 20),

                  // Items
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${item.name} × ${item.quantity}",
                                style: const TextStyle(fontSize: 13)),
                            Text(
                                "₹${(item.price * item.quantity).toStringAsFixed(0)}",
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )),

                  const Divider(height: 16),

                  // Payment
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Payment",
                          style: TextStyle(color: Colors.grey)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          order.paymentMethod.toUpperCase(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _green,
                              fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Action Buttons ──────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () =>
                    InvoiceGenerator.downloadInvoice(context, order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.download_outlined),
                label: const Text(
                  "Download / Share Invoice",
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/dashboard', (r) => false),
                    icon: const Icon(Icons.home_outlined),
                    label: const Text("Home"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context, '/sale-list', (r) => r.isFirst),
                    icon: const Icon(Icons.receipt_long_outlined,
                        color: _green),
                    label: const Text("View All Sales",
                        style: TextStyle(color: _green)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: _green),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
