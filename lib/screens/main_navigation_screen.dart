import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/leads_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/laporan_provider.dart';
import '../providers/auth_provider.dart';
import 'home/home_screen.dart';
import 'add_data/add_data_screen.dart';
import 'laporan/laporan_screen.dart';
import 'settings/settings_screen.dart';
import '../core/theme/app_colors.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token ?? '';
      context.read<LeadsProvider>().loadInitialData(token);
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    final token = context.read<AuthProvider>().token ?? '';
    final isOwner = context.read<AuthProvider>().userRole == 'owner';
    
    // Refresh state when specific tabs are selected
    if (index == 0) {
      context.read<DashboardProvider>().refreshDashboard(token);
    } else if ((isOwner && index == 1) || (!isOwner && index == 2)) {
      context.read<LaporanProvider>().loadReport(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = context.watch<AuthProvider>().userRole == 'owner';
    final screens = [
      const HomeScreen(),
      if (!isOwner) const AddDataScreen(),
      const LaporanScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom + 8 : 16,
          top: 8,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              elevation: 0,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textSecondary,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 10),
              items: [
                const BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Icon(Icons.dashboard_outlined, size: 20),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Icon(Icons.dashboard, size: 20),
                  ),
                  label: 'Home',
                ),
                if (!isOwner)
                  const BottomNavigationBarItem(
                    icon: Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: Icon(Icons.add_box_outlined, size: 20),
                    ),
                    activeIcon: Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: Icon(Icons.add_box, size: 20),
                    ),
                    label: 'Add Data',
                  ),
                const BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Icon(Icons.analytics_outlined, size: 20),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Icon(Icons.analytics, size: 20),
                  ),
                  label: 'Laporan',
                ),
                const BottomNavigationBarItem(
                  icon: Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Icon(Icons.settings_outlined, size: 20),
                  ),
                  activeIcon: Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Icon(Icons.settings, size: 20),
                  ),
                  label: 'Pengaturan',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
