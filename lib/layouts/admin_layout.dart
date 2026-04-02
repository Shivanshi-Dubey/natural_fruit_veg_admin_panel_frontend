import 'package:flutter/material.dart';

import '../screens/dashboard_screen.dart';
import '../screens/manage_products_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/returns_screen.dart';
import '../screens/cash_collection_screen.dart';
import '../screens/add_product_screen.dart';
import '../screens/customers_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';

// 🔹 Purchase & Inventory
import '../screens/suppliers_screen.dart';
import '../screens/purchase_invoices_screen.dart';
import '../screens/purchase_returns_screen.dart';
import '../screens/grn_screen.dart';
import '../screens/expenses_screen.dart';
import '../screens/accounts_screen.dart';
import '../screens/banks_screen.dart';
import '../screens/opening_balance_screen.dart';
import '../screens/add_receipt_screen.dart';
import '../screens/receipts_screen.dart';
import '../screens/add_payment_screen.dart';
import '../screens/payments_screen.dart';
import '../screens/contra_voucher_screen.dart';
import '../screens/contra_voucher_list_screen.dart';
import '../screens/bank_reconciliation_screen.dart';
import '../screens/party_reconciliation_screen.dart';
import '../screens/salesinvoicescreen.dart';
import '../screens/sales_list_screen.dart';

