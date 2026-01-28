import 'package:flutter/material.dart';
import '../../layouts/admin_layout.dart';

class ContraVoucherListScreen extends StatelessWidget {
  const ContraVoucherListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminLayout(
      title: 'Contra Voucher List',
      child: Center(
        child: Text(
          'Contra Voucher List\n(Coming Next Phase)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
