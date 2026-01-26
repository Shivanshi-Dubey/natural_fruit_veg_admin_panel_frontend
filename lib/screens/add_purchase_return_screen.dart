import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../layouts/admin_layout.dart';

class AddPurchaseReturnScreen extends StatefulWidget {
  const AddPurchaseReturnScreen({super.key});

  @override
  State<AddPurchaseReturnScreen> createState() =>
      _AddPurchaseReturnScreenState();
}

class _AddPurchaseReturnScreenState
    extends State<AddPurchaseReturnScreen> {
  final _formKey = GlobalKey<FormState>();

  String supplierName = '';
  final List<Map<String, dynamic>> items = [];

  bool isSubmitting = false;

  void addItem() {
    setState(() {
      items.add({
        'productId': '',
        'quantity': 1,
      });
    });
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isSubmitting = true);

    await http.post(
      Uri.parse(
          'https://naturalfruitveg.com/api/admin/purchase-returns'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'supplierName': supplierName,
        'items': items,
      }),
    );

    setState(() => isSubmitting = false);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Purchase Return')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Supplier Name'),
                onSaved: (v) => supplierName = v!,
                validator: (v) =>
                    v!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 16),

              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    return Card(
                      child: ListTile(
                        title: TextFormField(
                          decoration: const InputDecoration(
                              labelText: 'Product ID'),
                          onSaved: (v) =>
                              items[i]['productId'] = v!,
                          validator: (v) =>
                              v!.isEmpty ? 'Required' : null,
                        ),
                        trailing: SizedBox(
                          width: 80,
                          child: TextFormField(
                            initialValue: '1',
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Qty'),
                            onSaved: (v) => items[i]['quantity'] =
                                int.parse(v!),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: isSubmitting ? null : submit,
                    child: isSubmitting
                        ? const CircularProgressIndicator()
                        : const Text('Save Return'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
