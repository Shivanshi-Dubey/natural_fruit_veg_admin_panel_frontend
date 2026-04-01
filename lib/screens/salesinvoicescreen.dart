import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../layouts/admin_layout.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

class SalesInvoiceScreen extends StatefulWidget {
  const SalesInvoiceScreen({super.key});

  @override
  State<SalesInvoiceScreen> createState() => _SalesInvoiceScreenState();
}

class _SalesInvoiceScreenState extends State<SalesInvoiceScreen> {
  String filter = "today";

  static const _green = Color(0xFF2E7D32);
  static const _lightGreen = Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    // ✅ FIX: fetch orders on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrders();
    });
  }

  List<Order> _applyFilter(List<Order> orders) {
    final now = DateTime.now();
    return orders.where((o) {
      if (filter == "today") {
        return o.createdAt.year == now.year &&
            o.createdAt.month == now.month &&
            o.createdAt.day == now.day;
      }
      if (filter == "week") {
        return o.createdAt.isAfter(now.subtract(const Duration(days: 7)));
      }
      if (filter == "month") {
        return o.createdAt.month == now.month && o.createdAt.year == now.year;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();

    // ✅ Show error if any
    if (provider.errorMessage != null) {
      return AdminLayout(
        title: "Sales",
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(provider.errorMessage!,
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: _green),
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text("Retry", style: TextStyle(color: Colors.white)),
                onPressed: () => provider.fetchOrders(),
              ),
            ],
          ),
        ),
      );
    }

    final filteredOrders = _applyFilter(provider.orders);

    // Stats
    final double totalSales = filteredOrders.fold(0, (sum, o) => sum + o.itemsTotal);
    final int totalOrders = filteredOrders.length;

    // Product-wise item count
    final Map<String, int> itemCount = {};
    for (var order in filteredOrders) {
      for (var item in order.items) {
        itemCount[item.name] = (itemCount[item.name] ?? 0) + item.quantity;
      }
    }
    final int totalItems = itemCount.values.fold(0, (a, b) => a + b);

    // Sort items by qty descending
    final sortedItems = itemCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final fmt = NumberFormat('#,##,##0.00', 'en_IN');

    return AdminLayout(
      title: "Sales",
      child: provider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _green),
            )
          : RefreshIndicator(
              color: _green,
              onRefresh: () => provider.fetchOrders(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Filter Buttons ──────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _filterBtn("Today", "today"),
                          _filterBtn("This Week", "week"),
                          _filterBtn("This Month", "month"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Stats Cards ─────────────────────────────────
                    Row(
                      children: [
                        _statCard("Total Sales", "₹${fmt.format(totalSales)}",
                            Icons.currency_rupee, _green, _lightGreen),
                        const SizedBox(width: 10),
                        _statCard("Orders", "$totalOrders",
                            Icons.receipt_long_outlined, Colors.blue.shade700,
                            Colors.blue.shade50),
                        const SizedBox(width: 10),
                        _statCard("Items Sold", "$totalItems",
                            Icons.shopping_basket_outlined,
                            Colors.orange.shade700, Colors.orange.shade50),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Product-wise Sales ──────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Product-wise Sales",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          "${sortedItems.length} products",
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    sortedItems.isEmpty
                        ? _emptyState()
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: sortedItems.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final entry = sortedItems[i];
                              final pct = totalItems > 0
                                  ? entry.value / totalItems
                                  : 0.0;
                              return _productTile(
                                  entry.key, entry.value, pct, i);
                            },
                          ),

                    const SizedBox(height: 24),

                    // ── Recent Orders ───────────────────────────────
                    const Text(
                      "Recent Orders",
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),

                    const SizedBox(height: 10),

                    filteredOrders.isEmpty
                        ? _emptyState()
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredOrders.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) =>
                                _orderTile(filteredOrders[i], fmt),
                          ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Filter Button ────────────────────────────────────────────────────────

  Widget _filterBtn(String text, String value) {
    final isActive = filter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => filter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? _green : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  // ── Stat Card ────────────────────────────────────────────────────────────

  Widget _statCard(String title, String value, IconData icon,
      Color color, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(fontSize: 10, color: color.withOpacity(0.7)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Product Tile ─────────────────────────────────────────────────────────

  Widget _productTile(String name, int qty, double pct, int index) {
    final colors = [_green, Colors.blue.shade600, Colors.orange.shade600,
      Colors.purple.shade500, Colors.teal.shade600];
    final color = colors[index % colors.length];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Qty: $qty",
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.grey.shade100,
              color: color,
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${(pct * 100).toStringAsFixed(1)}% of total items",
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ── Order Tile ───────────────────────────────────────────────────────────

  Widget _orderTile(Order order, NumberFormat fmt) {
    final statusColor = switch (order.orderStatus) {
      'delivered' => _green,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_long_outlined,
                color: _green, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.customerName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt),
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
                    fontWeight: FontWeight.w800, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
    );
  }

  // ── Empty State ──────────────────────────────────────────────────────────

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text("No data for this period",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}