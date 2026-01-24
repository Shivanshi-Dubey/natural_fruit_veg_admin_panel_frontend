import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
import '../models/delivery_boy.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  String _statusFilter = 'all';
  List<Order> _filteredOrders = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<OrderProvider>().fetchOrders();
      _resetFilter();
    });
  }

  void _resetFilter() {
    final orders = context.read<OrderProvider>().orders;
    setState(() => _filteredOrders = orders);
  }

  /// 🔍 GLOBAL SEARCH
  void _onSearch(String query) {
    final orders = context.read<OrderProvider>().orders;

    if (query.isEmpty) {
      setState(() => _filteredOrders = orders);
      return;
    }

    final q = query.toLowerCase();

    setState(() {
      _filteredOrders = orders.where((o) {
        return o.customerName.toLowerCase().contains(q) ||
            o.id.toLowerCase().contains(q) ||
            (o.deliveryBoyName ?? '').toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();

    final visibleOrders = _statusFilter == 'all'
        ? _filteredOrders
        : _filteredOrders
            .where((o) => o.status == _statusFilter)
            .toList();

    return AdminLayout(
      title: 'Orders',

      /// 🔍 CONNECT SEARCH
      onSearch: _onSearch,

      child: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? Center(
                  child: Text(
                    provider.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// ================= HEADER =================
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Orders Management',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          DropdownButton<String>(
                            value: _statusFilter,
                            items: const [
                              DropdownMenuItem(
                                  value: 'all',
                                  child: Text('All')),
                              DropdownMenuItem(
                                  value: 'placed',
                                  child: Text('Placed')),
                              DropdownMenuItem(
                                  value: 'accepted',
                                  child: Text('Accepted')),
                              DropdownMenuItem(
                                  value: 'assigned',
                                  child: Text('Assigned')),
                              DropdownMenuItem(
                                  value: 'out_for_delivery',
                                  child:
                                      Text('Out for delivery')),
                              DropdownMenuItem(
                                  value: 'delivered',
                                  child: Text('Delivered')),
                              DropdownMenuItem(
                                  value: 'cancelled',
                                  child: Text('Cancelled')),
                            ],
                            onChanged: (v) =>
                                setState(() => _statusFilter = v!),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      /// ================= TABLE =================
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                                color:
                                    const Color(0xFFE5E7EB)),
                            borderRadius:
                                BorderRadius.circular(6),
                          ),
                          child: visibleOrders.isEmpty
                              ? const Center(
                                  child:
                                      Text('No orders found'),
                                )
                              : SingleChildScrollView(
                                  child: DataTable(
                                    columnSpacing: 24,
                                    headingRowColor:
                                        MaterialStateProperty.all(
                                      const Color(0xFFF9FAFB),
                                    ),
                                    columns: const [
                                      DataColumn(
                                          label:
                                              Text('Order ID')),
                                      DataColumn(
                                          label:
                                              Text('Customer')),
                                      DataColumn(
                                          label:
                                              Text('Amount')),
                                      DataColumn(
                                          label:
                                              Text('Payment')),
                                      DataColumn(
                                          label:
                                              Text('Status')),
                                      DataColumn(
                                          label:
                                              Text('Delivery')),
                                      DataColumn(
                                          label:
                                              Text('Actions')),
                                    ],
                                    rows: visibleOrders
                                        .map((order) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(
                                            order.id.substring(
                                                order.id.length -
                                                    6),
                                          )),
                                          DataCell(Text(
                                              order.customerName)),
                                          DataCell(Text(
                                            '₹${order.totalPrice.toStringAsFixed(0)}',
                                          )),
                                          DataCell(
                                            Text(
                                              order.paymentStatus
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                fontWeight:
                                                    FontWeight.w600,
                                                color: order
                                                            .paymentStatus ==
                                                        'paid'
                                                    ? Colors.green
                                                    : Colors.orange,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            _StatusChip(
                                                order.status),
                                          ),
                                          DataCell(Text(
                                            order.deliveryBoyName ??
                                                'Not assigned',
                                          )),
                                          DataCell(
                                            Row(
                                              children: [
                                                if (order.status ==
                                                    'placed')
                                                  TextButton(
                                                    onPressed:
                                                        () async {
                                                      await provider
                                                          .acceptOrder(
                                                              order
                                                                  .id);
                                                      await provider
                                                          .fetchOrders();
                                                      _resetFilter();
                                                    },
                                                    child: const Text(
                                                        'Accept'),
                                                  ),
                                                if (order.status ==
                                                    'accepted')
                                                  TextButton(
                                                    onPressed:
                                                        () =>
                                                            _showAssignDialog(
                                                      context,
                                                      provider,
                                                      order.id,
                                                    ),
                                                    child: const Text(
                                                        'Assign'),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  /// ================= ASSIGN DELIVERY =================
  Future<void> _showAssignDialog(
    BuildContext context,
    OrderProvider provider,
    String orderId,
  ) async {
    final boys = await _fetchDeliveryBoys();
    DeliveryBoy? selected;

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Assign Delivery Boy'),
              content: boys.isEmpty
                  ? const Text('No delivery boys available')
                  : DropdownButton<DeliveryBoy>(
                      isExpanded: true,
                      value: selected,
                      hint:
                          const Text('Select delivery boy'),
                      items: boys
                          .map(
                            (b) => DropdownMenuItem(
                              value: b,
                              child:
                                  Text('${b.name} (${b.phone})'),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selected = val),
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selected == null
                      ? null
                      : () async {
                          await provider.assignDeliveryBoy(
                              orderId, selected!.id);
                          await provider.fetchOrders();
                          _resetFilter();
                          if (context.mounted)
                            Navigator.pop(context);
                        },
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<DeliveryBoy>> _fetchDeliveryBoys() async {
    final res = await http.get(
      Uri.parse(
          'https://naturalfruitveg.com/api/delivery-boys?onlyAvailable=true'),
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => DeliveryBoy.fromJson(e)).toList();
    }
    return [];
  }
}

/// ================= STATUS CHIP =================
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'placed':
        color = Colors.grey;
        break;
      case 'accepted':
        color = Colors.blue;
        break;
      case 'assigned':
      case 'out_for_delivery':
        color = Colors.orange;
        break;
      case 'delivered':
        color = Colors.green;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
