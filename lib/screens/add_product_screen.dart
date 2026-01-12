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

  // Controllers
  late TextEditingController _priceCtrl;
  late TextEditingController _mrpCtrl;
  late TextEditingController _stockCtrl;

  // Fields
  String _name = '';
  String _description = ''; // ✅ subtitle / variety
  String _unit = '1 pc';
  String _imagePath = '';
  String _category = '';
  double _price = 0;
  double _mrp = 0;
  int _stock = 10;

  String? _priceError;

  @override
  void initState() {
    super.initState();

    if (widget.product != null) {
      final p = widget.product!;
      _name = p.name;
      _description = p.description;
      _price = p.price;
      _mrp = p.mrp;
      _unit = p.unit;
      _imagePath = p.imagePath;
      _category = p.category;
      _stock = p.stock;
    }

    _priceCtrl =
        TextEditingController(text: _price == 0 ? '' : _price.toStringAsFixed(0));
    _mrpCtrl =
        TextEditingController(text: _mrp == 0 ? '' : _mrp.toStringAsFixed(0));
    _stockCtrl = TextEditingController(text: _stock.toString());
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _mrpCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  /* =========================
     💾 SAVE
  ========================= */
  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_priceError != null) return;

    _formKey.currentState!.save();

    final discount =
        _mrp > _price ? (((_mrp - _price) / _mrp) * 100).round() : 0;

    final product = Product(
      id: widget.product?.id ?? '',
      name: _name,
      description: _description,
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
     🔍 PRICE VALIDATION
  ========================= */
  void _validatePrices() {
    if (_mrp > 0 && _price > _mrp) {
      _priceError = "Selling price cannot be greater than MRP";
    } else {
      _priceError = null;
    }
    setState(() {});
  }

  /* =========================
     UI
  ========================= */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Card(
              margin: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _textField("Product Name", _name, (v) => _name = v!),

                      _textField(
                        "Subtitle / Variety",
                        _description,
                        (v) => _description = v!,
                        required: false,
                      ),

                      _numericField(
                        label: "Selling Price",
                        controller: _priceCtrl,
                        errorText: _priceError,
                        onChanged: (v) {
                          _price = double.tryParse(v) ?? 0;
                          _validatePrices();
                        },
                      ),

                      _numericField(
                        label: "MRP",
                        controller: _mrpCtrl,
                        onChanged: (v) {
                          _mrp = double.tryParse(v) ?? 0;
                          _validatePrices();
                        },
                      ),

                      _textField("Unit (kg / pc / dozen)", _unit,
                          (v) => _unit = v!),

                      _textField("Image URL", _imagePath,
                          (v) => _imagePath = v!),

                      _textField("Category", _category,
                          (v) => _category = v!),

                      _numericField(
                        label: "Stock",
                        controller: _stockCtrl,
                        onChanged: (v) {
                          _stock = int.tryParse(v) ?? 0;
                        },
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
                                ? "Add Product"
                                : "Update Product",
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
    );
  }

  /* =========================
     FIELD HELPERS
  ========================= */
  Widget _textField(
    String label,
    String value,
    Function(String?) onSave, {
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: value,
        validator:
            required ? (v) => v == null || v.isEmpty ? "Required" : null : null,
        onSaved: onSave,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _numericField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    String? errorText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
        ],
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
