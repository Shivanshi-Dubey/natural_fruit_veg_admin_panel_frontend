import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminDropdownService {
  static const baseUrl = 'https://naturalfruitveg.com';

  static Future<List<dynamic>> fetchSuppliers() async {
    final res = await http.get(Uri.parse('$baseUrl/suppliers'));
    return jsonDecode(res.body);
  }

  static Future<List<dynamic>> fetchProducts() async {
    final res = await http.get(Uri.parse('$baseUrl/products'));
    return jsonDecode(res.body);
  }
}
