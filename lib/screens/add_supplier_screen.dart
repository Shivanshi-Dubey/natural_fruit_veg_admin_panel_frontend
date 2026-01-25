import 'package:flutter/material.dart';
import '../layouts/admin_layout.dart';

class AddSupplierScreen extends StatefulWidget {
  const AddSupplierScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Add Supplier',
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
                    label: const Text('Save Supplier'),
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

  // ================= SAVE (UI ONLY) =================
  void _saveSupplier() {
    if (!_formKey.currentState!.validate()) return;

    // 🚧 Backend integration will come later
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Supplier saved (UI only)'),
      ),
    );

    Navigator.pop(context);
  }

  // ================= UI HELPERS =================

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
          ? (v) => v == null || v.isEmpty ? 'Required' : null
          : null,
    );
  }
}
