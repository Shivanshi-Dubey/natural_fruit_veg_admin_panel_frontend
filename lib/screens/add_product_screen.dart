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
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

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

    final provider = Provider.of<ProductProvider>(context, listen: false);

    if (widget.product == null) {
      await provider.addProduct(product, context);
    } else {
      await provider.updateProduct(product, context);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent) {
          // ENTER → SAVE
          if (event.logicalKey == LogicalKeyboardKey.enter) {
            _saveForm();
          }

          // ESC → CANCEL / BACK
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.pop(context);
          }
        }
      },
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
                _field('Product Name', _name, (v) => _name = v!),
                _field(
                  'Selling Price',
                  _price.toString(),
                  (v) => _price = double.parse(v!),
                  isNumber: true,
                ),
                _field(
                  'MRP',
                  _mrp.toString(),
                  (v) => _mrp = double.parse(v!),
                  isNumber: true,
                ),
                _field(
                  'Unit (e.g. 250 g / 1 kg / 6 pcs)',
                  _unit,
                  (v) => _unit = v!,
                ),
                _field('Image URL', _imagePath, (v) => _imagePath = v!),
                _field('Category', _category, (v) => _category = v!),
                _field(
                  'Stock',
                  _stock.toString(),
                  (v) => _stock = int.parse(v!),
                  isNumber: true,
                ),
                const SizedBox(height: 24),

                // BUTTON STILL EXISTS (mouse users)
                ElevatedButton(
                  onPressed: _saveForm,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child:
                      Text(widget.product == null ? 'Add Product' : 'Update'),
                ),

                const SizedBox(height: 8),
                const Text(
                  "Tip: Press ENTER to save • ESC to cancel",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, String value, Function(String?) onSave,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: value,
        keyboardType:
            isNumber ? TextInputType.number : TextInputType.text,
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
        onSaved: onSave,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
