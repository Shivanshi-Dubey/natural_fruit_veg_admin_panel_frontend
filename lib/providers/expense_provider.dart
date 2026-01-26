import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/expense_model.dart';

class ExpenseProvider extends ChangeNotifier {
  final String _baseUrl =
      'https://naturalfruitveg.com/api/admin/expenses';

  bool isLoading = false;
  List<Expense> expenses = [];

  Future<void> fetchExpenses() async {
    isLoading = true;
    notifyListeners();

    final res = await http.get(Uri.parse(_baseUrl));
    final List data = jsonDecode(res.body);

    expenses =
        data.map((e) => Expense.fromJson(e)).toList();

    isLoading = false;
    notifyListeners();
  }

  Future<void> addExpense(
    String title,
    String category,
    double amount,
    String note,
  ) async {
    await http.post(
      Uri.parse(_baseUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "title": title,
        "category": category,
        "amount": amount,
        "note": note,
      }),
    );

    await fetchExpenses();
  }
}
