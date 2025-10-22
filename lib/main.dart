import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';
import 'providers/auth_provider.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/manage_products_screen.dart';
import 'screens/manage_orders_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/admin_home_screen.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: 'Admin Panel - Natural Fruits & Vegetables',
        theme: ThemeData(
          primarySwatch: Colors.green,
          scaffoldBackgroundColor: const Color(0xFFF8F8FF),
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/manage-products': (context) => const ManageProductsScreen(),
          '/manage-orders': (context) => const ManageOrdersScreen(),
          '/add-product': (context) => const AddProductScreen(),
          '/admin-home': (context) => const AdminHomeScreen(),
        },
      ),
    );
  }
}

