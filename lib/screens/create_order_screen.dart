import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() =>
      _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController itemName =
      TextEditingController();
  final TextEditingController price =
      TextEditingController();
  final TextEditingController qty =
      TextEditingController();

  List<OrderItem> items = [];
  DateTime selectedDate = DateTime.now();

  Future<void> pickDate() async {
  final picked = await showDatePicker(
    context: context,
    initialDate: selectedDate,
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );

  if (picked != null) {
    setState(() {
      selectedDate = picked;
    });
  }
}

  // ✅ ADD ITEM
  void addItem() {
    if (itemName.text.isEmpty ||
        price.text.isEmpty ||
        qty.text.isEmpty) return;

    setState(() {
      items.add(OrderItem(
        name: itemName.text,
        price: double.parse(price.text),
        quantity: int.parse(qty.text),
      ));
    });

    itemName.clear();
    price.clear();
    qty.clear();
  }

  // ✅ TOTAL
  double get total =>
      items.fold(0, (sum, i) => sum + i.price * i.quantity);

  // ✅ SAVE ORDER
  void saveOrder() async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add items first")),
      );
      return;
    }

    final order = {
      "customerName": nameController.text.isEmpty
          ? "Walk-in Customer"
          : nameController.text,
      "products": items.map((i) => {
            "name": i.name,
            "price": i.price,
            "quantity": i.quantity,
          }).toList(),
      "paymentMethod": "cash",
      "paymentStatus": "paid",
      "deliveryCharge": 0,
      "handlingCharge": 0,

       // 🔥 ADD THIS
  "createdAt": selectedDate.toIso8601String(),
    };

    await context.read<OrderProvider>().createOrder(order);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Order Created")),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: "Create Sale",
      showBack: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
              
              Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      "Date: ${selectedDate.toLocal().toString().split(' ')[0]}",
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    TextButton(
      onPressed: pickDate,
      child: const Text("Change"),
    )
  ],
),
            // 🔥 CUSTOMER SECTION
            _card(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Customer *",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 🔥 ADD ITEM SECTION
            _card(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: itemName,
                          decoration: const InputDecoration(
                            labelText: "Item",
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: price,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Price",
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: qty,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Qty",
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: Colors.green),
                        onPressed: addItem,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 🔥 ITEM LIST
                  if (items.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final item = items[i];
                        return ListTile(
                          title: Text(item.name),
                          subtitle:
                              Text("Qty: ${item.quantity}"),
                          trailing: Text(
                              "₹${item.price * item.quantity}"),
                        );
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 🔥 TOTAL SECTION
            _card(
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Amount",
                    style:
                        TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "₹${total.toStringAsFixed(0)}",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔥 SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveOrder,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.green,
                ),
                child: const Text(
                  "Save Sale",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 COMMON CARD WIDGET
  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
          )
        ],
      ),
      child: child,
    );
  }
}