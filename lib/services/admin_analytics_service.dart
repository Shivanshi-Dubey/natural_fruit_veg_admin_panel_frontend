import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminAnalyticsService {
  static const String baseUrl =
      "https://naturalfruitveg.com/api/admin/analytics";

  /// 🔴 DEAD PRODUCTS (Never sold)
  static Future<List<dynamic>> fetchDeadProducts() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/dead-products"),
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return decoded is List ? decoded : [];
      } else {
        debugPrint("❌ Dead products error: ${res.body}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Dead products exception: $e");
      return [];
    }
  }

  /// 🟠 LOW STOCK PRODUCTS
  static Future<List<dynamic>> fetchLowStockProducts() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/low-stock"),
      );

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return decoded['products'] ?? [];
      } else {
        debugPrint("❌ Low stock error: ${res.body}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Low stock exception: $e");
      return [];
    }
  }

  /// 📊 FUTURE: Sales summary
  static Future<Map<String, dynamic>> fetchSalesSummary() async {
    // Placeholder for future reports
    return {};
  }
}
