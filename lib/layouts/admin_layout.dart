import 'package:flutter/material.dart';

import '../screens/dashboard_screen.dart';
import '../screens/products_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/customers_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;
  final String title;

  const AdminLayout({
    super.key,
    required this.child,
    required this.title,
  });

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
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
                const SizedBox(height: 32),

                _menuItem(
                  context,
                  Icons.dashboard,
                  'Dashboard',
                  const DashboardScreen(),
                ),
                _menuItem(
                  context,
                  Icons.inventory_2,
                  'Products',
                  const ProductsScreen(),
                ),
                _menuItem(
                  context,
                  Icons.shopping_cart,
                  'Orders',
                  const OrdersScreen(),
                ),
                _menuItem(
                  context,
                  Icons.people,
                  'Customers',
                  const CustomersScreen(),
                ),
                _menuItem(
                  context,
                  Icons.bar_chart,
                  'Reports',
                  const ReportsScreen(),
                ),
                _menuItem(
                  context,
                  Icons.settings,
                  'Settings',
                  const SettingsScreen(),
                ),

                const Spacer(),

                _menuItem(
                  context,
                  Icons.logout,
                  'Logout',
                  const DashboardScreen(), // change later if needed
                ),

                const SizedBox(height: 20),
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
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const CircleAvatar(
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

  // ================= MENU ITEM =================
  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String label,
    Widget screen,
  ) {
    final bool active = title == label;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1E293B) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 20),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        onTap: () {
          if (!active) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => screen),
            );
          }
        },
      ),
    );
  }
}
