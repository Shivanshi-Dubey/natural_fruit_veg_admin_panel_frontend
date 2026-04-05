import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../layouts/admin_layout.dart';
import '../providers/supplier_provider.dart';
import '../models/supplier_model.dart';

class AddSupplierScreen extends StatefulWidget {
  final Supplier? supplier;

  const AddSupplierScreen({super.key, this.supplier});

  @override
  State<AddSupplierScreen> createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen>
    with SingleTickerProviderStateMixin {

  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;

  // ── Controllers ─────────────────────────────────────────
  final nameCtrl        = TextEditingController();
  final gstCtrl         = TextEditingController();
  final phoneCtrl       = TextEditingController();
  final openingBalCtrl  = TextEditingController(text: '0.00');
  final creditLimitCtrl = TextEditingController(text: '0');

  // Address tab
  final addressCtrl     = TextEditingController();
  final cityCtrl        = TextEditingController();
  final pincodeCtrl     = TextEditingController();

  // GST Details tab
  final emailCtrl       = TextEditingController();

  // ── State ────────────────────────────────────────────────
  DateTime asOfDate        = DateTime.now();
  bool isToReceive         = false; // false = To Pay, true = To Receive
  bool setCreditLimit      = false;
  bool isActive            = true;
  String? selectedState;
  String gstType           = 'Unregistered/Consumer';

  static const _green = Color(0xFF2E7D32);

  final List<String> indianStates = [
    '01-Jammu & Kashmir', '02-Himachal Pradesh', '03-Punjab',
    '04-Chandigarh', '05-Uttarakhand', '06-Haryana', '07-Delhi',
    '08-Rajasthan', '09-Uttar Pradesh', '10-Bihar', '11-Sikkim',
    '12-Arunachal Pradesh', '13-Nagaland', '14-Manipur',
    '15-Mizoram', '16-Tripura', '17-Meghalaya', '18-Assam',
    '19-West Bengal', '20-Jharkhand', '21-Odisha', '22-Chhattisgarh',
    '23-Madhya Pradesh', '24-Gujarat', '25-Daman & Diu',
    '26-Dadra & Nagar Haveli', '27-Maharashtra', '28-Andhra Pradesh',
    '29-Karnataka', '30-Goa', '31-Lakshadweep', '32-Kerala',
    '33-Tamil Nadu', '34-Puducherry', '35-Andaman & Nicobar',
    '36-Telangana', '37-Andhra Pradesh (New)',
  ];

  final List<String> gstTypes = [
    'Unregistered/Consumer',
    'Registered Business - Regular',
    'Registered Business - Composition',
    'Consumer',
    'Overseas',
    'Special Economic Zone',
    'Deemed Export',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.supplier != null) {
      final s = widget.supplier!;
      nameCtrl.text       = s.name;
      phoneCtrl.text      = s.phone;
      emailCtrl.text      = s.email;
      addressCtrl.text    = s.address;
      gstCtrl.text        = s.gstNumber;
      isActive            = s.isActive;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    nameCtrl.dispose();
    gstCtrl.dispose();
    phoneCtrl.dispose();
    openingBalCtrl.dispose();
    creditLimitCtrl.dispose();
    addressCtrl.dispose();
    cityCtrl.dispose();
    pincodeCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: asOfDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => asOfDate = picked);
  }

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
        await context.read<SupplierProvider>().addSupplier(supplier, context);
      } else {
        await context.read<SupplierProvider>().updateSupplier(supplier, context);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.supplier == null
              ? "Supplier Added Successfully"
              : "Supplier Updated Successfully"),
          backgroundColor: _green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: widget.supplier == null ? 'Add New supplier' : 'Edit supplier',
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Party Name ──────────────────────────
                    _inputField(
                      controller: nameCtrl,
                      label: 'Supplier Name *',
                      required: true,
                    ),

                    const SizedBox(height: 14),

                    // ── GST IN ──────────────────────────────
                    _inputField(
                      controller: gstCtrl,
                      label: 'GST IN',
                    ),

                    const SizedBox(height: 14),

                    // ── Contact Number ──────────────────────
                    _inputField(
                      controller: phoneCtrl,
                      label: 'Contact Number',
                      keyboard: TextInputType.phone,
                    ),

                    const SizedBox(height: 14),

                    // ── Opening Balance + As Of Date ────────
                    Row(
                      children: [
                        Expanded(
                          child: _inputField(
                            controller: openingBalCtrl,
                            label: 'Opening Ba...',
                            keyboard: TextInputType.number,
                            suffix: const Icon(Icons.info_outline,
                                size: 16, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickDate,
                            child: AbsorbPointer(
                              child: _inputField(
                                controller: TextEditingController(
                                  text: DateFormat('dd/MM/yyyy')
                                      .format(asOfDate),
                                ),
                                label: 'As Of Date',
                                suffix: const Icon(Icons.calendar_today,
                                    size: 16, color: _green),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── To Receive / To Pay ─────────────────
                    Row(
                      children: [
                        _radioOption(
                          label: 'To Receive',
                          value: true,
                          groupValue: isToReceive,
                          onChanged: (v) =>
                              setState(() => isToReceive = v!),
                        ),
                        const SizedBox(width: 24),
                        _radioOption(
                          label: 'To Pay',
                          value: false,
                          groupValue: isToReceive,
                          onChanged: (v) =>
                              setState(() => isToReceive = v!),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ── Set Credit Limit ────────────────────
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(
                              () => setCreditLimit = !setCreditLimit),
                          child: Row(
                            children: [
                              Icon(
                                setCreditLimit
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: _green,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Set Credit Limit',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: _green),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.info_outline,
                            size: 16, color: Colors.grey),
                        const Icon(Icons.settings,
                            size: 16, color: Colors.grey),
                      ],
                    ),

                    if (setCreditLimit) ...[
                      const SizedBox(height: 10),
                      _inputField(
                        controller: creditLimitCtrl,
                        label: 'Credit Limit (₹)',
                        keyboard: TextInputType.number,
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Tabs: Address | GST Details ─────────
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                              color: Colors.grey.shade200),
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: _green,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: _green,
                        indicatorWeight: 2,
                        tabs: const [
                          Tab(text: 'Address'),
                          Tab(text: 'GST Details'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Tab Content ─────────────────────────
                    SizedBox(
                      height: 280,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Address Tab
                          Column(
                            children: [
                              _inputField(
                                controller: addressCtrl,
                                label: 'Billing Address',
                                maxLines: 3,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _inputField(
                                      controller: cityCtrl,
                                      label: 'City',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _inputField(
                                      controller: pincodeCtrl,
                                      label: 'Pincode',
                                      keyboard: TextInputType.number,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // State Dropdown
                              DropdownButtonFormField<String>(
                                value: selectedState,
                                decoration: InputDecoration(
                                  labelText: 'State',
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300),
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 14),
                                ),
                                hint: const Text('Select State'),
                                items: indianStates
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s,
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => selectedState = v),
                              ),
                            ],
                          ),

                          // GST Details Tab
                          Column(
                            children: [
                              // GST Type dropdown
                              DropdownButtonFormField<String>(
                                value: gstType,
                                decoration: InputDecoration(
                                  labelText: 'GST Type',
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300),
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 14),
                                ),
                                items: gstTypes
                                    .map((t) => DropdownMenuItem(
                                          value: t,
                                          child: Text(t,
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => gstType = v!),
                              ),
                              const SizedBox(height: 12),
                              // State dropdown (same in GST tab)
                              DropdownButtonFormField<String>(
                                value: selectedState,
                                decoration: InputDecoration(
                                  labelText: 'State',
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: Colors.grey.shade300),
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 14),
                                ),
                                hint: const Text('Select State'),
                                items: indianStates
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s,
                                              style: const TextStyle(
                                                  fontSize: 13)),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => selectedState = v),
                              ),
                              const SizedBox(height: 12),
                              _inputField(
                                controller: emailCtrl,
                                label: 'Email',
                                keyboard: TextInputType.emailAddress,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // ── Save Party Button ───────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveSupplier,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    widget.supplier == null
                        ? 'Save Supplier'
                        : 'Update Supplier',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  // ── Helpers ───────────────────────────────────────────────

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboard = TextInputType.text,
    bool required = false,
    int maxLines = 1,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _green),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
          : null,
    );
  }

  Widget _radioOption({
    required String label,
    required bool value,
    required bool groupValue,
    required void Function(bool?) onChanged,
  }) {
    return Row(
      children: [
        Radio<bool>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor: _green,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Text(label,
            style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
