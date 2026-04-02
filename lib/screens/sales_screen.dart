import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../layouts/admin_layout.dart';
import '../models/order_model.dart';
import '../utils/invoice_generator.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  static const String baseUrl = "https://naturalfruitveg.com/api";

  bool isLoading = true;
  bool hasError = false;
  List<Order> orders = [];

  // Date filter
  DateTimeRange? customRange;
  String dateFilter = "today";

  @override
  void initState() {
    super.initState();
    loadSales();
  }

  Future<void> loadSales() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/orders"),
        headers: {"Content-Type": "application/json"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['orders'] ?? []);
        final parsed = (list as List)
            .map((e) => Order.fromJson(e))
            .where((o) => o.orderStatus == "delivered")
            .toList();
        setState(() {
          orders = parsed;
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Sales error: $e");
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  List<Order> get filteredOrders {
    final now = DateTime.now();
    return orders.where((o) {
      if (dateFilter == "today") {
        return o.createdAt.year == now.year &&
            o.createdAt.month == now.month &&
            o.createdAt.day == now.day;
      } else if (dateFilter == "week") {
        return o.createdAt
            .isAfter(now.subtract(const Duration(days: 7)));
      } else if (dateFilter == "month") {
        return o.createdAt.year == now.year &&
            o.createdAt.month == now.month;
      } else if (dateFilter == "custom" && customRange != null) {
        return o.createdAt.isAfter(
                customRange!.start
                    .subtract(const Duration(days: 1))) &&
            o.createdAt.isBefore(
                customRange!.end.add(const Duration(days: 1)));
      }
      return true;
    }).toList();
  }

  // ✅ Feature 23 — items total only, no delivery/handling
  double get totalSales => filteredOrders.fold(
      0, (sum, o) => sum + o.itemsTotal);

  int get totalItemsSold => filteredOrders.fold(
      0,
      (sum, o) =>
          sum + o.items.fold(0, (s, i) => s + i.quantity));

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
      setState(() {
        customRange = range;
        dateFilter = "custom";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredOrders;

    return AdminLayout(
      title: "Sales",
      showBack: true,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: loadSales,
                  child: SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        /* =========================
                           📅 DATE FILTERS
                        ========================= */
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _filterChip("Today", "today"),
                              const SizedBox(width: 8),
                              _filterChip(
                                  "This Week", "week"),
                              const SizedBox(width: 8),
                              _filterChip(
                                  "This Month", "month"),
                              const SizedBox(width: 8),
                              _filterChip("All", "all"),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: _pickCustomRange,
                                icon: const Icon(
                                    Icons.date_range,
                                    size: 16),
                                label: Text(
                                  customRange != null &&
                                          dateFilter == "custom"
                                      ? "${DateFormat('dd MMM').format(customRange!.start)} – ${DateFormat('dd MMM').format(customRange!.end)}"
                                      : "Custom",
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        /* =========================
                           📊 SUMMARY CARDS
                           Feature 23: items total only
                        ========================= */
                        Row(
                          children: [
                            Expanded(
                              child: _summaryCard(
                                "Total Sales",
                                "₹${totalSales.toStringAsFixed(0)}",
                                Icons.trending_up,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _summaryCard(
                                "Orders",
                                filtered.length.toString(),
                                Icons.receipt_long,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _summaryCard(
                                "Items Sold",
                                totalItemsSold.toString(),
                                Icons.shopping_basket,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        /* =========================
                           📋 SALE INVOICES LIST
                        ========================= */
                        const Text(
                          "Sale Invoices",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        const SizedBox(height: 12),

                        if (filtered.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: Text(
                                "No sales in this period",
                                style:
                                    TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) =>
                                _buildSaleCard(filtered[i]),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSaleCard(Order order) {
    // ✅ Feature 23 — show items total, not grand total
    final itemsTotal = order.itemsTotal;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    // ✅ Feature 24 — show invoice number
                    Text(
                      "Invoice #${order.id.substring(order.id.length - 6).toUpperCase()}",
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹${itemsTotal.toStringAsFixed(0)}",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green),
                  ),
                  Text(
                    DateFormat('dd MMM • hh:mm a')
                        .format(order.createdAt),
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Items list
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${item.name} × ${item.quantity}",
                        style: const TextStyle(fontSize: 13)),
                    Text(
                        "₹${(item.price * item.quantity).toStringAsFixed(0)}",
                        style: const TextStyle(fontSize: 13)),
                  ],
                ),
              )),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Payment badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: order.paymentMethod == "cod"
                      ? Colors.orange[50]
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.paymentMethod.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: order.paymentMethod == "cod"
                        ? Colors.orange
                        : Colors.blue,
                  ),
                ),
              ),

              // Download invoice button
              TextButton.icon(
                onPressed: () =>
                    InvoiceGenerator.downloadInvoice(
                        context, order),
                icon: const Icon(Icons.download, size: 16),
                label: const Text("Invoice"),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = dateFilter == value;
    return GestureDetector(
      onTap: () => setState(() => dateFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.green : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 13,
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
          const Icon(Icons.error_outline,
              color: Colors.red, size: 56),
          const SizedBox(height: 16),
          const Text("Failed to load sales"),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: loadSales,
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }
}