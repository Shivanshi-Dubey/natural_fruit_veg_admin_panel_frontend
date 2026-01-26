import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
import '../providers/expense_provider.dart';


class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        context.read<ExpenseProvider>().fetchExpenses());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    return AdminLayout(
      title: 'Expenses',
      child: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Title')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Date')),
                ],
                rows: provider.expenses.map((e) {
                  return DataRow(cells: [
                    DataCell(Text(e.title)),
                    DataCell(Text(e.category.toUpperCase())),
                    DataCell(Text('₹${e.amount}')),
                    DataCell(Text(
                        e.date.toString().substring(0, 10))),
                  ]);
                }).toList(),
              ),
            ),
    );
  }
}
