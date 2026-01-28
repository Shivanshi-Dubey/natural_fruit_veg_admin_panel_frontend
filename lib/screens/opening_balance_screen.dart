import 'package:flutter/material.dart';
import '../../layouts/admin_layout.dart';

class OpeningBalanceScreen extends StatelessWidget {
  const OpeningBalanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminLayout(
      title: 'Opening Balance',
      child: Center(
        child: Text(
          'Opening Balance Setup\n(Coming Next Phase)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
