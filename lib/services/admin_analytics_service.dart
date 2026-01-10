import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminAnalyticsService {
  static const String baseUrl =
      "https://naturalfruitveg.com/api/admin/analytics";

  /// 🔴 Dead Products
  static Future<List<dynamic>> fetchDeadProducts() async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/dead-products"));

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return decoded is List ? decoded : [];
      } else {
        print("❌ Dead products error: ${res.body}");
        return [];
      }
    } catch (e) {
      print("❌ Dead products exception: $e");
      return [];
    }
  }
}
