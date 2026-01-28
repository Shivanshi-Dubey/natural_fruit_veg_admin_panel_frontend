import 'package:flutter/material.dart';
import '../../layouts/admin_layout.dart';

class BanksScreen extends StatelessWidget {
  const BanksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminLayout(
      title: 'Banks',
      child: Center(
        child: Text(
          'Banks Management\n(Coming Next Phase)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
