import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../layouts/admin_layout.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  String _filter = 'requested'; // requested | approved | rejected | all

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().fetchOrders();
    });
  }

  List<Order> _filteredOrders(List<Order> orders) {
    if (_filter == 'all') {
      return orders.where((o) => o.returnStatus != 'none').toList();
    }
    return orders.where((o) => o.returnStatus == _filter).toList();
  }

  Future<void> _updateReturn(String orderId, String status) async {
    await http.put(
      Uri.parse("https://naturalfruitveg.com/api/orders/update-return/$orderId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"returnStatus": status}),
    );
    if (!mounted) return;
    await context.read<OrderProvider>().fetchOrders();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Return ${status == 'approved' ? 'Approved ✅' : 'Rejected ❌'}"),
        backgroundColor: status == 'approved' ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final filtered = _filteredOrders(provider.orders);

    // Summary counts
    final requested = provider.orders.where((o) => o.returnStatus == 'requested').length;
    final approved = provider.orders.where((o) => o.returnStatus == 'approved').length;
    final rejected = provider.orders.where((o) => o.returnStatus == 'rejected').length;

    return AdminLayout(
      title: 'Returns',
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
                          label: 'Pending',
                          count: requested,
                          color: Colors.orange,
                          icon: Icons.pending_actions,
                        ),
                        const SizedBox(width: 16),
                        _SummaryCard(
                          label: 'Approved',
                          count: approved,
                          color: Colors.green,
                          icon: Icons.check_circle,
                        ),
                        const SizedBox(width: 16),
                        _SummaryCard(
                          label: 'Rejected',
                          count: rejected,
                          color: Colors.red,
                          icon: Icons.cancel,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    /// ===== FILTER TABS =====
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('All Returns', 'all'),
                          const SizedBox(width: 10),
                          _filterChip('Requested', 'requested'),
                          const SizedBox(width: 10),
                          _filterChip('Approved', 'approved'),
                          const SizedBox(width: 10),
                          _filterChip('Rejected', 'rejected'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// ===== RETURN ORDERS LIST =====
                    if (filtered.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48),
                          child: Column(
                            children: [
                              Icon(Icons.assignment_return,
                                  size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No ${_filter == 'all' ? '' : _filter} return orders',
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _ReturnCard(
                          order: filtered[i],
                          onApprove: () =>
                              _updateReturn(filtered[i].id, 'approved'),
                          onReject: () =>
                              _updateReturn(filtered[i].id, 'rejected'),
                        ),
                      ),
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
            color: selected ? const Color(0xFF0F172A) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[700],
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// ===== RETURN CARD =====
class _ReturnCard extends StatelessWidget {
  final Order order;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ReturnCard({
    required this.order,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final shortId = order.id.length > 6
        ? order.id.substring(order.id.length - 6)
        : order.id;

    Color statusColor;
    IconData statusIcon;
    switch (order.returnStatus) {
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #$shortId',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    order.returnStatus.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),

          /// Customer & Amount
          Text('Customer: ${order.customerName}',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(
            'Amount: ₹${order.grandTotal.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            'Payment: ${order.paymentMethod.toUpperCase()} • ${order.paymentStatus.toUpperCase()}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const Divider(height: 20),

          /// Items
          ...order.items.map((i) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${i.name} x ${i.quantity}',
                        style: const TextStyle(fontSize: 13)),
                    Text(
                      '₹${(i.price * i.quantity).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              )),

          /// Action buttons — only for pending
          if (order.returnStatus == 'requested') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve Return'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onApprove,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject Return'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onReject,
                  ),
                ),
              ],
            ),
          ],

          if (order.returnStatus == 'approved')
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Return approved — refund to be processed',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// ===== SUMMARY CARD =====
class _SummaryCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.count,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(label,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
