import 'package:flutter/material.dart';
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

  late String _name;
  late double _price;
  late String _imagePath;
  late String _category;
  late int _stock; // ✅ STOCK, not quantity

  @override
  void initState() {
    super.initState();
    _name = widget.product?.name ?? '';
    _price = widget.product?.price ?? 0;
    _imagePath = widget.product?.imagePath ?? '';
    _category = widget.product?.category ?? '';
    _stock = widget.product?.stock ?? 10;
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final product = Product(
      id: widget.product?.id ?? '',
      name: _name,
      price: _price,
      imagePath: _imagePath,
      category: _category,
      stock: _stock, // ✅ correct
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
    return Scaffold(
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
              _field('Price', _price.toString(),
                  (v) => _price = double.parse(v!), isNumber: true),
              _field('Image URL', _imagePath, (v) => _imagePath = v!),
              _field('Category', _category, (v) => _category = v!),
              _field('Stock', _stock.toString(),
                  (v) => _stock = int.parse(v!), isNumber: true),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveForm,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text(widget.product == null ? 'Add Product' : 'Update'),
              ),
            ],
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
