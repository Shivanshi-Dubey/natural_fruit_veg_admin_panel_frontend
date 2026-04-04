import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../layouts/admin_layout.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen>
    with SingleTickerProviderStateMixin {
  static const String baseUrl = "https://naturalfruitveg.com/api";

  List<dynamic> allProducts = [];
  bool isLoading = true;
  String searchQuery = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse("$baseUrl/products"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          allProducts = data is List ? data : (data['products'] ?? []);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  List<dynamic> get filteredProducts {
    List<dynamic> list = allProducts;
    if (searchQuery.isNotEmpty) {
      list = list
          .where((p) => (p['name'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchQuery.toLowerCase()))
          .toList();
    }
    return list;
  }

  // ✅ TASK 4: All products
  List<dynamic> get allFiltered => filteredProducts;

  // ✅ TASK 4: Low stock (stock between 1–5)
  List<dynamic> get lowStockProducts => filteredProducts
      .where((p) => (p['stock'] as num? ?? 0) > 0 && (p['stock'] as num? ?? 0) <= 5)
      .toList();

  // ✅ TASK 4: Zero stock products
  List<dynamic> get zeroStockProducts => filteredProducts
      .where((p) => (p['stock'] as num? ?? 0) <= 0)
      .toList();

  // Summary stats
  int get totalProducts => allProducts.length;
  int get inStockCount =>
      allProducts.where((p) => (p['stock'] as num? ?? 0) > 5).length;
  int get lowStockCount =>
      allProducts.where((p) {
        final s = (p['stock'] as num? ?? 0);
        return s > 0 && s <= 5;
      }).length;
  int get outOfStockCount =>
      allProducts.where((p) => (p['stock'] as num? ?? 0) <= 0).length;

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: "Stock Management",
      showBack: true,
      child: Column(
        children: [
          // ── Summary Cards ─────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _summaryCard("Total", totalProducts, Colors.blue),
                const SizedBox(width: 8),
                _summaryCard("In Stock", inStockCount, Colors.green),
                const SizedBox(width: 8),
                _summaryCard("Low", lowStockCount, Colors.orange),
                const SizedBox(width: 8),
                _summaryCard("Zero", outOfStockCount, Colors.red),
              ],
            ),
          ),

          // ── Search ───────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search products...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => searchQuery = v),
            ),
          ),

          // ── Tabs ─────────────────────────────────────────
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.green,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.green,
              tabs: [
                Tab(text: "All (${allFiltered.length})"),
                Tab(text: "Low (${lowStockProducts.length})"),
                Tab(text: "Zero (${zeroStockProducts.length})"),
              ],
            ),
          ),

          // ── Product List ─────────────────────────────────
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchProducts,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildProductList(allFiltered),
                        _buildProductList(lowStockProducts),
                        _buildProductList(zeroStockProducts),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(List<dynamic> products) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text("No products found",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final p = products[index];
        final stock = (p['stock'] as num? ?? 0).toInt();
        final stockColor = stock <= 0
            ? Colors.red
            : stock <= 5
                ? Colors.orange
                : Colors.green;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03), blurRadius: 4)
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: stockColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.inventory_2_outlined,
                  color: stockColor, size: 22),
            ),
            title: Text(
              p['name']?.toString() ?? '',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      "Buy: ₹${p['buyPrice'] ?? 0}",
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Sell: ₹${p['price'] ?? 0}",
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      p['unit']?.toString() ?? '',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                if ((p['supplierName'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    "Supplier: ${p['supplierName']}",
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: stockColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: stockColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    "$stock ${p['unit'] ?? ''}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: stockColor,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stock <= 0
                      ? "Out of Stock"
                      : stock <= 5
                          ? "Low Stock"
                          : "In Stock",
                  style: TextStyle(
                      fontSize: 10,
                      color: stockColor,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}