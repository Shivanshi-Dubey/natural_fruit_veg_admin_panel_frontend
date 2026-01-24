import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
import '../providers/order_provider.dart';
import '../utils/csv_export.dart';

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
      ..sort(
        (a, b) => b.createdAt.compareTo(a.createdAt),
      ); // latest first

    final int totalOrders = orders.length;
    final double totalSpent =
        orders.fold(0.0, (sum, o) => sum + o.totalPrice);

    final int cancelledCount =
        orders.where((o) => o.status == 'cancelled').length;

    final String tag = _customerTag(totalOrders, cancelledCount);
    final Color tagColor = _tagColor(tag);

    return AdminLayout(
      title: 'Customer Details',
      showBack: true,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= CUSTOMER INFO =================
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
                          Text(
                            customerName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tagColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: tagColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Customer Account',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${totalSpent.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Lifetime Value',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ================= KPIs =================
            Row(
              children: [
                _kpi('Total Orders', totalOrders.toString()),
                _kpi(
                  'Avg Order',
                  totalOrders == 0
                      ? '₹0'
                      : '₹${(totalSpent / totalOrders).toStringAsFixed(0)}',
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                _kpi(
                  'Repeat Customer',
                  totalOrders > 1 ? 'YES' : 'NO',
                ),
                _kpi(
                  'Cancelled Orders',
                  cancelledCount.toString(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ================= ORDER HISTORY =================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Export Orders'),
                  onPressed: orders.isEmpty
                      ? null
                      : () {
                          final rows = <List<String>>[
                            ['Order ID', 'Amount', 'Payment', 'Status'],
                            ...orders.map(
                              (o) => [
                                o.id,
                                o.totalPrice.toStringAsFixed(0),
                                o.paymentStatus,
                                o.status,
                              ],
                            ),
                          ];

                          CsvExport.downloadCsv(
                            filename:
                                'orders_${customerName.replaceAll(" ", "_")}.csv',
                            rows: rows,
                          );
                        },
                ),
              ],
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Container(
                decoration: _box(),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.all(
                      const Color(0xFFF9FAFB),
                    ),
                    columns: const [
                      DataColumn(label: Text('Order ID')),
                      DataColumn(label: Text('Amount')),
                      DataColumn(label: Text('Payment')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: orders.map((o) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              o.id.substring(o.id.length - 6),
                            ),
                          ),
                          DataCell(
                            Text(
                              '₹${o.totalPrice.toStringAsFixed(0)}',
                            ),
                          ),
                          DataCell(
                            Text(
                              o.paymentStatus.toUpperCase(),
                              style: TextStyle(
                                color: o.paymentStatus == 'paid'
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DataCell(_statusChip(o.status)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= BUSINESS LOGIC =================

  String _customerTag(int totalOrders, int cancelled) {
    if (cancelled >= 2) return 'RISK';
    if (totalOrders >= 5) return 'LOYAL';
    if (totalOrders >= 2) return 'REGULAR';
    return 'NEW';
  }

  Color _tagColor(String tag) {
    switch (tag) {
      case 'LOYAL':
        return Colors.green;
      case 'REGULAR':
        return Colors.orange;
      case 'NEW':
        return Colors.blue;
      case 'RISK':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ================= UI HELPERS =================

  static BoxDecoration _box() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      );

  Widget _kpi(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: _box(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'placed':
        color = Colors.grey;
        break;
      case 'accepted':
        color = Colors.blue;
        break;
      case 'assigned':
      case 'out_for_delivery':
        color = Colors.orange;
        break;
      case 'delivered':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
