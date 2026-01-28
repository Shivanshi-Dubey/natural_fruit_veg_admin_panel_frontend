import 'package:flutter/material.dart';
import '../../layouts/admin_layout.dart';

class ContraVoucherScreen extends StatelessWidget {
  const ContraVoucherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminLayout(
      title: 'Contra Voucher',
      showBack: true,
      child: Center(
        child: Text(
          'Create Contra Voucher\n(Coming Next Phase)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