// ✅ NEW — Features 20-23
import '../screens/delivery_payments_screen.dart';
import '../screens/create_order_screen.dart';
import '../screens/sales_screen.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final bool showBack;
  final ValueChanged<String>? onSearch;

  const AdminLayout({
    super.key,
    required this.child,
    required this.title,
    this.showBack = false,
    this.onSearch,
  });

  void _navigate(BuildContext context, Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  bool get _showSearch =>
      onSearch != null &&
      title != 'Dashboard' &&
      title != 'Reports' &&
      title != 'Settings';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          /* =========================
             🗂️ SIDEBAR
          ========================= */
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

                /* ========== DASHBOARD ========== */
                _menuItem(
                  context,
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  screen: const DashboardScreen(),
                ),

                /* ========== SALES ========== */
                _sectionTitle('Sales'),
                _expandableSection(
                  icon: Icons.shopping_cart,
                  title: 'Orders',
                  children: [
                    _subMenuItem(
                      context,
                      'All Orders',
                      const OrdersScreen(),
                    ),
                    _subMenuItem(
                      context,
                      'Returns',
                      const ReturnsScreen(),
                    ),
                    // ✅ Feature 22 — Create Order
                    _subMenuItem(
                      context,
                      'Create Order',
                      const CreateOrderScreen(),
                    ),
                  ],
                ),
                _expandableSection(
                  icon: Icons.receipt_long,
                  title: 'Sales',
                  children: [
                    _subMenuItem(
                      context,
                      'Sales Invoice',
                      const SalesInvoiceScreen(),
                    ),
                    _subMenuItem(
                      context,
                      'Sales List',
                      const SalesListScreen(),
                    ),
                    // ✅ Feature 23 — Sale Invoice (items only, custom date)
                    _subMenuItem(
                      context,
                      'Sale Report',
                      const SalesScreen(),
                    ),
                  ],
                ),

                /* ========== PRODUCTS ========== */
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

                /* ========== PURCHASE & INVENTORY ========== */
                _sectionTitle('Purchase & Inventory'),
                _expandableSection(
                  icon: Icons.local_shipping,
                  title: 'Purchase',
                  children: [
                    _subMenuItem(
                      context,
                      'Suppliers',
                      const SuppliersScreen(),
                    ),
                    _subMenuItem(
                      context,
                      'Purchase Invoices',
                      const PurchaseInvoicesScreen(),
                    ),
                    _subMenuItem(
                      context,
                      'Purchase Returns',
                      const PurchaseReturnsScreen(),
                    ),
                  ],
                ),

                /* ========== EXPENSES ========== */
                _sectionTitle('Expenses'),
                _expandableSection(
                  icon: Icons.analytics,
                  title: 'Expenses',
                  children: [
                    _subMenuItem(
                      context,
                      'Today Earnings',
                      const ExpensesScreen(),
                    ),
                    _subMenuItem(
                      context,
                      'Handling Charges',
                      const SizedBox(),
                    ),
                    _subMenuItem(
                      context,
                      'Delivery Charges',
                      const SizedBox(),
                    ),
                  ],
                ),

                /* ========== DELIVERY ========== */
                _sectionTitle('Delivery'),
                _expandableSection(
                  icon: Icons.delivery_dining,
                  title: 'Delivery Boys',
                  children: [
                    _subMenuItem(
                      context,
                      'Cash Collection',
                      const CashCollectionScreen(),
                    ),
                    // ✅ Feature 20 — Delivery boy payments
                    _subMenuItem(
                      context,
                      'Pay Delivery Boys',
                      const DeliveryPaymentsScreen(),
                    ),
                  ],
                ),

                /* ========== FINANCE ========== */
                _sectionTitle('Finance'),
                _expandableSection(
                  icon: Icons.account_balance_wallet,
                  title: 'Finance',
                  children: [
                    _subSectionTitle('Master'),
                    _subMenuItem(
                        context, 'Accounts', const AccountsScreen()),
                    _subMenuItem(
                        context, 'Banks', const BanksScreen()),
                    _subMenuItem(context, 'Opening Balance',
                        const OpeningBalanceScreen()),

                    _subSectionTitle('Receipts'),
                    _subMenuItem(
                        context, 'Receipt', const AddReceiptScreen()),
                    _subMenuItem(context, 'Receipt List',
                        const ReceiptsScreen()),

                    _subSectionTitle('Payments'),
                    _subMenuItem(
                        context, 'Payment', const AddPaymentScreen()),
                    _subMenuItem(context, 'Payment List',
                        const PaymentsScreen()),

                    _subSectionTitle('Cash / Bank'),
                    _subMenuItem(context, 'Contra Voucher',
                        const ContraVoucherScreen()),
                    _subMenuItem(context, 'Contra Voucher List',
                        const ContraVoucherListScreen()),
                  ],
                ),

                /* ========== CUSTOMERS ========== */
                _sectionTitle('Customers'),
                _menuItem(
                  context,
                  icon: Icons.people,
                  label: 'Customers',
                  screen: const CustomersScreen(),
                ),

                /* ========== REPORTS ========== */
                _sectionTitle('Reports'),
                _menuItem(
                  context,
                  icon: Icons.bar_chart,
                  label: 'Reports',
                  screen: const ReportsScreen(),
                ),

                /* ========== SETTINGS ========== */
                _sectionTitle('Settings'),
                _menuItem(
                  context,
                  icon: Icons.settings,
                  label: 'Settings',
                  screen: const SettingsScreen(),
                ),
              ],
            ),
          ),

          /* =========================
             📄 MAIN CONTENT
          ========================= */
          Expanded(
            child: Column(
              children: [
                // TOP BAR
                Container(
                  height: 60,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom:
                          BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Row(
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
                      const Spacer(),
                      if (_showSearch)
                        SizedBox(
                          width: 260,
                          height: 36,
                          child: TextField(
                            onChanged: onSearch,
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              prefixIcon: const Icon(
                                  Icons.search,
                                  size: 18),
                              contentPadding:
                                  const EdgeInsets.symmetric(
                                      vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),
                      const CircleAvatar(
                        radius: 18,
                        child: Icon(Icons.person),
                      ),
                    ],
                  ),
                ),

                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /* =========================
     🧩 UI HELPERS
  ========================= */

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

  Widget _subSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 10, 20, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w600,
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
      margin: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF1E293B)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 20),
        title: Text(label,
            style: const TextStyle(color: Colors.white)),
        onTap: () {
          if (!active) _navigate(context, screen);
        },
      ),
    );
  }

  Widget _subMenuItem(
    BuildContext context,
    String label,
    Widget screen,
  ) {
    final bool active = title == label;
    return Container(
      decoration: BoxDecoration(
        color: active
            ? const Color(0xFF1E293B)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 72),
        title: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white70,
            fontSize: 14,
            fontWeight: active
                ? FontWeight.w600
                : FontWeight.normal,
          ),
        ),
        onTap: () => _navigate(context, screen),
      ),
    );
  }

  Widget _expandableSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Theme(
      data:
          ThemeData.dark().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.white, size: 20),
        title: Text(title,
            style: const TextStyle(color: Colors.white)),
        iconColor: Colors.white,
        collapsedIconColor: Colors.white54,
        children: children,
      ),
    );
  }
}