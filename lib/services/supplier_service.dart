import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/supplier_model.dart';

class SupplierService {
  static const String baseUrl =
      'https://naturalfruitveg.com/api/admin/suppliers';

  /// GET all suppliers
  static Future<List<Supplier>> fetchSuppliers() async {
    final res = await http.get(Uri.parse(baseUrl));

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Supplier.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load suppliers');
    }
  }

  /// ADD supplier
  static Future<void> addSupplier(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('Failed to add supplier');
    }
  }

  /// DELETE supplier
  static Future<void> deleteSupplier(String id) async {
    final res =
        await http.delete(Uri.parse('$baseUrl/$id'));

    if (res.statusCode != 200) {
      throw Exception('Failed to delete supplier');
    }
  }
}
