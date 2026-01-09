import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;
  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final FocusNode _focusNode = FocusNode();

  late String _name;
  late double _price;
  late double _mrp;
  late String _unit;
  late String _imagePath;
  late String _category;
  late int _stock;

  // Controllers for numeric keyboard handling
  late TextEditingController _priceCtrl;
  late TextEditingController _mrpCtrl;
  late TextEditingController _stockCtrl;

  @override
  void initState() {
    super.initState();
    _name = widget.product?.name ?? '';
    _price = widget.product?.price ?? 0;
    _mrp = widget.product?.mrp ?? 0;
    _unit = widget.product?.unit ?? '1 pc';
    _imagePath = widget.product?.imagePath ?? '';
    _category = widget.product?.category ?? '';
    _stock = widget.product?.stock ?? 10;

    _priceCtrl = TextEditingController(text: _price.toString());
    _mrpCtrl = TextEditingController(text: _mrp.toString());
    _stockCtrl = TextEditingController(text: _stock.toString());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _priceCtrl.dispose();
    _mrpCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  /* =========================
     💾 SAVE FORM
  ========================= */
  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final int discount =
        _mrp > _price ? (((_mrp - _price) / _mrp) * 100).round() : 0;

    final product = Product(
      id: widget.product?.id ?? '',
      name: _name,
      price: _price,
      mrp: _mrp,
      unit: _unit,
      discount: discount,
      imagePath: _imagePath,
      category: _category,
      stock: _stock,
    );

    final provider = context.read<ProductProvider>();

    widget.product == null
        ? await provider.addProduct(product, context)
        : await provider.updateProduct(product, context);

    if (mounted) Navigator.pop(context);
  }

  /* =========================
     ⌨️ KEYBOARD HANDLER
  ========================= */
  void _handleKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    // ESC → Cancel
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
    }

    // ENTER → Save
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _saveForm();
    }

    // CTRL + S → Save
    if (event.isControlPressed &&
        event.logicalKey == LogicalKeyboardKey.keyS) {
      _saveForm();
    }
  }

  /* =========================
     🔢 NUMERIC KEY CONTROL
  ========================= */
  void _handleNumericKey(
    RawKeyEvent event,
    TextEditingController controller,
    void Function(num) onChanged, {
    num step = 1,
  }) {
    if (event is! RawKeyDownEvent) return;

    num value = num.tryParse(controller.text) ?? 0;

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      value += event.isControlPressed ? step * 10 : step;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      value -= event.isControlPressed ? step * 10 : step;
      if (value < 0) value = 0;
    }

    controller.text = value.toString();
    onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: _handleKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
          backgroundColor: Colors.green,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _textField('Product Name', _name, (v) => _name = v!),

                _numericField(
                  label: 'Selling Price',
                  controller: _priceCtrl,
                  onChanged: (v) => _price = v.toDouble(),
                ),

                _numericField(
                  label: 'MRP',
                  controller: _mrpCtrl,
                  onChanged: (v) => _mrp = v.toDouble(),
                ),

                _textField('Unit (250 g / 1 kg / 6 pcs)', _unit,
                    (v) => _unit = v!),

                _textField('Image URL', _imagePath,
                    (v) => _imagePath = v!),

                _textField('Category', _category,
                    (v) => _category = v!),

                _numericField(
                  label: 'Stock',
                  controller: _stockCtrl,
                  onChanged: (v) => _stock = v.toInt(),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _saveForm,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green),
                  child: Text(widget.product == null ? 'Add Product' : 'Update'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /* =========================
     🧩 FIELD HELPERS
  ========================= */
  Widget _textField(
      String label, String value, Function(String?) onSave) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: value,
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        onSaved: onSave,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _numericField({
    required String label,
    required TextEditingController controller,
    required Function(num) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (e) =>
            _handleNumericKey(e, controller, onChanged),
        child: TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          decoration: InputDecoration(
            labelText: '$label (↑ ↓ | CTRL+↑ ↓)',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }
}
