import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/purchase_return_model.dart';

class PurchaseReturnProvider extends ChangeNotifier {
  final String baseUrl =
      'https://naturalfruitveg.com/api/admin/purchase-returns';

  bool isLoading = false;
  String? error;
  List<PurchaseReturn> returns = [];

  Future<void> fetchReturns() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();

      final res = await http.get(Uri.parse(baseUrl));

      debugPrint('Purchase returns status: ${res.statusCode}');
      debugPrint('Purchase returns body: ${res.body}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        returns = data.map((e) => PurchaseReturn.fromJson(e)).toList();
      } else {
        error = 'Failed to load returns (${res.statusCode})';
      }
    } catch (e) {
      error = 'Error: $e';
      debugPrint('Purchase return error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}