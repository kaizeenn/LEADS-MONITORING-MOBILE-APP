import 'dart:io';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'providers/leads_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/laporan_provider.dart';
import 'providers/settings_provider.dart';
import 'routes/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for desktop platforms (Linux, Windows)
  if (Platform.isLinux || Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LeadsProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => LaporanProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const LeadsMonitoringApp(),
    ),
  );
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class LeadsMonitoringApp extends StatelessWidget {
  const LeadsMonitoringApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leads Monitoring App',
      theme: AppTheme.lightTheme,
      scrollBehavior: MyCustomScrollBehavior(),
      initialRoute: AppRoutes.initial,
      routes: AppRoutes.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
