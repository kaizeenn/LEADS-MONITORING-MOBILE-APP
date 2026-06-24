import 'package:flutter/material.dart';
import '../screens/main_navigation_screen.dart';

class AppRoutes {
  static const String initial = '/';

  static Map<String, WidgetBuilder> get routes => {
    initial: (context) => const MainNavigationScreen(),
  };
}
