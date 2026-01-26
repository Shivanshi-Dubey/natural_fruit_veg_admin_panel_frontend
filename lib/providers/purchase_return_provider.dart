import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/purchase_return_model.dart';

class PurchaseReturnProvider extends ChangeNotifier {
  final String baseUrl =
      'https://naturalfruitveg.com/api/admin/purchase-returns';

  bool isLoading = false;
  List<PurchaseReturn> returns = [];

  Future<void> fetchReturns() async {
    try {
      isLoading = true;
      notifyListeners();

      final res = await http.get(Uri.parse(baseUrl));
      final data = jsonDecode(res.body) as List;

      returns =
          data.map((e) => PurchaseReturn.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Purchase return error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
