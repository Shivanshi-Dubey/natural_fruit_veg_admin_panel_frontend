import 'package:flutter/material.dart';
import '../../layouts/admin_layout.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminLayout(
      title: 'Payments List',
      child: Center(
        child: Text(
          'Payments List\n(Coming Next Phase)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
