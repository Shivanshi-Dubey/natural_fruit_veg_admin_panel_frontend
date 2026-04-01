import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:audioplayers/audioplayers.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import '../layouts/admin_layout.dart';
import '../models/order_model.dart';
import '../models/delivery_boy.dart';
import '../providers/order_provider.dart';
import '../utils/invoice_generator.dart';
import '../screens/create_order_screen.dart';

class OrdersScreen extends StatefulWidget {
  final bool showOnlyPaid;
  const OrdersScreen({super.key, this.showOnlyPaid = false});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late IO.Socket socket;
  String searchQuery = "";
  String dateFilter = "all";
  final AudioPlayer player = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _requestNotificationPermission();

    socket = IO.io(
      'https://naturalfruitveg.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      debugPrint("Admin socket connected: ${socket.id}");
    });

    socket.onDisconnect((_) {
      debugPrint("Admin socket disconnected");
    });

    // ✅ New order listener
    socket.on('newOrder', (_) async {
      if (!mounted) return;
      context.read<OrderProvider>().fetchOrders();
      _playSound();
      _showBrowserNotification("New Order!", "A new order has been placed.");
      _showNewOrderPopup();
    });

    // ✅ Return request listener
    socket.on("return-request", (data) async {
      if (!mounted) return;
      debugPrint("Return request: $data");
      await context.read<OrderProvider>().fetchOrders();
      _showBrowserNotification(
        "Return Request",
        "Customer requested return for order #${data['orderId'].toString().substring(data['orderId'].toString().length - 6)}",
      );
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Return Request"),
          content: Text(
            "Customer requested return for order #${data['orderId'].toString().substring(data['orderId'].toString().length - 6)}",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    });
  }

  void _requestNotificationPermission() {
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', ["""
          if ('Notification' in window) {
            Notification.requestPermission().then(function(p) {
              console.log('Notification permission:', p);
            });
          }
        """]);
      } catch (e) {
        debugPrint("Notification permission error: $e");
      }
    }
  }

  void _showBrowserNotification(String title, String body) {
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', ["""
          if ('Notification' in window && Notification.permission === 'granted') {
            new Notification('$title', {
              body: '$body',
              icon: '/icons/Icon-192.png'
            });
          }
        """]);
      } catch (e) {
        debugPrint("Browser notification error: $e");
      }
    }
  }

  void _playSound() {
    if (kIsWeb) {
      try {
        js.context.callMethod('eval', ["""
          var audio = new Audio('/assets/assets/sounds/new_order.mp3');
          audio.play().catch(function(e) {
            console.log('Audio blocked:', e);
          });
        """]);
      } catch (e) {
        debugPrint("Sound error: $e");
      }
    } else {
      player.play(AssetSource('sounds/new_order.mp3'));
    }
  }

  @override
  void dispose() {
    socket.dispose();
    player.dispose();
    super.dispose();
  }

  void _showNewOrderPopup() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text("New Order"),
        content: Text("A new order has been placed."),
      ),
    );
  }

  List<Order> _applyFilters(List<Order> orders) {
    List<Order> filtered = orders;
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((o) =>
              o.customerName
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              o.id.contains(searchQuery))
          .toList();
    }
    if (dateFilter == "today") {
      final today = DateTime.now();
      filtered = filtered
          .where((o) =>
              o.createdAt.year == today.year &&
              o.createdAt.month == today.month &&
              o.createdAt.day == today.day)
          .toList();
    }
    if (dateFilter == "week") {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      filtered =
          filtered.where((o) => o.createdAt.isAfter(weekAgo)).toList();
    }
    return filtered;
  }

  Map<String, dynamic> _calculateStats(List<Order> orders) {
    double totalRevenue = 0, codPending = 0, upiRevenue = 0;
    for (var o in orders) {
      totalRevenue += o.grandTotal;
      if (o.paymentMethod == 'cod' && o.paymentStatus == 'pending')
        codPending += o.grandTotal;
      if (o.paymentMethod == 'upi' && o.paymentStatus == 'paid')
        upiRevenue += o.grandTotal;
    }
    return {
      "totalOrders": orders.length,
      "totalRevenue": totalRevenue,
      "codPending": codPending,
      "upiRevenue": upiRevenue,
    };
  }

  Future<void> _showAssignDeliveryDialog(Order order) async {
    try {
      final response = await http
          .get(Uri.parse("https://naturalfruitveg.com/api/delivery-boys"));
      final data = jsonDecode(response.body);
      List<DeliveryBoy> boys =
          (data as List).map((e) => DeliveryBoy.fromJson(e)).toList();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Assign Delivery Boy"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            )
          ],
          content: SizedBox(
            width: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: boys.length,
              itemBuilder: (context, index) {
                final boy = boys[index];
                return ListTile(
                  title: Text(boy.name),
                  subtitle: Text(boy.phone),
                  trailing: ElevatedButton(
                    child: const Text("Assign"),
                    onPressed: () async {
                      // ✅ FIX 3: Only assign delivery boy, keep status as 'packed'
                      // Do NOT set out_for_delivery — delivery boy will do that
                      await context
                          .read<OrderProvider>()
                          .assignDeliveryBoy(order.id, boy.id);

                      Navigator.pop(context);
                      await context.read<OrderProvider>().fetchOrders();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "${boy.name} assigned to order #${order.id.substring(order.id.length - 6)}"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<String> _checkNotificationPermission() async {
    if (!kIsWeb) return 'granted';
    try {
      final result = js.context
          .callMethod('eval', ["Notification.permission"]) as String;
      return result;
    } catch (e) {
      return 'default';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    List<Order> orders = _applyFilters(provider.orders);
    final stats = _calculateStats(orders);

    return AdminLayout(
      title: 'Orders',
      showBack: true,
      child: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ✅ Notification permission banner
                    if (kIsWeb)
                      FutureBuilder<String>(
                        future: _checkNotificationPermission(),
                        builder: (context, snap) {
                          if (snap.data == 'denied' ||
                              snap.data == 'default') {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.orange.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.notifications_off,
                                      color: Colors.orange),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      "Enable notifications to get new order alerts",
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed:
                                        _requestNotificationPermission,
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange),
                                    child: const Text("Enable",
                                        style: TextStyle(
                                            color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                    // SEARCH
                    TextField(
                      decoration: const InputDecoration(
                        hintText: "Search by customer or order ID",
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => searchQuery = v),
                    ),

                    const SizedBox(height: 20),

                    // DATE FILTER
                    Row(
                      children: [
                        _dateButton("All", "all"),
                        const SizedBox(width: 10),
                        _dateButton("Today", "today"),
                        const SizedBox(width: 10),
                        _dateButton("Last 7 Days", "week"),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // STATS
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _statCard("Total Orders",
                            stats["totalOrders"].toString(), Colors.blue),
                        _statCard(
                            "Total Revenue",
                            "Rs.${stats["totalRevenue"].toStringAsFixed(0)}",
                            Colors.green),
                        _statCard(
                            "COD Pending",
                            "Rs.${stats["codPending"].toStringAsFixed(0)}",
                            Colors.red),
                        _statCard(
                            "UPI Revenue",
                            "Rs.${stats["upiRevenue"].toStringAsFixed(0)}",
                            Colors.orange),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // 🔥 CREATE ORDER BUTTON (ADD HERE)
Row(
  mainAxisAlignment: MainAxisAlignment.end,
  children: [
    ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const CreateOrderScreen(),
          ),
        );
      },
      icon: const Icon(Icons.add),
      label: const Text("Create Order"),
    ),
  ],
),

const SizedBox(height: 20),


                    // ORDERS LIST
                    if (orders.isEmpty)
                      const Center(child: Text("No orders found"))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: orders.length,
                        itemBuilder: (context, index) =>
                            _buildOrderCard(orders[index]),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.id.substring(order.id.length - 6)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              _StatusChip(order.orderStatus),
            ],
          ),

          const SizedBox(height: 10),

          Text("Customer: ${order.customerName}"),
          Text(
            "Total: Rs.${order.grandTotal.toStringAsFixed(0)}",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

          if (order.deliveryBoyName != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                "Delivery: ${order.deliveryBoyName}",
                style: const TextStyle(
                    color: Colors.blue, fontSize: 13),
              ),
            ),

          const Divider(height: 24),

          ...order.items.map((i) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text("${i.name} x ${i.quantity}")),
                  Text(
                      "Rs.${(i.price * i.quantity).toStringAsFixed(0)}"),
                ],
              )),

          const SizedBox(height: 16),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // INVOICE
              ElevatedButton.icon(
                icon: const Icon(Icons.download, size: 16),
                label: const Text("Invoice"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                ),
                onPressed: () =>
                    InvoiceGenerator.downloadInvoice(context, order),
              ),

              // ACCEPT ORDER
              if (order.orderStatus == 'placed')
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green),
                  onPressed: () async {
                    await context
                        .read<OrderProvider>()
                        .updateOrderStatus(order.id, 'accepted');
                    await context.read<OrderProvider>().fetchOrders();
                    if (!mounted) return;
                    _showAssignDeliveryDialog(order);
                  },
                  child: const Text("Accept Order"),
                ),

              // ASSIGN DELIVERY
              if (order.orderStatus == 'accepted')
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue),
                  onPressed: () => _showAssignDeliveryDialog(order),
                  child: const Text("Assign Delivery"),
                ),

              // RETURN REQUEST
              if (order.returnStatus == 'requested') ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.orange.shade300),
                  ),
                  child: const Text(
                    "Return Requested",
                    style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green),
                  onPressed: () async {
                    await http.put(
                      Uri.parse(
                          "https://naturalfruitveg.com/api/orders/update-return/${order.id}"),
                      headers: {"Content-Type": "application/json"},
                      body:
                          jsonEncode({"returnStatus": "approved"}),
                    );
                    await context.read<OrderProvider>().fetchOrders();
                  },
                  child: const Text("Approve Return"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red),
                  onPressed: () async {
                    await http.put(
                      Uri.parse(
                          "https://naturalfruitveg.com/api/orders/update-return/${order.id}"),
                      headers: {"Content-Type": "application/json"},
                      body:
                          jsonEncode({"returnStatus": "rejected"}),
                    );
                    await context.read<OrderProvider>().fetchOrders();
                  },
                  child: const Text("Reject Return"),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }

  Widget _dateButton(String text, String value) {
    final selected = dateFilter == value;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? Colors.black : Colors.grey[300],
        foregroundColor: selected ? Colors.white : Colors.black,
      ),
      onPressed: () => setState(() => dateFilter = value),
      child: Text(text),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'delivered':
        color = Colors.green;
        break;
      case 'out_for_delivery':
      case 'accepted':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
