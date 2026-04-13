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
  String _selectedCategory = 'All';
  String _lastSearchQuery = '';

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
    _applyFilters(_lastSearchQuery, _selectedCategory, products);
  }

  List<String> _getCategories(List<Product> products) {
    final cats = products.map((p) => p.category).toSet().toList()..sort();
    return ['All', ...cats];
  }

  void _applyFilters(String query, String category, List<Product> all) {
    setState(() {
      _lastSearchQuery = query;
      _filteredProducts = all.where((p) {
        final matchSearch = query.isEmpty ||
            p.name.toLowerCase().contains(query.toLowerCase()) ||
            p.category.toLowerCase().contains(query.toLowerCase());
        final matchCat = category == 'All' || p.category == category;
        return matchSearch && matchCat;
      }).toList();
    });
  }

  void _onSearch(String query) {
    final products = context.read<ProductProvider>().products;
    _applyFilters(query, _selectedCategory, products);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final allProducts = provider.products;

    return AdminLayout(
      title: 'Items',
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
                            'Item Inventory',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Item'),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AdminLayout(
                                    title: 'Add Item',
                                    showBack: true,
                                    child: const AddProductScreen(),
                                  ),
                                ),
                              );
                              _resetFilter();
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // ── Category Filter Chips + Bulk OOS Toggle ──────
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            ..._getCategories(allProducts).map((cat) {
                              final isSelected = _selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedCategory = cat);
                                    _applyFilters(
                                        _lastSearchQuery, cat, allProducts);
                                  },
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF2E7D32)
                                          : Colors.grey.shade100,
                                      borderRadius:
                                          BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected
                                            ? const Color(0xFF2E7D32)
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      cat,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),

                            // Bulk OOS toggle — only when a category is selected
                            if (_selectedCategory != 'All') ...[
                              const SizedBox(width: 4),
                              _BulkOosButton(
                                category: _selectedCategory,
                                products: allProducts
                                    .where((p) =>
                                        p.category == _selectedCategory)
                                    .toList(),
                                provider: provider,
                                onDone: _resetFilter,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Product Count ────────────────────────────────
                      Text(
                        '${_filteredProducts.length} product${_filteredProducts.length == 1 ? '' : 's'} found',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Table ────────────────────────────────────────
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                                color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: _filteredProducts.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.inventory_2_outlined,
                                          size: 48,
                                          color: Colors.grey.shade300),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No Item found',
                                        style: TextStyle(
                                            color: Colors.grey.shade500),
                                      ),
                                      if (_selectedCategory != 'All') ...[
                                        const SizedBox(height: 8),
                                        TextButton(
                                          onPressed: () {
                                            setState(() =>
                                                _selectedCategory = 'All');
                                            _applyFilters(
                                                '', 'All', allProducts);
                                          },
                                          child: const Text('Clear filter'),
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    child: DataTable(
                                      columnSpacing: 24,
                                      headingRowColor:
                                          WidgetStateProperty.all(
                                        const Color(0xFFF9FAFB),
                                      ),
                                      columns: const [
                                        DataColumn(label: Text('Item')),
                                        DataColumn(label: Text('Category')),
                                        DataColumn(label: Text('Price')),
                                        DataColumn(label: Text('Stock')),
                                        DataColumn(label: Text('Status')),
                                        DataColumn(label: Text('Actions')),
                                      ],
                                      rows: _filteredProducts
                                          .map((product) {
                                        final bool inStock =
                                            product.stock > 0;

                                        return DataRow(
                                          cells: [

                                            // ── Product ────────────────
                                            DataCell(
                                              Row(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(6),
                                                    child: Image.network(
                                                      product.imagePath
                                                              .isNotEmpty
                                                          ? product.imagePath
                                                          : 'https://via.placeholder.com/40',
                                                      width: 40,
                                                      height: 40,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_,
                                                              __,
                                                              ___) =>
                                                          Container(
                                                        width: 40,
                                                        height: 40,
                                                        color: Colors
                                                            .grey.shade100,
                                                        child: const Icon(
                                                          Icons.image_outlined,
                                                          size: 20,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    product.name,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // ── Category ───────────────
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue
                                                      .withOpacity(0.08),
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(4),
                                                ),
                                                child: Text(
                                                  product.category,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.blue,
                                                    fontWeight:
                                                        FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // ── Price ──────────────────
                                            DataCell(
                                              Text(
                                                '₹${product.price.toStringAsFixed(0)}',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            ),

                                            // ── Stock ──────────────────
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

                                            // ── Status Badge ───────────
                                            DataCell(
                                              Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: inStock
                                                      ? Colors.green
                                                          .withOpacity(0.1)
                                                      : Colors.red
                                                          .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius
                                                          .circular(4),
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
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // ── Actions ────────────────
                                            DataCell(
                                              Row(
                                                children: [

                                                  // Mark OOS / Mark Active
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
                                                      decoration:
                                                          BoxDecoration(
                                                        color: inStock
                                                            ? Colors.orange
                                                                .shade50
                                                            : Colors.green
                                                                .shade50,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                        border: Border.all(
                                                          color: inStock
                                                              ? Colors.orange
                                                                  .shade300
                                                              : Colors.green
                                                                  .shade300,
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
                                                              ? Colors.orange
                                                                  .shade700
                                                              : Colors.green
                                                                  .shade700,
                                                        ),
                                                      ),
                                                    ),
                                                  ),

                                                  // Edit
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.edit,
                                                        size: 18),
                                                    onPressed: () async {
                                                      await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              AdminLayout(
                                                            title:
                                                                'Edit Item',
                                                            showBack: true,
                                                            child:
                                                                AddProductScreen(
                                                              product:
                                                                  product,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                      _resetFilter();
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
                                                              'Delete Item'),
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
                                                              child:
                                                                  const Text(
                                                                'Delete',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .red),
                                                              ),
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
                      ),
                    ],
                  ),
                ),
    );
  }
}

// ── Bulk OOS / Active Button ─────────────────────────────────────────────────

class _BulkOosButton extends StatelessWidget {
  const _BulkOosButton({
    required this.category,
    required this.products,
    required this.provider,
    required this.onDone,
  });

  final String category;
  final List<Product> products;
  final ProductProvider provider;
  final VoidCallback onDone;

  bool get _allOutOfStock =>
      products.isNotEmpty && products.every((p) => p.stock == 0);

  Future<void> _toggle(BuildContext context) async {
    final makeOos = !_allOutOfStock;
    final newStock = makeOos ? 0 : 10;
    final label = makeOos ? 'Mark All OOS' : 'Mark All Active';
    final message = makeOos
        ? 'Set stock to 0 for all ${products.length} product(s) in "$category"?'
        : 'Restore stock (set to 10) for all ${products.length} product(s) in "$category"?';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(label),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              label,
              style: TextStyle(
                color: makeOos ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (final p in products) {
        await provider.updateProductStock(p.id, newStock);
      }
      onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final allOos = _allOutOfStock;
    return GestureDetector(
      onTap: () => _toggle(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color:
              allOos ? Colors.green.shade50 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: allOos
                ? Colors.green.shade300
                : Colors.orange.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              allOos
                  ? Icons.check_circle_outline
                  : Icons.block_outlined,
              size: 14,
              color: allOos
                  ? Colors.green.shade700
                  : Colors.orange.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              allOos ? 'Mark All Active' : 'Mark All OOS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: allOos
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}