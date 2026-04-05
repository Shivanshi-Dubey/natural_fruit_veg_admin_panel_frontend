import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../layouts/admin_layout.dart';
import '../providers/order_provider.dart';
import '../utils/csv_export.dart';
import '../utils/invoice_generator.dart';

class CustomerDetailsScreen extends StatelessWidget {
  final String customerName;

  const CustomerDetailsScreen({
    super.key,
    required this.customerName,
  });

  @override
  Widget build(BuildContext context) {
    final orders = context
        .watch<OrderProvider>()
        .orders
        .where((o) => o.customerName == customerName)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final int totalOrders = orders.length;
    final double totalSpent =
        orders.fold(0.0, (sum, o) => sum + o.itemsTotal);
    final int cancelledCount =
        orders.where((o) => o.orderStatus == 'cancelled').length;
    final String tag = _customerTag(totalOrders, cancelledCount);
    final Color tagColor = _tagColor(tag);
    final fmt = DateFormat('dd MMM yyyy');

    return AdminLayout(
      title: 'Customer Details',
      showBack: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Customer Info Card ────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _box(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(customerName,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(width: 8),
                          _tagChip(tag, tagColor),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Customer Account',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${totalSpent.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                      const Text('Lifetime Value',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── KPI Cards ─────────────────────────────────
            Row(
              children: [
                _kpi('Total Orders', totalOrders.toString()),
                const SizedBox(width: 12),
                _kpi(
                  'Avg Order',
                  totalOrders == 0
                      ? '₹0'
                      : '₹${(totalSpent / totalOrders).toStringAsFixed(0)}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _kpi('Repeat Customer', totalOrders > 1 ? 'YES' : 'NO'),
                const SizedBox(width: 12),
                _kpi('Cancelled', cancelledCount.toString()),
              ],
            ),

            const SizedBox(height: 24),

            // ── Order History Header ──────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Order History',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                TextButton.icon(
                  onPressed: orders.isEmpty
                      ? null
                      : () {
                          final rows = <List<String>>[
                            // ✅ Date added to export too
                            ['Date', 'Order ID', 'Amount', 'Payment', 'Status'],
                            ...orders.map((o) => [
                                  fmt.format(o.createdAt),
                                  o.id.substring(o.id.length >= 6
                                      ? o.id.length - 6
                                      : 0),
                                  o.itemsTotal.toStringAsFixed(0),
                                  o.paymentMethod,
                                  o.orderStatus,
                                ]),
                          ];
                          CsvExport.downloadCsv(
                            filename:
                                'orders_${customerName.replaceAll(" ", "_")}.csv',
                            rows: rows,
                          );
                        },
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Export'),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Order History List ────────────────────────
            orders.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(30),
                    decoration: _box(),
                    child: const Center(
                      child: Text('No orders found',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final o = orders[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: _box(),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // ── Row 1: Date + Amount ──────
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                // ✅ DATE shown prominently
                                Row(
                                  children: [
                                    const Icon(
                                        Icons.calendar_today,
                                        size: 13,
                                        color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      fmt.format(o.createdAt),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight:
                                              FontWeight.w600,
                                          color: Colors.black87),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('hh:mm a')
                                          .format(o.createdAt),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors
                                              .grey.shade500),
                                    ),
                                  ],
                                ),
                                Text(
                                  '₹${o.itemsTotal.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF2E7D32)),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // ── Row 2: Order ID + Status ──
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Order #${o.id.substring(o.id.length >= 6 ? o.id.length - 6 : 0).toUpperCase()}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600),
                                ),
                                Row(
                                  children: [
                                    _statusChip(o.orderStatus),
                                    const SizedBox(width: 8),
                                    // Payment badge
                                    Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 3),
                                      decoration: BoxDecoration(
                                        color: o.paymentMethod ==
                                                'cod'
                                            ? Colors.orange.shade50
                                            : Colors.blue.shade50,
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        o.paymentMethod
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: o.paymentMethod ==
                                                  'cod'
                                              ? Colors.orange.shade700
                                              : Colors.blue.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // ── Row 3: Items ──────────────
                            Text(
                              o.items
                                  .map((it) =>
                                      '${it.name} ×${it.quantity}')
                                  .join(', '),
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            const SizedBox(height: 8),

                            // ── Row 4: Invoice Button ─────
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () =>
                                    InvoiceGenerator
                                        .downloadInvoice(context, o),
                                icon: const Icon(Icons.download,
                                    size: 14),
                                label: const Text('Invoice',
                                    style:
                                        TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      const Color(0xFF2E7D32),
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4),
                                  minimumSize: Size.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  String _customerTag(int totalOrders, int cancelled) {
    if (cancelled >= 2) return 'RISK';
    if (totalOrders >= 5) return 'LOYAL';
    if (totalOrders >= 2) return 'REGULAR';
    return 'NEW';
  }

  Color _tagColor(String tag) {
    switch (tag) {
      case 'LOYAL': return Colors.green;
      case 'REGULAR': return Colors.orange;
      case 'NEW': return Colors.blue;
      case 'RISK': return Colors.red;
      default: return Colors.grey;
    }
  }

  static BoxDecoration _box() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03), blurRadius: 4)
        ],
      );

  Widget _tagChip(String tag, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(tag,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }

  Widget _kpi(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _box(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final color = switch (status) {
      'delivered' => Colors.green,
      'placed' => Colors.grey,
      'accepted' => Colors.blue,
      'assigned' || 'out_for_delivery' => Colors.orange,
      'cancelled' => Colors.red,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color),
      ),
    );
  }
}