import 'package:flutter/material.dart';
import '../../layouts/admin_layout.dart';

class AddPaymentScreen extends StatelessWidget {
  const AddPaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminLayout(
      title: 'Add Payment',
      showBack: true,
      child: Center(
        child: Text(
          'Create Payment Screen\n(Coming Next Phase)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
