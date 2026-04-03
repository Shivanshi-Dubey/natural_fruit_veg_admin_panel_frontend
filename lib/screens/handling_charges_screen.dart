import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../layouts/admin_layout.dart';
import '../models/order_model.dart';

class HandlingChargesScreen extends StatefulWidget {
  const HandlingChargesScreen({super.key});

  @override
  State<HandlingChargesScreen> createState() =>
      _HandlingChargesScreenState();
}

class _HandlingChargesScreenState
    extends State<HandlingChargesScreen> {
  static const String baseUrl =
      "https://naturalfruitveg.com/api";

  bool isLoading = true;
  bool hasError = false;
  List<Order> allOrders = [];
  String dateFilter = "today";
  DateTimeRange? customRange;

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  Future<void> loadOrders() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/orders/admin/all"),
        headers: {"Content-Type": "application/json"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data is List ? data : (data['orders'] ?? []);
        setState(() {
          allOrders = (list as List)
              .map((e) => Order.fromJson(e))
              .where((o) => o.handlingCharge > 0)
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Load orders error: $e");
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  List<Order> get filteredOrders {
    final now = DateTime.now();
    return allOrders.where((o) {
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
      } else if (dateFilter == "custom" &&
          customRange != null) {
        return o.createdAt.isAfter(customRange!.start
                .subtract(const Duration(days: 1))) &&
            o.createdAt.isBefore(
                customRange!.end.add(const Duration(days: 1)));
      }
      return true;
    }).toList();
  }

  double get totalHandlingCharge => filteredOrders.fold(
      0, (sum, o) => sum + o.handlingCharge);

  double get avgHandlingCharge => filteredOrders.isEmpty
      ? 0
      : totalHandlingCharge / filteredOrders.length;

  Future<void> _pickCustomRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: customRange ??
          DateTimeRange(
            start:
                DateTime.now().subtract(const Duration(days: 7)),
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
      title: "Handling Charges",
      showBack: true,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: loadOrders,
                  child: SingleChildScrollView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
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
                              _filterChip("This Week", "week"),
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

                        const SizedBox(height: 24),

                        /* =========================
                           📊 SUMMARY CARDS
                        ========================= */
                        Row(
                          children: [
                            Expanded(
                              child: _summaryCard(
                                label: "Total Collected",
                                value:
                                    "₹${totalHandlingCharge.toStringAsFixed(0)}",
                                icon: Icons.inventory_2_outlined,
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _summaryCard(
                                label: "Total Orders",
                                value: filtered.length
                                    .toString(),
                                icon: Icons.receipt_long,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _summaryCard(
                                label: "Avg per Order",
                                value:
                                    "₹${avgHandlingCharge.toStringAsFixed(0)}",
                                icon: Icons.analytics,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        /* =========================
                           📋 ORDER LIST
                        ========================= */
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Order Breakdown",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                            Text(
                              "${filtered.length} orders",
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        if (filtered.isEmpty)
                          _emptyState(
                              "No handling charges in this period")
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) =>
                                _buildOrderCard(filtered[i]),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          // Left — order info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  "Order #${order.id.substring(order.id.length - 6).toUpperCase()}",
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMM • hh:mm a')
                          .format(order.createdAt),
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Items count
                Text(
                  "${order.items.length} item${order.items.length > 1 ? 's' : ''} • ₹${order.itemsTotal.toStringAsFixed(0)} subtotal",
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),

          // Right — charge amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "₹${order.handlingCharge.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.purple,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Order status badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: order.orderStatus == "delivered"
                      ? Colors.green[50]
                      : Colors.orange[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.orderStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: order.orderStatus == "delivered"
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Payment method
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: order.paymentMethod == "cod"
                      ? Colors.orange[50]
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order.paymentMethod.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: order.paymentMethod == "cod"
                        ? Colors.orange
                        : Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: color),
          ),
          const SizedBox(height: 4),
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
          color:
              selected ? Colors.purple : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 56, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(color: Colors.grey)),
          ],
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
          const Text("Failed to load orders"),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: loadOrders,
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple),
          ),
        ],
      ),
    );
  }
}