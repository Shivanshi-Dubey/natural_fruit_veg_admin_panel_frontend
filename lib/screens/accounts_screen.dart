import 'package:flutter/material.dart';
import '../layouts/admin_layout.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminLayout(
      title: 'Accounts',
      child: Center(
        child: Text(
          'Accounts Master\n(Coming next phase)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
