import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
import '../providers/purchase_invoice_provider.dart';

class CreatePurchaseInvoiceScreen extends StatefulWidget {
  const CreatePurchaseInvoiceScreen({super.key});

  @override
  State<CreatePurchaseInvoiceScreen> createState() =>
      _CreatePurchaseInvoiceScreenState();
}

class _CreatePurchaseInvoiceScreenState
    extends State<CreatePurchaseInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();

  final _invoiceCtrl = TextEditingController();
  final _supplierCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider =
        context.watch<PurchaseInvoiceProvider>();

    return AdminLayout(
      title: 'Create Purchase Invoice',
      showBack: true,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// INVOICE NUMBER
              _field(
                label: 'Invoice Number',
                controller: _invoiceCtrl,
              ),

              /// SUPPLIER NAME
              _field(
                label: 'Supplier Name',
                controller: _supplierCtrl,
              ),

              /// TOTAL AMOUNT
              _field(
                label: 'Total Amount',
                controller: _amountCtrl,
                keyboard: TextInputType.number,
              ),

              const SizedBox(height: 24),

              /// ACTIONS
              Row(
                children: [
                  ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () async {
                            if (!_formKey.currentState!
                                .validate()) return;

                            final success =
                                await provider.createInvoice(
                              invoiceNumber: _invoiceCtrl.text,
                              supplierName: _supplierCtrl.text,
                              totalAmount:
                                  double.parse(_amountCtrl.text),
                            );

                            if (success && mounted) {
                              Navigator.pop(context);
                            }
                          },
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Invoice'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: keyboard,
            validator: (v) =>
                v == null || v.isEmpty ? 'Required' : null,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
