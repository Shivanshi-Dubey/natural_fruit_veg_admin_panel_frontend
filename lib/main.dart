import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/product_provider.dart';
import 'providers/order_provider.dart';

import 'screens/admin_home_screen.dart';
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
      ],
      child: MaterialApp(
        title: 'Admin Panel - Natural Fruits & Vegetables',
        theme: ThemeData(primarySwatch: Colors.green),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const AdminHomeScreen(),
          '/manage-products': (context) => const ManageProductsScreen(),
          '/manage-orders': (context) => const ManageOrdersScreen(),
          '/add-product': (context) => const AddProductScreen(),
          '/dashboard-screen': (context) => const DashboardScreen(),
        },
      ),
    );
  }
}

