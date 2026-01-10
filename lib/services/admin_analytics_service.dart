import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminAnalyticsService {
  static const String baseUrl = "https://naturalfruitveg.com/api";

  static Future<Map<String, dynamic>> fetchDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/admin/analytics/summary"),
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to load analytics");
      }
    } catch (e) {
      throw Exception("Analytics error: $e");
    }
  }
}
