import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:audioplayers/audioplayers.dart';
import '../layouts/admin_layout.dart';
import '../models/order_model.dart';
import '../models/delivery_boy.dart';
import '../providers/order_provider.dart';

class OrdersScreen extends StatefulWidget {
  final bool showOnlyPaid;

  const OrdersScreen({
    super.key,
    this.showOnlyPaid = false,
  });

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

    socket = IO.io(
      'https://naturalfruitveg.com',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    socket.on('newOrder', (_) async {

  context.read<OrderProvider>().fetchOrders();

  await player.play(AssetSource('sounds/new_order.mp3.mp3'));

  _showNewOrderPopup();
});
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  void _showNewOrderPopup() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text("🆕 New Order"),
        content: Text("A new order has been placed."),
      ),
    );
  }

  /// ================= FILTERS =================

  List<Order> _applyFilters(List<Order> orders) {
    List<Order> filtered = orders;

    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((o) =>
          o.customerName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          o.id.contains(searchQuery)).toList();
    }

    if (dateFilter == "today") {
      final today = DateTime.now();
      filtered = filtered.where((o) =>
          o.createdAt.year == today.year &&
          o.createdAt.month == today.month &&
          o.createdAt.day == today.day).toList();
    }

    if (dateFilter == "week") {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      filtered = filtered.where((o) => o.createdAt.isAfter(weekAgo)).toList();
    }

    return filtered;
  }

  Map<String, dynamic> _calculateStats(List<Order> orders) {
    double totalRevenue = 0;
    double codPending = 0;
    double upiRevenue = 0;

    for (var o in orders) {
      totalRevenue += o.grandTotal;

      if (o.paymentMethod == 'cod' && o.paymentStatus == 'pending') {
        codPending += o.grandTotal;
      }

      if (o.paymentMethod == 'upi' && o.paymentStatus == 'paid') {
        upiRevenue += o.grandTotal;
      }
    }

    return {
      "totalOrders": orders.length,
      "totalRevenue": totalRevenue,
      "codPending": codPending,
      "upiRevenue": upiRevenue,
    };
  }

  /// ================= ASSIGN DELIVERY BOY =================

  Future<void> _showAssignDeliveryDialog(Order order) async {
    try {
      final response = await http.get(
        Uri.parse("https://naturalfruitveg.com/api/delivery-boys"),
      );

      final data = jsonDecode(response.body);

      List<DeliveryBoy> boys =
          (data as List).map((e) => DeliveryBoy.fromJson(e)).toList();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
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

                        /// Assign delivery boy
                        await context
                            .read<OrderProvider>()
                            .assignDeliveryBoy(order.id, boy.id);

                        /// Update order status
                        await context
                            .read<OrderProvider>()
                            .updateOrderStatus(order.id, 'out_for_delivery');

                        Navigator.pop(context);

                        /// Refresh orders
                        await context.read<OrderProvider>().fetchOrders();
                      },
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint(e.toString());
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

                    /// SEARCH
                    TextField(
                      decoration: const InputDecoration(
                        hintText: "Search by customer or order ID",
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    /// DATE FILTER
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

                    /// DASHBOARD STATS
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _statCard("Total Orders",
                            stats["totalOrders"].toString(), Colors.blue),
                        _statCard(
                            "Total Revenue",
                            "₹${stats["totalRevenue"].toStringAsFixed(0)}",
                            Colors.green),
                        _statCard(
                            "COD Pending",
                            "₹${stats["codPending"].toStringAsFixed(0)}",
                            Colors.red),
                        _statCard(
                            "UPI Revenue",
                            "₹${stats["upiRevenue"].toStringAsFixed(0)}",
                            Colors.orange),
                      ],
                    ),

                    const SizedBox(height: 30),

                    /// ORDERS LIST
                    if (orders.isEmpty)
                      const Center(child: Text("No orders found"))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          return _buildOrderCard(order);
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  /// ================= ORDER CARD =================

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
  "Total: ₹${order.grandTotal.toStringAsFixed(0)}",
  style: const TextStyle(
    fontWeight: FontWeight.w600,
  ),
),

          const Divider(height: 24),

          ...order.items.map((i) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text("${i.name} × ${i.quantity}")),
                  Text("₹${(i.price * i.quantity).toStringAsFixed(0)}"),
                ],
              )),

          const SizedBox(height: 16),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [

              /// PRINT
              OutlinedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text("Print"),
                onPressed: () => _printOrder(order),
              ),

              /// ACCEPT ORDER
              if (order.orderStatus == 'placed')
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
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

              /// ASSIGN DELIVERY
              if (order.orderStatus == 'accepted')
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () {
                    _showAssignDeliveryDialog(order);
                  },
                  child: const Text("Assign Delivery"),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// ================= PRINT =================

  Future<void> _printOrder(Order order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Natural Fruit & Veg",
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text("Order ID: ${order.id}"),
            pw.Text("Customer: ${order.customerName}"),
            pw.SizedBox(height: 10),
            ...order.items.map((i) => pw.Text("${i.name} x${i.quantity}")),
            pw.Divider(),
            pw.Text("Grand Total: ₹${order.grandTotal.toStringAsFixed(0)}"),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
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
          Text(
            value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
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
      onPressed: () {
        setState(() {
          dateFilter = value;
        });
      },
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
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}