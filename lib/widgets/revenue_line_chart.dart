import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/order_model.dart';

class RevenueLineChart extends StatelessWidget {
  final List<Order> orders;

  const RevenueLineChart({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    final sorted = [...orders]..sort(
        (a, b) => a.createdAt.compareTo(b.createdAt));

    final spots = <FlSpot>[];
    double index = 0;

    for (final o in sorted) {
      spots.add(FlSpot(index++, o.totalPrice));
    }

    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.green,
              barWidth: 3,
              dotData: FlDotData(show: false),
            )
          ],
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
