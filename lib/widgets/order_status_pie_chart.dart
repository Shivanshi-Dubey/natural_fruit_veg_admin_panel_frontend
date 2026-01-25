import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/order_model.dart';

class OrderStatusPieChart extends StatelessWidget {
  final List<Order> orders;

  const OrderStatusPieChart({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    final Map<String, int> map = {};

    for (final o in orders) {
      map[o.status] = (map[o.status] ?? 0) + 1;
    }

    final colors = {
      'placed': Colors.grey,
      'accepted': Colors.blue,
      'delivered': Colors.green,
      'cancelled': Colors.red,
    };

    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: PieChart(
        PieChartData(
          sections: map.entries.map((e) {
            return PieChartSectionData(
              value: e.value.toDouble(),
              title: e.key,
              color: colors[e.key] ?? Colors.orange,
            );
          }).toList(),
        ),
      ),
    );
  }

  BoxDecoration _box() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      );
}
