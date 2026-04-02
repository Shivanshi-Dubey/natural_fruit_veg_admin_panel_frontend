import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/purchase_invoice_model.dart';

class PurchaseInvoiceProvider extends ChangeNotifier {
  final String baseUrl =
      'https://naturalfruitveg.com/api/admin/purchase-invoices';

  bool isLoading = false;
  String? error;
  List<PurchaseInvoice> invoices = [];

  Future<void> fetchInvoices() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final res = await http.get(Uri.parse(baseUrl));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        invoices =
            data.map((e) => PurchaseInvoice.fromJson(e)).toList();
      } else {
        error = 'Failed to load invoices';
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToInventory(String invoiceId) async {
  try {
    isLoading = true;
    notifyListeners();

    final res = await http.post(
      Uri.parse(
        'https://naturalfruitveg.com/api/admin/purchase-invoices/add-to-inventory/$invoiceId',
      ),
    );

    print("ADD INVENTORY RESPONSE: ${res.body}");

    if (res.statusCode == 200) {
      await fetchInvoices(); // refresh UI
    } else {
      error = "Failed to add to inventory";
    }
  } catch (e) {
    error = e.toString();
  } finally {
    isLoading = false;
    notifyListeners();
  }
}

  Future<bool> createInvoice({
  required String invoiceNumber,
  required String supplierName,
  required double totalAmount,
}) async {
  try {
    isLoading = true;
    notifyListeners();

    final res = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'invoiceNumber': invoiceNumber,
        'supplierName': supplierName,
        'totalAmount': totalAmount,
      }),
    );

    if (res.statusCode == 201 || res.statusCode == 200) {
      await fetchInvoices(); // refresh list
      return true;
    } else {
      error = 'Failed to create invoice';
      return false;
    }
  } catch (e) {
    error = e.toString();
    return false;
  } finally {
    isLoading = false;
    notifyListeners();
  }
}

}
