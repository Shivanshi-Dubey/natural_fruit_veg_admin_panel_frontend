import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/add_product_screen.dart';
import 'screens/orders_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/login': (_) => const LoginScreen(),
  '/dashboard': (_) => const DashboardScreen(),
  '/products': (_) => const ProductListScreen(),
  '/add_product': (_) => const AddProductScreen(),
  '/orders': (_) => const OrdersScreen(),
};
