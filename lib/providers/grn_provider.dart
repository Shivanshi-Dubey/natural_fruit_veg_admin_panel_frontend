import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/grn_model.dart';

class GRNProvider extends ChangeNotifier {
  final String baseUrl =
      'https://naturalfruitveg.com/api/admin/grn';

  bool isLoading = false;
  List<GRN> grns = [];

  Future<void> fetchGRNs() async {
    try {
      isLoading = true;
      notifyListeners();

      final res = await http.get(Uri.parse(baseUrl));
      final data = jsonDecode(res.body) as List;

      grns = data.map((e) => GRN.fromJson(e)).toList();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
