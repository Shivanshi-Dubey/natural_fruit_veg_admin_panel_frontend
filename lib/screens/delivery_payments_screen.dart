import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../layouts/admin_layout.dart';

class DeliveryPaymentsScreen extends StatefulWidget {
  const DeliveryPaymentsScreen({super.key});

  @override
  State<DeliveryPaymentsScreen> createState() =>
      _DeliveryPaymentsScreenState();
}

class _DeliveryPaymentsScreenState
    extends State<DeliveryPaymentsScreen> {
  static const String baseUrl = "https://naturalfruitveg.com/api";

  bool isLoading = true;
  bool hasError = false;
  List<dynamic> deliveryBoys = [];

  @override
  void initState() {
    super.initState();
    loadDeliveryBoys();
  }

  Future<void> loadDeliveryBoys() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/delivery-boys"),
        headers: {"Content-Type": "application/json"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          deliveryBoys = data is List ? data : (data['boys'] ?? []);
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Load delivery boys error: $e");
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> loadBoyEarnings(String id) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/orders/delivery/earnings/$id"),
        headers: {"Content-Type": "application/json"},
      );
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      debugPrint("❌ Earnings error: $e");
    }
    return {"totalEarnings": 0, "totalOrders": 0, "unpaidAmount": 0};
  }

  Future<void> markAsPaid(String deliveryBoyId, double amount) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/delivery-boys/mark-paid/$deliveryBoyId"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"amount": amount}),
      );
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Payment marked as paid"),
            backgroundColor: Colors.green,
          ),
        );
        loadDeliveryBoys();
      }
    } catch (e) {
      debugPrint("❌ Mark paid error: $e");
    }
  }

  void _showBoyDetails(dynamic boy) async {
    final id = boy['_id']?.toString() ?? '';
    final name = boy['name']?.toString() ?? 'Delivery Boy';
    final phone = boy['phone']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    final earnings = await loadBoyEarnings(id);
    if (!mounted) return;
    Navigator.pop(context);

    final double totalEarnings =
        (earnings['totalEarnings'] as num?)?.toDouble() ?? 0;
    final int totalOrders =
        (earnings['totalOrders'] as num?)?.toInt() ?? 0;
    final double unpaid =
        (earnings['unpaidAmount'] as num?)?.toDouble() ?? totalEarnings;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFF2E7D32),
              child: Icon(Icons.delivery_dining, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  Text(phone,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            const SizedBox(height: 8),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statPill("Total Orders", totalOrders.toString(),
                    Colors.blue),
                _statPill("Total Earned",
                    "₹${totalEarnings.toStringAsFixed(0)}", Colors.green),
                _statPill("Unpaid",
                    "₹${unpaid.toStringAsFixed(0)}", Colors.red),
              ],
            ),

            const SizedBox(height: 20),

            if (unpaid > 0)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(
                      "Mark ₹${unpaid.toStringAsFixed(0)} as Paid"),
                  onPressed: () async {
                    Navigator.pop(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Confirm Payment"),
                        content: Text(
                          "Mark ₹${unpaid.toStringAsFixed(0)} as paid to $name?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: const Text("Yes, Mark Paid"),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await markAsPaid(id, unpaid);
                    }
                  },
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text("All payments cleared",
                        style: TextStyle(color: Colors.green)),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: "Delivery Payments",
      showBack: true,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: loadDeliveryBoys,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Delivery Boy Payments",
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Tap any delivery boy to view earnings and mark payment",
                          style: TextStyle(
                              color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        if (deliveryBoys.isEmpty)
                          const Center(
                              child:
                                  Text("No delivery boys found"))
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            itemCount: deliveryBoys.length,
                            itemBuilder: (_, i) {
                              final boy = deliveryBoys[i];
                              final name =
                                  boy['name']?.toString() ?? '';
                              final phone =
                                  boy['phone']?.toString() ?? '';
                              final initials = name.length >= 2
                                  ? name.substring(0, 2).toUpperCase()
                                  : 'DB';

                              return Container(
                                margin: const EdgeInsets.only(
                                    bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(
                                          0xFFE5E7EB)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withOpacity(0.04),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        const Color(0xFF2E7D32),
                                    child: Text(initials,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight:
                                                FontWeight.bold)),
                                  ),
                                  title: Text(name,
                                      style: const TextStyle(
                                          fontWeight:
                                              FontWeight.w600)),
                                  subtitle: Text(phone,
                                      style: const TextStyle(
                                          color: Colors.grey)),
                                  trailing: const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey),
                                  onTap: () =>
                                      _showBoyDetails(boy),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              color: Colors.red, size: 56),
          const SizedBox(height: 16),
          const Text("Failed to load delivery boys"),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: loadDeliveryBoys,
            icon: const Icon(Icons.refresh),
            label: const Text("Retry"),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }
}