import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../layouts/admin_layout.dart';
import 'purchase_invoices_screen.dart'; // ✅ to create new purchase

class PurchaseListScreen extends StatefulWidget {
  const PurchaseListScreen({super.key});

  @override
  State<PurchaseListScreen> createState() => _PurchaseListScreenState();
}

class _PurchaseListScreenState extends State<PurchaseListScreen> {
  static const String baseUrl = "https://naturalfruitveg.com/api";
  static const _green = Color(0xFF2E7D32);

  List<dynamic> allPurchases = [];
  bool isLoading = true;
  bool hasError = false;
  String dateFilter = "today";
  DateTimeRange? customRange;
  String searchQuery = '';

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
      final res = await http.get(
        Uri.parse("$baseUrl/admin/purchase-invoices"),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data is List ? data : (data['invoices'] ?? [])) as List;
        // Sort latest first
        list.sort((a, b) {
          final aDate = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(2000);
          final bDate = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
        setState(() { allPurchases = list; isLoading = false; });
      } else {
        setState(() { hasError = true; isLoading = false; });
      }
    } catch (e) {
      setState(() { hasError = true; isLoading = false; });
    }
  }

  // ── Filter by date ───────────────────────────────────────
  List<dynamic> get filteredPurchases {
    final now = DateTime.now();
    List<dynamic> list = allPurchases;

    // Date filter
    list = list.where((p) {
      final date = DateTime.tryParse(p['createdAt'] ?? '') ?? DateTime(2000);
      if (dateFilter == "today") {
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      } else if (dateFilter == "week") {
        return date.isAfter(now.subtract(const Duration(days: 7)));
      } else if (dateFilter == "month") {
        return date.year == now.year && date.month == now.month;
      } else if (dateFilter == "custom" && customRange != null) {
        return date.isAfter(
                customRange!.start.subtract(const Duration(days: 1))) &&
            date.isBefore(customRange!.end.add(const Duration(days: 1)));
      }
      return true;
    }).toList();

    // Search filter
    if (searchQuery.isNotEmpty) {
      list = list.where((p) {
        final supplier = (p['supplier'] ?? '').toString().toLowerCase();
        final invoice = (p['invoiceNumber'] ?? '').toString().toLowerCase();
        return supplier.contains(searchQuery.toLowerCase()) ||
            invoice.contains(searchQuery.toLowerCase());
      }).toList();
    }

    return list;
  }

  // ── Summary totals ───────────────────────────────────────
  double get totalAmount => filteredPurchases.fold(
      0, (sum, p) => ((p['totalAmount'] as num?) ?? 0).toDouble() + sum);

  double get totalPaid => filteredPurchases.fold(
      0, (sum, p) => ((p['paidAmount'] as num?) ?? 0).toDouble() + sum);

  double get totalDue => totalAmount - totalPaid;

  int get totalItems => filteredPurchases.fold(
      0,
      (sum, p) =>
          sum +
          ((p['products'] as List?)?.length ?? 0));

  Future<void> _pickCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: customRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
    );
    if (range != null) {
      setState(() { customRange = range; dateFilter = "custom"; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredPurchases;

    return AdminLayout(
      title: "Purchase List",
      showBack: true,
      // ✅ FAB to create new purchase
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Purchase",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PurchaseInvoicesScreen()),
        ).then((_) => _fetchPurchases()), // ✅ refresh after new purchase
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : hasError
              ? _errorView()
              : Column(
                  children: [

                    // ── Summary Bar ───────────────────────────
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          _miniStat("Total", "₹${totalAmount.toStringAsFixed(0)}", Colors.blue),
                          _divider(),
                          _miniStat("Paid", "₹${totalPaid.toStringAsFixed(0)}", _green),
                          _divider(),
                          _miniStat("Due", "₹${totalDue.toStringAsFixed(0)}",
                              totalDue > 0 ? Colors.red : _green),
                          _divider(),
                          _miniStat("Invoices", "${filtered.length}", Colors.orange),
                        ],
                      ),
                    ),

                    // ── Search ────────────────────────────────
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search supplier or invoice...",
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (v) => setState(() => searchQuery = v),
                      ),
                    ),

                    // ── Date Filters ──────────────────────────
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filterChip("Today", "today"),
                            const SizedBox(width: 8),
                            _filterChip("This Week", "week"),
                            const SizedBox(width: 8),
                            _filterChip("This Month", "month"),
                            const SizedBox(width: 8),
                            _filterChip("All", "all"),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: _pickCustomRange,
                              icon: const Icon(Icons.date_range, size: 16),
                              label: Text(
                                customRange != null && dateFilter == "custom"
                                    ? "${DateFormat('dd MMM').format(customRange!.start)} – ${DateFormat('dd MMM').format(customRange!.end)}"
                                    : "Custom",
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                side: const BorderSide(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Divider(height: 1),

                    // ── Purchase List ─────────────────────────
                    Expanded(
                      child: RefreshIndicator(
                        color: _green,
                        onRefresh: _fetchPurchases,
                        child: filtered.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.4,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.receipt_long_outlined,
                                            size: 56, color: Colors.grey.shade300),
                                        const SizedBox(height: 12),
                                        Text(
                                          dateFilter == "today"
                                              ? "No purchases today"
                                              : "No purchases in this period",
                                          style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 15),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    const PurchaseInvoicesScreen()),
                                          ).then((_) => _fetchPurchases()),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: _green),
                                          icon: const Icon(Icons.add),
                                          label: const Text("Add Purchase"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                                itemCount: filtered.length,
                                itemBuilder: (_, i) =>
                                    _buildPurchaseCard(filtered[i]),
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildPurchaseCard(dynamic p) {
    final date = DateTime.tryParse(p['createdAt'] ?? '') ?? DateTime.now();
    final products = (p['products'] as List?) ?? [];
    final totalAmt = ((p['totalAmount'] as num?) ?? 0).toDouble();
    final paidAmt = ((p['paidAmount'] as num?) ?? 0).toDouble();
    final balance = totalAmt - paidAmt;
    final isPaid = balance <= 0;
    final invoiceNumber = p['invoiceNumber']?.toString() ?? '';
    final supplierName = p['supplier']?.toString() ?? 'Unknown Supplier';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Card Header ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                // Supplier avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _green.withOpacity(0.1),
                  child: Text(
                    supplierName.length >= 2
                        ? supplierName.substring(0, 2).toUpperCase()
                        : supplierName.toUpperCase(),
                    style: const TextStyle(
                        color: _green,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(supplierName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      if (invoiceNumber.isNotEmpty)
                        Text("Invoice: $invoiceNumber",
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("₹${totalAmt.toStringAsFixed(0)}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _green)),
                    const SizedBox(height: 3),
                    // Paid/Pending badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPaid
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: isPaid
                                ? Colors.green.shade200
                                : Colors.red.shade200),
                      ),
                      child: Text(
                        isPaid ? "✅ PAID" : "⏳ PENDING",
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isPaid
                                ? Colors.green.shade700
                                : Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Date + Items ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      "${fmt.format(date)}  •  ${fmtTime.format(date)}",
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),

                if (products.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  // Products list
                  ...products.take(3).map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.fiber_manual_record,
                                    size: 6, color: Colors.grey),
                                const SizedBox(width: 6),
                                Text(
                                  "${item['name'] ?? ''} • ${item['quantity'] ?? 0} ${item['unit'] ?? 'kg'}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            Text(
                              "₹${(((item['price'] as num?) ?? 0) * ((item['quantity'] as num?) ?? 0)).toStringAsFixed(0)}",
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )),
                  // Show +N more if more than 3
                  if (products.length > 3)
                    Text(
                      "+${products.length - 3} more items",
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic),
                    ),
                ],
              ],
            ),
          ),

          // ── Footer: Paid / Balance ───────────────────
          if (!isPaid) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text("Paid: ",
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      Text("₹${paidAmt.toStringAsFixed(0)}",
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _green)),
                    ],
                  ),
                  Row(
                    children: [
                      Text("Balance: ",
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                      Text("₹${balance.toStringAsFixed(0)}",
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(height: 30, width: 1, color: Colors.grey.shade200);

  Widget _filterChip(String label, String value) {
    final selected = dateFilter == value;
    return GestureDetector(
      onTap: () => setState(() => dateFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _green : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 56),
          const SizedBox(height: 16),
          const Text("Failed to load purchases"),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchPurchases,
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            style: ElevatedButton.styleFrom(backgroundColor: _green),
          ),
        ],
      ),
    );
  }
}
