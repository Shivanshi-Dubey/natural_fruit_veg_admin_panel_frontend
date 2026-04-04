import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  // ── Filter ──────────────────────────────────────────
  String _filter = 'today'; // today | week | month

  // ── State ───────────────────────────────────────────
  bool isLoading = true;
  bool _hasError = false;

  // ── Raw API values ───────────────────────────────────
  double handling = 0;
  double delivery = 0;
  double totalRevenue = 0;
  double totalBuyCost = 0; // cost of goods sold
  int orders = 0;

  // ── Computed ─────────────────────────────────────────
  double get grossProfit => totalRevenue - totalBuyCost;
  double get totalExpenses => handling + delivery;
  double get netProfit => grossProfit - totalExpenses;
  double get profitMargin =>
      totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0;
  bool get isLoss => netProfit < 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

Future<void> _fetchData() async {
  setState(() {
    isLoading = true;
    _hasError = false;
  });

  try {
    // ✅ Use existing orders API — no backend changes needed
    final res = await http.get(
      Uri.parse("https://naturalfruitveg.com/api/orders/admin/all"),
    );

    if (res.statusCode == 200) {
      final List allOrders = jsonDecode(res.body);

      final now = DateTime.now();

      // ✅ Filter orders by selected period
      final filtered = allOrders.where((o) {
        final createdAt = DateTime.tryParse(o['createdAt'] ?? '') ?? DateTime.now();
        if (_filter == 'today') {
          return createdAt.year == now.year &&
              createdAt.month == now.month &&
              createdAt.day == now.day;
        } else if (_filter == 'week') {
          return createdAt.isAfter(now.subtract(const Duration(days: 7)));
        } else {
          return createdAt.month == now.month &&
              createdAt.year == now.year;
        }
      }).toList();

      // ✅ Calculate all metrics from order data
      double revenue = 0;
      double buyCost = 0;
      double handlingTotal = 0;
      double deliveryTotal = 0;
      int orderCount = filtered.length;

      for (final o in filtered) {
        // Skip cancelled orders
        if ((o['orderStatus'] ?? '') == 'cancelled') continue;

        revenue += (o['grandTotal'] ?? 0).toDouble();
        handlingTotal += (o['handlingCharge'] ?? 0).toDouble();
        deliveryTotal += (o['deliveryCharge'] ?? 0).toDouble();

        // ✅ Calculate buy cost from products
        final products = o['products'] as List? ?? [];
        for (final item in products) {
          final product = item['product'] ?? {};
          final buyPrice = (product['buyPrice'] ?? 0).toDouble();
          final qty = (item['quantity'] ?? 0) as int;
          buyCost += buyPrice * qty;
        }
      }

      setState(() {
        totalRevenue = revenue;
        totalBuyCost = buyCost;
        handling = handlingTotal;
        delivery = deliveryTotal;
        orders = orderCount;
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
        _hasError = true;
      });
    }
  } catch (e) {
    setState(() {
      isLoading = false;
      _hasError = true;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          "Expenses & P&L",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : _hasError
              ? _buildError()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Filter Toggle ──────────────────────────
                      _buildFilterToggle(),

                      const SizedBox(height: 20),

                      // ── Revenue Card (big) ─────────────────────
                      _buildRevenueCard(),

                      const SizedBox(height: 14),

                      // ── Gross / Net Profit ─────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              label: 'Gross Profit',
                              value: grossProfit,
                              icon: Icons.trending_up,
                              color: grossProfit >= 0
                                  ? const Color(0xFF2E7D32)
                                  : Colors.red.shade700,
                              subtitle: 'Revenue − Buy Cost',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              label: 'Net Profit',
                              value: netProfit,
                              icon: netProfit >= 0
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color: netProfit >= 0
                                  ? const Color(0xFF2E7D32)
                                  : Colors.red.shade700,
                              subtitle: 'After all expenses',
                              isHighlight: true,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ── Loss Warning Banner ────────────────────
                      if (isLoss) _buildLossBanner(),

                      if (isLoss) const SizedBox(height: 14),

                      // ── Profit Margin ──────────────────────────
                      _buildMarginCard(),

                      const SizedBox(height: 14),

                      // ── Expense Breakdown ──────────────────────
                      _buildExpenseBreakdown(),

                      const SizedBox(height: 14),

                      // ── P&L Summary Table ──────────────────────
                      _buildPLTable(),

                      const SizedBox(height: 14),

                      // ── Orders Card ────────────────────────────
                      _buildOrdersCard(),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  // ── Filter Toggle ──────────────────────────────────────────────────────────

  Widget _buildFilterToggle() {
    final filters = [
      ('today', 'Today'),
      ('week', 'This Week'),
      ('month', 'This Month'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: filters.map((f) {
          final isActive = _filter == f.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _filter = f.$1);
                _fetchData();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF2E7D32) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  f.$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Revenue Card ───────────────────────────────────────────────────────────

  Widget _buildRevenueCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Revenue',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _filterLabel,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${totalRevenue.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$orders orders • Buy cost ₹${totalBuyCost.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Metric Card ────────────────────────────────────────────────────────────

  Widget _buildMetricCard({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
    required String subtitle,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlight ? color.withOpacity(0.07) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlight ? color.withOpacity(0.3) : const Color(0xFFE5E7EB),
          width: isHighlight ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${value < 0 ? '-' : ''}₹${value.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style:
                  TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  // ── Loss Banner ────────────────────────────────────────────────────────────

  Widget _buildLossBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.warning_amber_rounded,
                color: Colors.red.shade700, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ You are in loss for $_filterLabel',
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Net loss: ₹${netProfit.abs().toStringAsFixed(0)} — Review your expenses',
                  style: TextStyle(
                      color: Colors.red.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Profit Margin Card ─────────────────────────────────────────────────────

  Widget _buildMarginCard() {
    final margin = profitMargin.clamp(-100.0, 100.0);
    final isPositive = margin >= 0;
    final color = isPositive ? const Color(0xFF2E7D32) : Colors.red.shade700;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Profit Margin',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${margin.toStringAsFixed(1)}%',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (margin.abs() / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade100,
              color: color,
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPositive
                ? 'Good! You keep ${margin.toStringAsFixed(1)}% of revenue as profit'
                : 'Expenses exceed revenue by ${margin.abs().toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ── Expense Breakdown ──────────────────────────────────────────────────────

  Widget _buildExpenseBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Expense Breakdown',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              Text(
                'Total: ₹${totalExpenses.toStringAsFixed(0)}',
                style: TextStyle(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _expenseRow(
            icon: Icons.inventory_2_outlined,
            label: 'Handling Charges',
            amount: handling,
            color: Colors.blue.shade600,
            total: totalExpenses,
          ),
          const SizedBox(height: 10),
          _expenseRow(
            icon: Icons.delivery_dining,
            label: 'Delivery Charges',
            amount: delivery,
            color: Colors.orange.shade600,
            total: totalExpenses,
          ),
        ],
      ),
    );
  }

  Widget _expenseRow({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
    required double total,
  }) {
    final pct = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 38),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.grey.shade100,
              color: color,
              minHeight: 5,
            ),
          ),
        ),
      ],
    );
  }

  // ── P&L Summary Table ──────────────────────────────────────────────────────

  Widget _buildPLTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('P&L Summary',
              style:
                  TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 14),
          _plRow('Revenue', totalRevenue, Colors.black87, isBold: true),
          _plDivider(),
          _plRow('(−) Buy Cost', totalBuyCost, Colors.red.shade600),
          _plDivider(),
          _plRow('Gross Profit', grossProfit,
              grossProfit >= 0 ? const Color(0xFF2E7D32) : Colors.red.shade700,
              isBold: true),
          _plDivider(),
          _plRow('(−) Handling', handling, Colors.blue.shade600),
          _plRow('(−) Delivery', delivery, Colors.orange.shade600),
          _plDivider(),
          _plRow(
            'Net Profit',
            netProfit,
            netProfit >= 0 ? const Color(0xFF2E7D32) : Colors.red.shade700,
            isBold: true,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _plRow(String label, double value, Color color,
      {bool isBold = false, bool isLast = false}) {
    final isNegative = value < 0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isLast ? 10 : 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isLast ? 14 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: isLast ? color : Colors.black87,
            ),
          ),
          Text(
            '${isNegative ? '-' : ''}₹${value.abs().toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: isLast ? 15 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _plDivider() =>
      Divider(height: 1, color: Colors.grey.shade100);

  // ── Orders Card ────────────────────────────────────────────────────────────

  Widget _buildOrdersCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shopping_bag_outlined,
                color: Color(0xFF2E7D32), size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Orders $_filterLabel',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
              Text(
                '$orders orders',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ],
          ),
          const Spacer(),
          if (orders > 0)
            Text(
              'Avg ₹${(totalRevenue / orders).toStringAsFixed(0)}/order',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }

  // ── Error State ────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_outlined, size: 52, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          const Text('Could not load data',
              style: TextStyle(color: Colors.grey, fontSize: 15)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32)),
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text('Retry',
                style: TextStyle(color: Colors.white)),
            onPressed: _fetchData,
          ),
        ],
      ),
    );
  }

  String get _filterLabel => switch (_filter) {
        'week' => 'This Week',
        'month' => 'This Month',
        _ => 'Today',
      };
}