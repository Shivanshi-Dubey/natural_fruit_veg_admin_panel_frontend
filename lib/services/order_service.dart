import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';

class OrderService {
  static const String baseUrl = 'https://naturalfruitveg.com/api/orders';

  static Future<List<Order>> fetchOrders() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => Order.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  static Future<void> updateOrderStatus(String id, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update status');
    }
  }

  Future<void> assignDeliveryBoy({
  required String orderId,
  required String deliveryBoyId,
}) async {
  final url = Uri.parse(
    '${ApiConfig.baseUrl}/api/orders/admin/$orderId',
  );

  final response = await http.put(
    url,
    headers: {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'deliveryBoyId': deliveryBoyId,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to assign delivery boy');
  }
}

}
