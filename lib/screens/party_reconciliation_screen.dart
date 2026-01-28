import 'package:flutter/material.dart';
import '../../layouts/admin_layout.dart';

class PartyReconciliationScreen extends StatelessWidget {
  const PartyReconciliationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminLayout(
      title: 'Party Reconciliation',
      child: Center(
        child: Text(
          'Party Reconciliation\n(Coming Next Phase)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
