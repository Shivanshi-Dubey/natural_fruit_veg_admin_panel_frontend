import 'package:flutter/material.dart';

import '../screens/dashboard_screen.dart';
import '../screens/manage_products_screen.dart';
import '../screens/manage_orders_screen.dart';
import '../screens/add_product_screen.dart';
import '../screens/customers_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final bool showBack;

  const AdminLayout({
    super.key,
    required this.child,
    required this.title,
    this.showBack = false,
  });

  void _navigate(BuildContext context, Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // ================= SIDEBAR =================
          Container(
            width: 260,
            color: const Color(0xFF0F172A),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _menuItem(
                  context,
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  screen: const DashboardScreen(),
                ),

                _sectionTitle('Sales'),
                _expandableSection(
                  icon: Icons.shopping_cart,
                  title: 'Orders',
                  children: [
                    _subMenuItem(
                      context,
                      'All Orders',
                      const ManageOrdersScreen(),
                    ),
                  ],
                ),

                _sectionTitle('Products'),
                _expandableSection(
                  icon: Icons.inventory,
                  title: 'Products',
                  children: [
                    _subMenuItem(
                      context,
                      'All Products',
                      const ManageProductsScreen(),
                    ),
                    _subMenuItem(
                      context,
                      'Add Product',
                      const AddProductScreen(),
                    ),
                  ],
                ),

                _sectionTitle('Customers'),
                _menuItem(
                  context,
                  icon: Icons.people,
                  label: 'Customers',
                  screen: const CustomersScreen(),
                ),

                _sectionTitle('Reports'),
                _menuItem(
                  context,
                  icon: Icons.bar_chart,
                  label: 'Reports',
                  screen: const ReportsScreen(),
                ),

                _sectionTitle('Settings'),
                _menuItem(
                  context,
                  icon: Icons.settings,
                  label: 'Settings',
                  screen: const SettingsScreen(),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),

          // ================= MAIN CONTENT =================
          Expanded(
            child: Column(
              children: [
                // ---------- TOP BAR ----------
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (showBack)
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () => Navigator.pop(context),
                            ),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const CircleAvatar(
                        radius: 18,
                        child: Icon(Icons.person),
                      ),
                    ],
                  ),
                ),

                // ---------- PAGE ----------
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= UI HELPERS =================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Widget screen,
  }) {
    final bool active = title == label;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1E293B) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 20),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        onTap: () {
          if (!active) _navigate(context, screen);
        },
      ),
    );
  }

  Widget _expandableSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Theme(
      data: ThemeData.dark().copyWith(
        dividerColor: Colors.transparent,
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.white, size: 20),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white54,
        children: children,
      ),
    );
  }

  Widget _subMenuItem(
    BuildContext context,
    String label,
    Widget screen,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 14),
      ),
      onTap: () => _navigate(context, screen),
    );
  }
}
