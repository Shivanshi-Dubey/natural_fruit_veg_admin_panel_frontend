import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../layouts/admin_layout.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

class CashCollectionScreen extends StatefulWidget {
  const CashCollectionScreen({super.key});

  @override
  State<CashCollectionScreen> createState() => _CashCollectionScreenState();
}

class _CashCollectionScreenState extends State<CashCollectionScreen> {
  String _filter = 'pending'; // pending | deposited | all

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrders();
    });
  }

  /// Group COD orders by delivery boy
  Map<String, _DeliveryBoyGroup> _groupByDeliveryBoy(List<Order> orders) {
    final Map<String, _DeliveryBoyGroup> groups = {};

    for (final order in orders) {
      if (order.paymentMethod != 'cod') continue;
      if (order.orderStatus != 'delivered') continue;

      // Apply filter
      if (_filter == 'pending' && order.cashDepositedToAdmin) continue;
      if (_filter == 'deposited' && !order.cashDepositedToAdmin) continue;

      final boyId = order.deliveryBoyId ?? 'unassigned';
      final boyName = order.deliveryBoyName ?? 'Unassigned';

      if (!groups.containsKey(boyId)) {
        groups[boyId] = _DeliveryBoyGroup(id: boyId, name: boyName);
      }
      groups[boyId]!.orders.add(order);
    }

    return groups;
  }

  Future<void> _markDeposited(String orderId) async {
    await http.put(
      Uri.parse(
          "https://naturalfruitveg.com/api/orders/delivery/collect-cash/$orderId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"cashDepositedToAdmin": true}),
    );
    if (!mounted) return;
    await context.read<OrderProvider>().fetchOrders();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Cash marked as deposited ✅"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _markAllDeposited(List<Order> orders) async {
    for (final order in orders) {
      if (!order.cashDepositedToAdmin) {
        await http.put(
          Uri.parse(
              "https://naturalfruitveg.com/api/orders/delivery/collect-cash/${order.id}"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"cashDepositedToAdmin": true}),
        );
      }
    }
    if (!mounted) return;
    await context.read<OrderProvider>().fetchOrders();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("All cash marked as deposited ✅"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final groups = _groupByDeliveryBoy(provider.orders);

    // Overall summary
    final codOrders = provider.orders
        .where((o) => o.paymentMethod == 'cod' && o.orderStatus == 'delivered')
        .toList();
    final totalCollected =
        codOrders.fold<double>(0, (s, o) => s + o.grandTotal);
    final totalPending = codOrders
        .where((o) => !o.cashDepositedToAdmin)
        .fold<double>(0, (s, o) => s + o.grandTotal);
    final totalDeposited = codOrders
        .where((o) => o.cashDepositedToAdmin)
        .fold<double>(0, (s, o) => s + o.grandTotal);

    return AdminLayout(
      title: 'Cash Collection',
      showBack: true,
      child: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// ===== SUMMARY CARDS =====
                    Row(
                      children: [
                        _SummaryCard(
                          label: 'Total COD',
                          amount: totalCollected,
                          color: Colors.blue,
                          icon: Icons.monetization_on,
                        ),
                        const SizedBox(width: 16),
                        _SummaryCard(
                          label: 'Pending',
                          amount: totalPending,
                          color: Colors.red,
                          icon: Icons.money_off,
                        ),
                        const SizedBox(width: 16),
                        _SummaryCard(
                          label: 'Deposited',
                          amount: totalDeposited,
                          color: Colors.green,
                          icon: Icons.account_balance_wallet,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    /// ===== FILTER TABS =====
                    Row(
                      children: [
                        _filterChip('Pending', 'pending'),
                        const SizedBox(width: 10),
                        _filterChip('Deposited', 'deposited'),
                        const SizedBox(width: 10),
                        _filterChip('All', 'all'),
                      ],
                    ),

                    const SizedBox(height: 20),

                    /// ===== DELIVERY BOY GROUPS =====
                    if (groups.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            children: [
                              Icon(Icons.payments_outlined,
                                  size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                _filter == 'pending'
                                    ? 'No pending cash collections 🎉'
                                    : 'No records found',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...groups.values.map((group) =>
                          _DeliveryBoyCard(
                            group: group,
                            onMarkDeposited: _markDeposited,
                            onMarkAllDeposited: () =>
                                _markAllDeposited(group.orders),
                          )),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF0F172A)
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[700],
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// ===== DELIVERY BOY GROUP CARD =====
class _DeliveryBoyCard extends StatefulWidget {
  final _DeliveryBoyGroup group;
  final Function(String) onMarkDeposited;
  final VoidCallback onMarkAllDeposited;

  const _DeliveryBoyCard({
    required this.group,
    required this.onMarkDeposited,
    required this.onMarkAllDeposited,
  });

  @override
  State<_DeliveryBoyCard> createState() => _DeliveryBoyCardState();
}

class _DeliveryBoyCardState extends State<_DeliveryBoyCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final total = widget.group.orders
        .fold<double>(0, (s, o) => s + o.grandTotal);
    final pendingCount = widget.group.orders
        .where((o) => !o.cashDepositedToAdmin)
        .length;
    final pendingAmount = widget.group.orders
        .where((o) => !o.cashDepositedToAdmin)
        .fold<double>(0, (s, o) => s + o.grandTotal);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          /// Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF0F172A),
                    child: Text(
                      widget.group.name[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.group.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                        Text(
                          '${widget.group.orders.length} orders • ₹${total.toStringAsFixed(0)} total',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (pendingCount > 0) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${pendingAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '$pendingCount pending',
                          style: const TextStyle(
                              color: Colors.red, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          /// Mark All button
          if (_expanded && pendingCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.done_all, size: 16),
                  label: Text(
                      'Mark All Deposited (₹${pendingAmount.toStringAsFixed(0)})'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: widget.onMarkAllDeposited,
                ),
              ),
            ),

          /// Orders list
          if (_expanded) ...[
            const Divider(height: 1),
            ...widget.group.orders.map((order) {
              final shortId = order.id.length > 6
                  ? order.id.substring(order.id.length - 6)
                  : order.id;
              final deposited = order.cashDepositedToAdmin;

              return ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: deposited
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  child: Icon(
                    deposited ? Icons.check : Icons.access_time,
                    color: deposited ? Colors.green : Colors.red,
                    size: 16,
                  ),
                ),
                title: Text('Order #$shortId',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(order.customerName,
                    style: const TextStyle(fontSize: 12)),
                trailing: deposited
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Deposited',
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${order.grandTotal.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () =>
                                widget.onMarkDeposited(order.id),
                            child: const Text('Mark',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// ===== DATA CLASSES =====
class _DeliveryBoyGroup {
  final String id;
  final String name;
  final List<Order> orders = [];

  _DeliveryBoyGroup({required this.id, required this.name});
}

/// ===== SUMMARY CARD =====
class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(label,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
