import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';
import 'customer_details_screen.dart';
import '../utils/csv_export.dart';


class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<OrderProvider>().orders;

    /// ================= BUILD CUSTOMER MAP =================
    final Map<String, _CustomerRow> customers = {};
for (final o in orders) {
  final key = o.customerName; // ✅ ONLY name

  if (!customers.containsKey(key)) {
    customers[key] = _CustomerRow(
      name: o.customerName,
      phone: '—', // phone not available
      totalOrders: 0,
      totalSpent: 0,
      lastStatus: o.status,
    );
  }

  customers[key]!.totalOrders += 1;
  customers[key]!.totalSpent += o.totalPrice;
  customers[key]!.lastStatus = o.status;
}


    /// ================= SEARCH FILTER =================
    final filtered = customers.values.where((c) {
      return c.name.toLowerCase().contains(_search) ||
          c.phone.toLowerCase().contains(_search);
    }).toList();

    return AdminLayout(
      title: 'Customers',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ================= HEADER =================
           Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      'Customer Management',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    ),
    Row(
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search name / phone',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              isDense: true,
            ),
            onChanged: (v) =>
                setState(() => _search = v.toLowerCase()),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.download),
          label: const Text('Export CSV'),
          onPressed: () {
            final rows = <List<String>>[
              ['Name', 'Phone', 'Total Orders', 'Total Spent', 'Last Status'],
              ...filtered.map((c) => [
                    c.name,
                    c.phone,
                    c.totalOrders.toString(),
                    c.totalSpent.toStringAsFixed(0),
                    c.lastStatus,
                  ]),
            ];

            CsvExport.downloadCsv(
              filename: 'customers.csv',
              rows: rows,
            );
          },
        ),
      ],
    ),
  ],
),


            const SizedBox(height: 16),

            /// ================= TABLE =================
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border:
                      Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor:
                        MaterialStateProperty.all(
                            const Color(0xFFF9FAFB)),
                    columns: const [
                      DataColumn(label: Text('Customer')),
                      DataColumn(label: Text('Phone')),
                      DataColumn(label: Text('Orders')),
                      DataColumn(label: Text('Total Spent')),
                      DataColumn(label: Text('Last Status')),
                    ],
                    rows: filtered.map((c) {
                      return DataRow(
  onSelectChanged: (_) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerDetailsScreen(
          customerName: c.name,
        ),
      ),
    );
  },
  cells: [
    DataCell(Text(
      c.name,
      style: const TextStyle(fontWeight: FontWeight.w600),
    )),
    DataCell(Text(c.phone)),
    DataCell(Text(c.totalOrders.toString())),
    DataCell(Text('₹${c.totalSpent.toStringAsFixed(0)}')),
    DataCell(_StatusChip(c.lastStatus)),
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
}

/// ================= CUSTOMER MODEL (UI ONLY) =================
class _CustomerRow {
  final String name;
  final String phone;
  int totalOrders;
  double totalSpent;
  String lastStatus;

  _CustomerRow({
    required this.name,
    required this.phone,
    required this.totalOrders,
    required this.totalSpent,
    required this.lastStatus,
  });
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
