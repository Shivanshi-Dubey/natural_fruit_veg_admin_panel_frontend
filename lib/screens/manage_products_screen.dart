import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import 'add_product_screen.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch products when screen loads
    Future.microtask(() =>
        Provider.of<ProductProvider>(context, listen: false).fetchProducts());
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        backgroundColor: Colors.green,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.errorMessage != null
              ? Center(child: Text(provider.errorMessage!))
              : RefreshIndicator(
                  onRefresh: () => provider.fetchProducts(),
                  child: ListView.builder(
                    itemCount: provider.products.length,
                    itemBuilder: (context, index) {
                      final Product product = provider.products[index];

                      // ✅ STOCK is the source of truth
                      final bool isOutOfStock = product.stock <= 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        elevation: 2,
                        child: ListTile(
                          leading: Image.network(
                            product.imagePath.isNotEmpty
                                ? product.imagePath
                                : 'https://via.placeholder.com/80',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '₹${product.price.toStringAsFixed(2)} • ${product.category}\n'
                            'Stock: ${product.stock}',
                            style: const TextStyle(fontSize: 13),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ✅ OUT OF STOCK TOGGLE (STOCK BASED)
                              Switch(
                                value: !isOutOfStock,
                                activeColor: Colors.green,
                                onChanged: (value) async {
                                  if (product.id.isEmpty) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('❌ Product ID is missing'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                    return;
                                  }

                                  final updatedProduct = product.copyWith(
                                    stock: value ? 10 : 0, // ✅ change stock
                                  );

                                  await provider.updateProduct(
                                    updatedProduct,
                                    context,
                                  );
                                },
                              ),

                              // ✏️ EDIT
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AddProductScreen(product: product),
                                    ),
                                  );
                                },
                              ),

                              // ❌ DELETE
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  if (product.id.isEmpty) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('❌ Product ID is missing'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                    return;
                                  }
                                  await provider.deleteProduct(
                                    product.id,
                                    context,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddProductScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
