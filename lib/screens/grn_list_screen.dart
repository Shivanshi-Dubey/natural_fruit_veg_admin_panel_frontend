import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
import '../providers/grn_provider.dart';

class GRNListScreen extends StatefulWidget {
  const GRNListScreen({super.key});

  @override
  State<GRNListScreen> createState() => _GRNListScreenState();
}

class _GRNListScreenState extends State<GRNListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<GRNProvider>().fetchGRNs());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GRNProvider>();

    return AdminLayout(
      title: 'GRN List',
      child: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : DataTable(
              columns: const [
                DataColumn(label: Text('Supplier')),
                DataColumn(label: Text('Items')),
                DataColumn(label: Text('Date')),
              ],
              rows: provider.grns.map((g) {
                return DataRow(cells: [
                  DataCell(Text(g.supplierName)),
                  DataCell(Text(g.totalItems.toString())),
                  DataCell(Text(
                      '${g.date.day}/${g.date.month}/${g.date.year}')),
                ]);
              }).toList(),
            ),
    );
  }
}
