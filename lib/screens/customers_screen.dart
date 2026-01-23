import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

class CustomersScreen extends StatelessWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().orders;

    /// Build customer summary from orders
    final Map<String, _CustomerSummary> customers = {};

    for (final o in orders) {
      final key = o.customerName;

      customers.putIfAbsent(
        key,
        () => _CustomerSummary(name: o.customerName),
      );

      customers[key]!
        ..totalOrders += 1
        ..totalSpent += o.totalPrice;
    }

    return AdminLayout(
      title: 'Customers',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: customers.isEmpty
            ? const Center(child: Text('No customers found'))
            : Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: DataTable(
                  columnSpacing: 32,
                  headingRowColor: MaterialStateProperty.all(
                    const Color(0xFFF9FAFB),
                  ),
                  columns: const [
                    DataColumn(label: Text('Customer')),
                    DataColumn(label: Text('Orders')),
                    DataColumn(label: Text('Total Spent')),
                  ],
                  rows: customers.values.map((c) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            c.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                        DataCell(
                          Text(c.totalOrders.toString()),
                        ),
                        DataCell(
                          Text(
                            '₹${c.totalSpent.toStringAsFixed(0)}',
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
      ),
    );
  }
}

class _CustomerSummary {
  final String name;
  int totalOrders = 0;
  double totalSpent = 0;

  _CustomerSummary({
    required this.name,
  });
}
