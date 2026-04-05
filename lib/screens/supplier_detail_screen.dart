import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../layouts/admin_layout.dart';
import '../models/supplier_model.dart';
import 'add_supplier_screen.dart';

class SupplierDetailScreen extends StatefulWidget {
  final Supplier supplier;

  const SupplierDetailScreen({super.key, required this.supplier});

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  static const String baseUrl = "https://naturalfruitveg.com/api";
  static const _green = Color(0xFF2E7D32);

  List<dynamic> purchases = [];
  bool isLoading = true;
  bool hasError = false;

  final fmt = DateFormat('dd MMM yyyy');
  final fmtTime = DateFormat('hh:mm a');

  @override
  void initState() {
    super.initState();
    _fetchPurchases();
  }

  Future<void> _fetchPurchases() async {
    setState(() { isLoading = true; hasError = false; });
    try {
      // ✅ FIXED: correct endpoint is /purchaseInvoices?supplierId=
      final res = await http.get(
        Uri.parse("$baseUrl/purchaseInvoices?supplierId=${widget.supplier.id}"),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data is List ? data : (data['invoices'] ?? [])) as List;
        // ✅ normalize fields: backend uses 'createdAt' not 'date'
        list.sort((a, b) {
          final aDate = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(2000);
          final bDate = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
        setState(() { purchases = list; isLoading = false; });
      } else {
        setState(() { hasError = true; isLoading = false; });
      }
    } catch (e) {
      setState(() { hasError = true; isLoading = false; });
    }
  }

  // ── Computed totals ──────────────────────────────────────
  double get totalPurchased => purchases.fold(
      0, (sum, p) => sum + ((p['totalAmount'] as num?) ?? 0).toDouble());

  double get totalPaid => purchases.fold(
      0, (sum, p) => sum + ((p['paidAmount'] as num?) ?? 0).toDouble());

  double get balanceDue => totalPurchased - totalPaid;

  @override
  Widget build(BuildContext context) {
    final s = widget.supplier;
    final initials = s.name.length >= 2
        ? s.name.substring(0, 2).toUpperCase()
        : s.name.toUpperCase();

    return AdminLayout(
      title: s.name,
      showBack: true,
      child: RefreshIndicator(
        onRefresh: _fetchPurchases,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Supplier Info Card ──────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _box(),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _green.withOpacity(0.1),
                      child: Text(initials,
                          style: const TextStyle(
                              color: _green,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const SizedBox(height: 4),
                          if (s.phone.isNotEmpty)
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
                            Text("GST: ${s.gstNumber}",
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        _statusChip(s.isActive),
                        const SizedBox(height: 8),
                        // Edit button
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddSupplierScreen(supplier: s),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border.all(color: _green),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text("Edit",
                                style: TextStyle(
                                    color: _green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Balance Summary Cards ───────────────────
              isLoading
                  ? const SizedBox()
                  : Row(
                      children: [
                        _amountCard("Total Purchased",
                            totalPurchased, Colors.blue),
                        const SizedBox(width: 10),
                        _amountCard(
                            "Total Paid", totalPaid, _green),
                        const SizedBox(width: 10),
                        _amountCard("Balance Due", balanceDue,
                            balanceDue > 0 ? Colors.red : _green),
                      ],
                    ),

              const SizedBox(height: 20),

              // ── Purchase History Header ─────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Purchase History (${purchases.length})",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  if (balanceDue > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        "Due: ₹${balanceDue.toStringAsFixed(0)}",
                        style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // ── Purchase List ───────────────────────────
              isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                            color: _green),
                      ),
                    )
                  : hasError
                      ? Center(
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 48),
                              const SizedBox(height: 8),
                              const Text("Failed to load purchases"),
                              TextButton.icon(
                                onPressed: _fetchPurchases,
                                icon: const Icon(Icons.refresh),
                                label: const Text("Retry"),
                              ),
                            ],
                          ),
                        )
                      : purchases.isEmpty
                          ? Container(
                              padding: const EdgeInsets.all(40),
                              decoration: _box(),
                              child: Column(
                                children: [
                                  Icon(Icons.receipt_long_outlined,
                                      size: 48,
                                      color: Colors.grey.shade300),
                                  const SizedBox(height: 12),
                                  Text(
                                    "No purchases from ${s.name} yet",
                                    style: TextStyle(
                                        color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount: purchases.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) =>
                                  _buildPurchaseCard(purchases[i]),
                            ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseCard(dynamic p) {
    // ✅ backend uses 'createdAt' and 'products' (not 'date'/'items')
    final date = DateTime.tryParse(p['createdAt'] ?? '') ?? DateTime.now();
    final items = (p['products'] as List?) ?? [];
    final totalAmount =
        ((p['totalAmount'] as num?) ?? 0).toDouble();
    final paidAmount =
        ((p['paidAmount'] as num?) ?? 0).toDouble();
    final balance = totalAmount - paidAmount;
    final isPaid = balance <= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Row 1: Date + Total ───────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 13, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    fmt.format(date),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ],
              ),
              Text(
                "₹${totalAmount.toStringAsFixed(0)}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _green),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // ── Invoice number ────────────────────────────
          if ((p['invoiceNumber'] ?? '').toString().isNotEmpty)
            Text(
              "Invoice: ${p['invoiceNumber']}",
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade500),
            ),

          const SizedBox(height: 8),

          // ── Items list ────────────────────────────────
          if (items.isNotEmpty) ...[
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                              Icons.fiber_manual_record,
                              size: 6,
                              color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            "${item['name'] ?? ''} • ${item['quantity'] ?? 0} ${item['unit'] ?? 'kg'}",
                            style: const TextStyle(
                                fontSize: 12),
                          ),
                        ],
                      ),
                      Text(
                        "₹${((item['buyPrice'] as num? ?? 0) * (item['quantity'] as num? ?? 0)).toStringAsFixed(0)}",
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )),
            const Divider(height: 16),
          ],

          // ── Payment Summary ───────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _amountRow("Paid", paidAmount, _green),
                  const SizedBox(height: 4),
                  _amountRow(
                      "Balance",
                      balance,
                      balance > 0
                          ? Colors.red.shade600
                          : _green),
                ],
              ),
              // Payment status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isPaid
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isPaid
                          ? Colors.green.shade200
                          : Colors.red.shade200),
                ),
                child: Text(
                  isPaid ? "✅ PAID" : "⏳ PENDING",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPaid
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _amountCard(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              "₹${amount.toStringAsFixed(0)}",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: color.withOpacity(0.8)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _amountRow(String label, double amount, Color color) {
    return Row(
      children: [
        Text("$label: ",
            style: const TextStyle(
                fontSize: 12, color: Colors.grey)),
        Text(
          "₹${amount.toStringAsFixed(0)}",
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color),
        ),
      ],
    );
  }

  Widget _statusChip(bool isActive) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withOpacity(0.12)
            : Colors.red.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isActive ? 'ACTIVE' : 'INACTIVE',
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.green : Colors.red),
      ),
    );
  }

  static BoxDecoration _box() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03), blurRadius: 4)
        ],
      );
}