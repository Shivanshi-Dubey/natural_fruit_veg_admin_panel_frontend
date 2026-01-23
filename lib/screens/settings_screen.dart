import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layouts/admin_layout.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return AdminLayout(
      title: 'Settings',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            /// ================= APPEARANCE =================
            _section(
              title: 'Appearance',
              child: SwitchListTile(
                title: const Text('Dark Mode'),
                value: themeProvider.isDarkMode,
                onChanged: themeProvider.toggleTheme,
                secondary: const Icon(Icons.dark_mode),
              ),
            ),

            /// ================= SECURITY =================
            _section(
              title: 'Security',
              child: ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change Password'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Change Password feature coming soon'),
                    ),
                  );
                },
              ),
            ),

            /// ================= ABOUT =================
            _section(
              title: 'About',
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About App'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('About App'),
                      content: const Text(
                        'Natural Fruits & Vegetables\n'
                        'Admin Panel\n\n'
                        'Version: 1.0.0\n'
                        'Developed with Flutter',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= SECTION WRAPPER =================
  Widget _section({
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }
}
