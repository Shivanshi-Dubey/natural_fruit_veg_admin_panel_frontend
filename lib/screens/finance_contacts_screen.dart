import 'package:flutter/material.dart';
import '../../layouts/admin_layout.dart';

class FinanceContactsScreen extends StatelessWidget {
  const FinanceContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminLayout(
      title: 'Finance Contacts',
      child: Center(
        child: Text(
          'Contacts (Customers / Vendors)\n(Coming Next Phase)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
