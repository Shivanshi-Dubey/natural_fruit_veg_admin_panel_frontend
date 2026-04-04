import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/supplier_model.dart';

class SupplierProvider extends ChangeNotifier {
  final String baseUrl = 'https://naturalfruitveg.com/api/admin/suppliers';

  List<Supplier> suppliers = [];
  bool isLoading = false;
  String? error;

  Future<void> fetchSuppliers() async {
    isLoading = true;
    notifyListeners();

    try {
      final res = await http.get(Uri.parse(baseUrl));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        suppliers = data.map((e) => Supplier.fromJson(e)).toList();
        error = null;
      } else {
        error = 'Failed to load suppliers';
      }
    } catch (e) {
      error = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> addSupplier(Supplier supplier, BuildContext context) async {
    try {
      final res = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(supplier.toJson()),
      );

      if (res.statusCode == 201) {
        await fetchSuppliers();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add supplier')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

 Future<void> deleteSupplier(String id) async {
  try {
    final res = await http.delete(Uri.parse('$baseUrl/$id'));
    if (res.statusCode == 200) {
      suppliers.removeWhere((s) => s.id == id);
      notifyListeners();
    } else {
      error = 'Failed to delete supplier';
      notifyListeners();
    }
  } catch (e) {
    error = 'Failed to delete supplier';
    notifyListeners();
  }
}

}
