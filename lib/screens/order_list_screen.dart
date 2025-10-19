import 'package:flutter/material.dart';

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders List'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Order list will appear here!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
