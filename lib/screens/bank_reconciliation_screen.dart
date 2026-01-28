import 'package:flutter/material.dart';
import '../../layouts/admin_layout.dart';

class BankReconciliationScreen extends StatelessWidget {
  const BankReconciliationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminLayout(
      title: 'Bank Reconciliation',
      child: Center(
        child: Text(
          'Bank Reconciliation\n(Coming Next Phase)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
