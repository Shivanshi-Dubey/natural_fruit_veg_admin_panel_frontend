import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/purchase_invoice_provider.dart';
import 'providers/grn_provider.dart';

// Screens
import 'screens/manage_products_screen.dart';
import 'screens/manage_orders_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseInvoiceProvider()),
        ChangeNotifierProvider(create: (_) => GRNProvider()),

      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Admin Panel - Natural Fruits & Vegetables',

            // 🌙 THEME SUPPORT
            themeMode: theme.themeMode,
            theme: ThemeData(
              primarySwatch: Colors.green,
              scaffoldBackgroundColor: Colors.grey[100],
            ),
            darkTheme: ThemeData.dark(),

            // 👇 ENTRY POINT
            home: const DashboardScreen(),

            routes: {
              '/dashboard': (context) => const DashboardScreen(),
              '/manage-products': (context) =>
                  const ManageProductsScreen(),
              '/manage-orders': (context) =>
                  const ManageOrdersScreen(),
              '/add-product': (context) =>
                  const AddProductScreen(),
            },
          );
        },
      ),
    );
  }
}
