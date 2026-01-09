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
  final FocusNode _pageFocus = FocusNode();

  late String _name;
  late double _price;
  late double _mrp;
  late String _unit;
  late String _imagePath;
  late String _category;
  late int _stock;

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
    _pageFocus.dispose();
    _priceCtrl.dispose();
    _mrpCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  /* =========================
     💾 SAVE FORM
  ========================= */
  Future<void> _saveForm() async {
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
     ⌨️ GLOBAL KEY HANDLER
  ========================= */
  void _handleKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.pop(context);
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        (event.isControlPressed &&
            event.logicalKey == LogicalKeyboardKey.keyS)) {
      _saveForm();
    }
  }

  /* =========================
     🔢 NUMERIC CONTROL
  ========================= */
  void _numericAdjust(
      RawKeyEvent e,
      TextEditingController ctrl,
      void Function(num) onChanged,
      {num step = 1}) {
    if (e is! RawKeyDownEvent) return;

    num value = num.tryParse(ctrl.text) ?? 0;

    if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
      value += e.isControlPressed ? step * 10 : step;
    }

    if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
      value -= e.isControlPressed ? step * 10 : step;
      if (value < 0) value = 0;
    }

    ctrl.text = value.toString();
    onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _pageFocus,
      autofocus: true,
      onKey: _handleKey,
      child: Scaffold(
        appBar: AppBar(
          title:
              Text(widget.product == null ? 'Add Product' : 'Edit Product'),
          backgroundColor: Colors.green,
        ),
        body: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.all(24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _textField('Product Name', _name,
                            (v) => _name = v!),

                        _numericField(
                          'Selling Price',
                          _priceCtrl,
                          (v) => _price = v.toDouble(),
                        ),

                        _numericField(
                          'MRP',
                          _mrpCtrl,
                          (v) => _mrp = v.toDouble(),
                        ),

                        _textField(
                          'Unit (250 g / 1 kg / 6 pcs)',
                          _unit,
                          (v) => _unit = v!,
                        ),

                        _textField(
                          'Image URL',
                          _imagePath,
                          (v) => _imagePath = v!,
                        ),

                        _textField(
                          'Category',
                          _category,
                          (v) => _category = v!,
                        ),

                        _numericField(
                          'Stock',
                          _stockCtrl,
                          (v) => _stock = v.toInt(),
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _saveForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              widget.product == null
                                  ? 'Add Product'
                                  : 'Update Product',
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
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

  Widget _numericField(
      String label,
      TextEditingController ctrl,
      Function(num) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (e) => _numericAdjust(e, ctrl, onChanged),
        child: TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
          decoration: InputDecoration(
            labelText: '$label (↑ ↓ | Ctrl+↑ ↓)',
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }
}
