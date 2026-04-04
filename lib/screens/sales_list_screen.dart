import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../layouts/admin_layout.dart';
import '../providers/order_provider.dart';
import '../models/order_model.dart';
import '../utils/invoice_generator.dart';
import '../screens/create_order_screen.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  String dateFilter = "today";
  DateTimeRange? customRange;

  static const _green = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrders();
    });
  }

  List<Order> _applyFilter(List<Order> orders) {
    final now = DateTime.now();
    return orders.where((o) {
      if (dateFilter == "today") {
        return o.createdAt.year == now.year &&
            o.createdAt.month == now.month &&
            o.createdAt.day == now.day;
      }
      if (dateFilter == "week") {
        return o.createdAt
            .isAfter(now.subtract(const Duration(days: 7)));
      }
      if (dateFilter == "month") {
        return o.createdAt.month == now.month &&
            o.createdAt.year == now.year;
      }
      if (dateFilter == "custom" && customRange != null) {
        return o.createdAt.isAfter(customRange!.start
                .subtract(const Duration(days: 1))) &&
            o.createdAt.isBefore(
                customRange!.end.add(const Duration(days: 1)));
      }
      return true;
    }).toList();
  }

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
    final provider = context.watch<OrderProvider>();

    // ✅ Error state
    if (provider.errorMessage != null && !provider.isLoading) {
      return AdminLayout(
        title: "Sale List",
        showBack: true,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_outlined,
                  size: 56, color: Colors.grey),
              const SizedBox(height: 12),
              Text(provider.errorMessage!,
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _green),
                icon: const Icon(Icons.refresh,
                    color: Colors.white),
                label: const Text("Retry",
                    style: TextStyle(color: Colors.white)),
                onPressed: () => provider.fetchOrders(),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _applyFilter(provider.orders);
    final double totalSales =
        filtered.fold(0, (sum, o) => sum + o.itemsTotal);
    final int totalItems = filtered.fold(
        0,
        (sum, o) =>
            sum + o.items.fold(0, (s, i) => s + i.quantity));
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');

    return AdminLayout(
      title: "Sale List",
      showBack: true,
      child: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _green))
          : Column(
              children: [
                /* =========================
                   📊 SUMMARY BAR
                ========================= */
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      _miniStat("Total Sales",
                          "₹${fmt.format(totalSales)}", _green),
                      _divider(),
                      _miniStat("Orders", "${filtered.length}",
                          Colors.blue.shade700),
                      _divider(),
                      _miniStat("Items", "$totalItems",
                          Colors.orange.shade700),
                    ],
                  ),
                ),

                /* =========================
                   📅 DATE FILTER
                ========================= */
                Container(
                  color: Colors.white,
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
                          icon: const Icon(Icons.date_range,
                              size: 16),
                          label: Text(
                            customRange != null &&
                                    dateFilter == "custom"
                                ? "${DateFormat('dd MMM').format(customRange!.start)} – ${DateFormat('dd MMM').format(customRange!.end)}"
                                : "Custom",
                            style:
                                const TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            side: const BorderSide(
                                color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1),

                /* =========================
                   📋 SALE LIST
                ========================= */
                Expanded(
                  child: RefreshIndicator(
                    color: _green,
                    onRefresh: () => provider.fetchOrders(),
                    child: filtered.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height: MediaQuery.of(context)
                                        .size
                                        .height *
                                    0.4,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                        Icons
                                            .receipt_long_outlined,
                                        size: 56,
                                        color: Colors
                                            .grey.shade300),
                                    const SizedBox(height: 12),
                                    Text(
                                      "No sales in this period",
                                      style: TextStyle(
                                          color: Colors
                                              .grey.shade500,
                                          fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                                12, 12, 12, 80),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) =>
                                _buildSaleCard(
                                    filtered[i], fmt),
                          ),
                  ),
                ),

                /* =========================
                   ✅ CREATE SALE BUTTON
                   (replaces floatingActionButton)
                ========================= */
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(
                      16, 10, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const CreateOrderScreen(),
                          ),
                        ).then((_) {
                          // ✅ Refresh list after creating sale
                          provider.fetchOrders();
                        });
                      },
                      icon: const Icon(Icons.add,
                          color: Colors.white),
                      label: const Text(
                        "Create New Sale",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /* =========================
     🧩 SALE CARD
  ========================= */
  Widget _buildSaleCard(Order order, NumberFormat fmt) {
    final statusColor = switch (order.orderStatus) {
      'delivered' => const Color(0xFF2E7D32),
      'placed' => Colors.orange.shade700,
      'cancelled' => Colors.red.shade700,
      _ => Colors.blue.shade700,
    };
    final statusBg = switch (order.orderStatus) {
      'delivered' => const Color(0xFFE8F5E9),
      'placed' => const Color(0xFFFFF3E0),
      'cancelled' => const Color(0xFFFFEBEE),
      _ => const Color(0xFFE3F2FD),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          /* ── Header ── */
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                      Icons.receipt_long_outlined,
                      color: Color(0xFF2E7D32),
                      size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Invoice #${order.id.substring(order.id.length >= 6 ? order.id.length - 6 : 0).toUpperCase()}",
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹${fmt.format(order.itemsTotal)}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Color(0xFF2E7D32)),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.orderStatus.toUpperCase(),
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: statusColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          /* ── Items ── */
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
            child: Column(
              children: order.items
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${item.name} × ${item.quantity}",
                              style:
                                  const TextStyle(fontSize: 12),
                            ),
                            Text(
                              "₹${(item.price * item.quantity).toStringAsFixed(0)}",
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),

          const Divider(height: 1),

          /* ── Footer ── */
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy • hh:mm a')
                          .format(order.createdAt),
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: order.paymentMethod == "cod"
                            ? Colors.orange.shade50
                            : Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        order.paymentMethod.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: order.paymentMethod == "cod"
                              ? Colors.orange.shade700
                              : Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),

                // ✅ Download invoice
                TextButton.icon(
                  onPressed: () =>
                      InvoiceGenerator.downloadInvoice(
                          context, order),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text("Invoice"),
                  style: TextButton.styleFrom(
                      foregroundColor:
                          const Color(0xFF2E7D32)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* =========================
     🧩 UI HELPERS
  ========================= */
  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 10, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
        height: 30, width: 1, color: Colors.grey.shade200);
  }

  Widget _filterChip(String label, String value) {
    final selected = dateFilter == value;
    return GestureDetector(
      onTap: () => setState(() => dateFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF2E7D32)
              : Colors.grey[100],
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
}
