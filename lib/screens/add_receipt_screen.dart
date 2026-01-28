import 'package:flutter/material.dart';
import '../../layouts/admin_layout.dart';

class AddReceiptScreen extends StatelessWidget {
  const AddReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminLayout(
      title: 'Add Receipt',
      showBack: true,
      child: Center(
        child: Text(
          'Create Receipt Screen\n(Coming Next Phase)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
