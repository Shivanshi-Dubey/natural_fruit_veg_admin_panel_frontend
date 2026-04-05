import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/supplier_model.dart';

class SupplierProvider extends ChangeNotifier {

  // ✅ SINGLE SOURCE OF TRUTH
  List<Supplier> _suppliers = [];

  // ✅ FIX: Added isLoading and error state
  bool _isLoading = false;
  String? _error;

  // ✅ PUBLIC GETTERS
  List<Supplier> get suppliers => _suppliers;
  bool get isLoading => _isLoading;       // ✅ was missing
  String? get error => _error;            // ✅ was missing

  // ================= FETCH =================
  Future<void> fetchSuppliers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse(
          "https://naturalfruitveg.com/api/admin/suppliers");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _suppliers = (data as List)
            .map((e) => Supplier.fromJson(e))
            .toList();

        _isLoading = false;
        notifyListeners();
      } else {
        _isLoading = false;
        _error = "Failed to fetch suppliers (${response.statusCode})";
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      _error = "Network error: ${e.toString()}";
      notifyListeners();
    }
  }

  // ================= ADD =================
  Future<void> addSupplier(Supplier supplier, BuildContext context) async {
    try {
      final url = Uri.parse(
          "https://naturalfruitveg.com/api/admin/suppliers");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": supplier.name,
          "phone": supplier.phone,
          "email": supplier.email,
          "address": supplier.address,
          "gstNumber": supplier.gstNumber,
          "isActive": supplier.isActive,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ Re-fetch to get server-assigned ID instead of local add
        await fetchSuppliers();
      } else {
        throw Exception("Failed to add supplier");
      }
    } catch (e) {
      rethrow;
    }
  }

  // ================= UPDATE =================
  Future<void> updateSupplier(Supplier supplier, BuildContext context) async {
    try {
      final url = Uri.parse(
          "https://naturalfruitveg.com/api/admin/suppliers/${supplier.id}");

      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": supplier.name,
          "phone": supplier.phone,
          "email": supplier.email,
          "address": supplier.address,
          "gstNumber": supplier.gstNumber,
          "isActive": supplier.isActive,
        }),
      );

      if (response.statusCode == 200) {
        final index =
            _suppliers.indexWhere((s) => s.id == supplier.id);
        if (index != -1) {
          _suppliers[index] = supplier;
          notifyListeners();
        }
      } else {
        throw Exception("Failed to update supplier");
      }
    } catch (e) {
      rethrow;
    }
  }

  // ================= DELETE =================
  Future<void> deleteSupplier(String id) async {
    try {
      final url = Uri.parse(
          "https://naturalfruitveg.com/api/admin/suppliers/$id");

      final response = await http.delete(url);

      if (response.statusCode == 200) {
        _suppliers.removeWhere((s) => s.id == id);
        notifyListeners();
      } else {
        throw Exception("Failed to delete supplier");
      }
    } catch (e) {
      rethrow;
    }
  }
}
