import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product; // For editing

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
  late int _quantity;

  @override
  void initState() {
    super.initState();
    _name = widget.product?.name ?? '';
    _price = widget.product?.price ?? 0.0;
    _imagePath = widget.product?.imagePath ?? '';
    _category = widget.product?.category ?? '';
    _quantity = widget.product?.quantity ?? 1;
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newProduct = Product(
        id: widget.product?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: _name,
        price: _price,
        imagePath: _imagePath,
        category: _category,
        quantity: _quantity,
      );

      final productProvider =
          Provider.of<ProductProvider>(context, listen: false);

      if (widget.product == null) {
        await productProvider.addProduct(newProduct, context);
      } else {
        await productProvider.updateProduct(newProduct, context);
      }

      if (mounted) Navigator.pop(context);
    }
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
              _buildTextField(
                label: 'Product Name',
                initialValue: _name,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter product name' : null,
                onSaved: (v) => _name = v!,
              ),
              _buildTextField(
                label: 'Price',
                initialValue: _price == 0 ? '' : _price.toString(),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter price' : null,
                onSaved: (v) => _price = double.parse(v!),
              ),
              _buildTextField(
                label: 'Image Path (URL)',
                initialValue: _imagePath,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter image path' : null,
                onSaved: (v) => _imagePath = v!,
              ),
              _buildTextField(
                label: 'Category',
                initialValue: _category,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter category' : null,
                onSaved: (v) => _category = v!,
              ),
              _buildTextField(
                label: 'Quantity',
                initialValue: _quantity.toString(),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Enter quantity' : null,
                onSaved: (v) => _quantity = int.parse(v!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  widget.product == null ? 'Add Product' : 'Update Product',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required FormFieldValidator<String> validator,
    required FormFieldSetter<String> onSaved,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: validator,
        onSaved: onSaved,
        keyboardType: keyboardType,
      ),
    );
  }
}
