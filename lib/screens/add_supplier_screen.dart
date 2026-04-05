import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
import '../providers/supplier_provider.dart';
import '../models/supplier_model.dart';

class AddSupplierScreen extends StatefulWidget {
  final Supplier? supplier; // ✅ for edit mode

  const AddSupplierScreen({
    super.key,
    this.supplier,
  });

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController addressCtrl = TextEditingController();
  final TextEditingController gstCtrl = TextEditingController();

  bool isActive = true;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();

    // ✅ Prefill if editing
    if (widget.supplier != null) {
      nameCtrl.text = widget.supplier!.name;
      phoneCtrl.text = widget.supplier!.phone;
      emailCtrl.text = widget.supplier!.email;
      addressCtrl.text = widget.supplier!.address;
      gstCtrl.text = widget.supplier!.gstNumber;
      isActive = widget.supplier!.isActive;
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: widget.supplier == null ? 'Add Supplier' : 'Edit Supplier',
      showBack: true,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              /// ================= BASIC INFO =================
              _sectionTitle('Supplier Information'),

              _textField(
                controller: nameCtrl,
                label: 'Supplier Name',
                required: true,
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _textField(
                      controller: phoneCtrl,
                      label: 'Phone Number',
                      keyboard: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _textField(
                      controller: emailCtrl,
                      label: 'Email',
                      keyboard: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _textField(
                controller: addressCtrl,
                label: 'Address',
                maxLines: 3,
              ),

              const SizedBox(height: 16),

              _textField(
                controller: gstCtrl,
                label: 'GST Number (optional)',
              ),

              const SizedBox(height: 24),

              /// ================= STATUS =================
              _sectionTitle('Status'),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active Supplier'),
                subtitle: const Text(
                  'Inactive suppliers cannot be used in purchases',
                ),
                value: isActive,
                onChanged: (v) => setState(() => isActive = v),
              ),

              const SizedBox(height: 32),

              /// ================= ACTIONS =================
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: Text(
                      widget.supplier == null
                          ? 'Save Supplier'
                          : 'Update Supplier',
                    ),
                    onPressed: _saveSupplier,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= SAVE =================
  Future<void> _saveSupplier() async {
    if (!_formKey.currentState!.validate()) return;

    final supplier = Supplier(
      id: widget.supplier?.id ?? '',
      name: nameCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      address: addressCtrl.text.trim(),
      gstNumber: gstCtrl.text.trim(),
      isActive: isActive,
      createdAt: widget.supplier?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.supplier == null) {
        // ➕ ADD
        await context.read<SupplierProvider>().addSupplier(supplier, context);
      } else {
        // ✏️ UPDATE
        await context.read<SupplierProvider>().updateSupplier(supplier, context);
      }

      // ✅ Success Message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.supplier == null
                ? "Supplier Added Successfully"
                : "Supplier Updated Successfully",
          ),
        ),
      );

      Navigator.pop(context); // go back

    } catch (e) {
      // ❌ Error Handling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  // ================= HELPERS =================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboard = TextInputType.text,
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
          : null,
    );
  }
}