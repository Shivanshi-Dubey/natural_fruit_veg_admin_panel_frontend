import 'package:flutter/material.dart';
import '../layouts/admin_layout.dart';

class GrnScreen extends StatelessWidget {
  const GrnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminLayout(
      title: 'GRN',
      child: Center(
        child: Text(
          'GRN Module (Coming Soon)',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
