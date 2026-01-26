import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
import '../providers/expense_provider.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _titleCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  bool isSaving = false;

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Add Expense',
      showBack: true,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field('Title', _titleCtrl),
            const SizedBox(height: 16),

            _field('Category (Fuel, Transport, Rent)', _categoryCtrl),
            const SizedBox(height: 16),

            _field(
              'Amount',
              _amountCtrl,
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 16),

            _field('Note (optional)', _noteCtrl),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: isSaving ? null : _saveExpense,
              child: Text(isSaving ? 'Saving...' : 'Save Expense'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Future<void> _saveExpense() async {
    if (_titleCtrl.text.isEmpty ||
        _categoryCtrl.text.isEmpty ||
        _amountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all required fields')),
      );
      return;
    }

    setState(() => isSaving = true);

    await context.read<ExpenseProvider>().addExpense(
          _titleCtrl.text.trim(),
          _categoryCtrl.text.trim(),
          double.parse(_amountCtrl.text),
          _noteCtrl.text.trim(),
        );

    setState(() => isSaving = false);

    Navigator.pop(context);
  }
}
