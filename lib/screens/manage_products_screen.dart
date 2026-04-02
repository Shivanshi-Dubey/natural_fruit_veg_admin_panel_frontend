import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import 'add_product_screen.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await context.read<ProductProvider>().fetchProducts();
      _resetFilter();
    });
  }

  void _resetFilter() {
    final products = context.read<ProductProvider>().products;
    setState(() => _filteredProducts = products);
  }

  void _onSearch(String query) {
    final products = context.read<ProductProvider>().products;
    if (query.isEmpty) {
      setState(() => _filteredProducts = products);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filteredProducts = products.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();

    return AdminLayout(
      title: 'Products',
      onSearch: _onSearch,
      child: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? Center(child: Text(provider.errorMessage!))
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Header ──────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Product Inventory',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Product'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminLayout(
                                    title: 'Add Product',
                                    showBack: true,
                                    child: const AddProductScreen(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Table ────────────────────────────────────────
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: _filteredProducts.isEmpty
                              ? const Center(child: Text('No products found'))
                              : SingleChildScrollView(
                                  child: DataTable(
                                    columnSpacing: 24,
                                    headingRowColor:
                                        MaterialStateProperty.all(
                                      const Color(0xFFF9FAFB),
                                    ),
                                    columns: const [
                                      DataColumn(label: Text('Product')),
                                      DataColumn(label: Text('Price')),
                                      DataColumn(label: Text('Stock')),
                                      DataColumn(label: Text('Status')),
                                      DataColumn(label: Text('Actions')),
                                    ],
                                    rows: _filteredProducts.map((product) {
                                      final bool inStock = product.stock > 0;

                                      return DataRow(
                                        cells: [

                                          // ── Product ──────────────────
                                          DataCell(
                                            Row(
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child: Image.network(
                                                    product.imagePath.isNotEmpty
                                                        ? product.imagePath
                                                        : 'https://via.placeholder.com/40',
                                                    width: 40,
                                                    height: 40,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) =>
                                                        Container(
                                                      width: 40,
                                                      height: 40,
                                                      color: Colors.grey.shade100,
                                                      child: const Icon(
                                                          Icons.image_outlined,
                                                          size: 20,
                                                          color: Colors.grey),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      product.name,
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600),
                                                    ),
                                                    Text(
                                                      product.category,
                                                      style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          // ── Price ────────────────────
                                          DataCell(
                                            Text(
                                              '₹${product.price.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ),

                                          // ── Stock ────────────────────
                                          DataCell(
                                            Text(
                                              product.stock.toString(),
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: inStock
                                                    ? Colors.black87
                                                    : Colors.red,
                                              ),
                                            ),
                                          ),

                                          // ── Status Badge ─────────────
                                          DataCell(
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: inStock
                                                    ? Colors.green
                                                        .withOpacity(0.1)
                                                    : Colors.red
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                inStock
                                                    ? 'Active'
                                                    : 'Out of Stock',
                                                style: TextStyle(
                                                  color: inStock
                                                      ? Colors.green
                                                      : Colors.red,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),

                                          // ── Actions ──────────────────
                                          DataCell(
                                            Row(
                                              children: [

                                                // ✅ Mark OOS / Mark Active
                                                GestureDetector(
                                                  onTap: () async {
                                                    final newStock =
                                                        inStock ? 0 : 10;
                                                    await provider
                                                        .updateProductStock(
                                                      product.id,
                                                      newStock,
                                                    );
                                                    _resetFilter();
                                                  },
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                            horizontal: 8,
                                                            vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: inStock
                                                          ? Colors.orange.shade50
                                                          : Colors.green.shade50,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                      border: Border.all(
                                                        color: inStock
                                                            ? Colors
                                                                .orange.shade300
                                                            : Colors
                                                                .green.shade300,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      inStock
                                                          ? 'Mark OOS'
                                                          : 'Mark Active',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: inStock
                                                            ? Colors
                                                                .orange.shade700
                                                            : Colors
                                                                .green.shade700,
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                // Edit
                                                IconButton(
                                                  icon: const Icon(Icons.edit,
                                                      size: 18),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            AdminLayout(
                                                          title: 'Edit Product',
                                                          showBack: true,
                                                          child:
                                                              AddProductScreen(
                                                            product: product,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),

                                                // Delete
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete,
                                                    size: 18,
                                                    color: Colors.red,
                                                  ),
                                                  onPressed: () async {
                                                    final confirm =
                                                        await showDialog<bool>(
                                                      context: context,
                                                      builder: (_) =>
                                                          AlertDialog(
                                                        title: const Text(
                                                            'Delete Product'),
                                                        content: Text(
                                                            'Are you sure you want to delete "${product.name}"?'),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context,
                                                                    false),
                                                            child: const Text(
                                                                'Cancel'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context,
                                                                    true),
                                                            child: const Text(
                                                                'Delete',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .red)),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                    if (confirm == true) {
                                                      await provider
                                                          .deleteProduct(
                                                        product.id,
                                                        context,
                                                      );
                                                      _resetFilter();
                                                    }
                                                  },
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
}