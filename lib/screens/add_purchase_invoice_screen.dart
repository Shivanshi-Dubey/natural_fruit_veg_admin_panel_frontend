import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
import '../providers/supplier_provider.dart';
import '../providers/product_provider.dart';
import '../providers/purchase_invoice_provider.dart';
import '../models/product.dart';

class AddPurchaseInvoiceScreen extends StatefulWidget {
  const AddPurchaseInvoiceScreen({super.key});

  @override
  State<AddPurchaseInvoiceScreen> createState() =>
      _AddPurchaseInvoiceScreenState();
}

class _AddPurchaseInvoiceScreenState
    extends State<AddPurchaseInvoiceScreen> {
  String? selectedSupplier;
  final invoiceController = TextEditingController();

  final List<_InvoiceItem> items = [];

  double subtotal = 0;
  double tax = 0;
  double grandTotal = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<SupplierProvider>().fetchSuppliers();
      context.read<ProductProvider>().fetchProducts();
    });
  }

  void _recalculate() {
    subtotal = items.fold(
      0,
      (sum, i) => sum + (i.qty * i.price),
    );
    tax = subtotal * 0.05;
    grandTotal = subtotal + tax;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final suppliers = context.watch<SupplierProvider>().suppliers;
    final products = context.watch<ProductProvider>().products;

    return AdminLayout(
      title: 'Create Purchase Invoice',
      showBack: true,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            /// ===== SUPPLIER =====
            DropdownButtonFormField<String>(
              value: selectedSupplier,
              decoration: const InputDecoration(
                labelText: 'Supplier',
                border: OutlineInputBorder(),
              ),
              items: suppliers
                  .map(
                    (s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedSupplier = v),
            ),

            const SizedBox(height: 16),

            /// ===== INVOICE NUMBER =====
            TextField(
              controller: invoiceController,
              decoration: const InputDecoration(
                labelText: 'Invoice Number',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            /// ===== ITEMS =====
            const Text(
              'Items',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
              onPressed: () {
                setState(() {
                  items.add(_InvoiceItem());
                });
              },
            ),

            const SizedBox(height: 16),

            ...items.map((item) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      DropdownButtonFormField<Product>(
                        value: item.product,
                        decoration: const InputDecoration(
                          labelText: 'Product',
                        ),
                        items: products
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(p.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          item.product = v;
                          _recalculate();
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(labelText: 'Qty'),
                              onChanged: (v) {
                                item.qty = int.tryParse(v) ?? 0;
                                _recalculate();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Purchase Price'),
                              onChanged: (v) {
                                item.price = double.tryParse(v) ?? 0;
                                _recalculate();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            /// ===== TOTALS =====
            Text('Subtotal: ₹${subtotal.toStringAsFixed(2)}'),
            Text('Tax (5%): ₹${tax.toStringAsFixed(2)}'),
            Text(
              'Grand Total: ₹${grandTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            /// ===== SAVE =====
            ElevatedButton(
              onPressed: () async {
                await context
                    .read<PurchaseInvoiceProvider>()
                    .createInvoice(
                      supplierId: selectedSupplier!,
                      invoiceNumber: invoiceController.text,
                      items: items.map((i) => i.toMap()).toList(),
                      subtotal: subtotal,
                      tax: tax,
                      grandTotal: grandTotal,
                    );

                Navigator.pop(context);
              },
              child: const Text('Save Invoice'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= HELPER =================

class _InvoiceItem {
  Product? product;
  int qty = 0;
  double price = 0;

  Map<String, dynamic> toMap() => {
        'product': product!.id,
        'quantity': qty,
        'purchasePrice': price,
        'total': qty * price,
      };
}
