import 'package:flutter/material.dart';
import '../layouts/admin_layout.dart';
import '../models/order_model.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final TextEditingController nameController = TextEditingController();

  List<OrderItem> items = [];

  final TextEditingController itemName = TextEditingController();
  final TextEditingController price = TextEditingController();
  final TextEditingController qty = TextEditingController();

  // ✅ ADD ITEM
  void addItem() {
    if (itemName.text.isEmpty ||
        price.text.isEmpty ||
        qty.text.isEmpty) return;

    setState(() {
      items.add(
        OrderItem(
          name: itemName.text,
          price: double.parse(price.text),
          quantity: int.parse(qty.text),
        ),
      );
    });

    itemName.clear();
    price.clear();
    qty.clear();
  }

  // ✅ TOTAL
  double get total =>
      items.fold(0, (sum, i) => sum + i.price * i.quantity);

  // ✅ SAVE ORDER
  void saveOrder() {
    if (items.isEmpty) return;

    final order = Order(
      id: "ORD${DateTime.now().millisecondsSinceEpoch}",
      customerName:
          nameController.text.isEmpty ? "Walk-in Customer" : nameController.text,
      items: items,
      deliveryCharge: 0,
      handlingCharge: 0,
      grandTotal: total,
      orderStatus: "completed",
      returnStatus: "none",
      paymentMethod: "cash",
      paymentStatus: "paid",
      cashDepositedToAdmin: true,
      createdAt: DateTime.now(),
    );

    // 👉 TODO: Save to Provider / Backend

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Order Created Successfully")),
    );

    setState(() {
      items.clear();
      nameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: "Create Order",
      showBack: true,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // CUSTOMER NAME
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Customer Name (Optional)",
              ),
            ),

            const SizedBox(height: 20),

            // ADD ITEM
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: itemName,
                    decoration: const InputDecoration(labelText: "Item"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Price"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: qty,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Qty"),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: addItem,
                )
              ],
            ),

            const SizedBox(height: 20),

            // ITEMS LIST
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final item = items[i];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text("Qty: ${item.quantity}"),
                    trailing:
                        Text("₹${item.price * item.quantity}"),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // TOTAL
            Text(
              "Total: ₹$total",
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            // SAVE BUTTON
            ElevatedButton(
              onPressed: saveOrder,
              child: const Text("Save Order"),
            ),
          ],
        ),
      ),
    );
  }
}