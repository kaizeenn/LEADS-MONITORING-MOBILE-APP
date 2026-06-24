import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/chart_card.dart';
import '../../core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token ?? '';
      context.read<DashboardProvider>().refreshDashboard(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bus_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text(
              'Leads Pariwisata',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final dailyTrend = provider.dailyTrend;
          final wilayahChart = provider.wilayahChart;
          final sumberChart = provider.sumberChart;

          final hasData = dailyTrend.isNotEmpty || wilayahChart.isNotEmpty || sumberChart.isNotEmpty;

          return RefreshIndicator(
            onRefresh: () {
              final token = context.read<AuthProvider>().token ?? '';
              return provider.refreshDashboard(token);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: 'Hari Ini',
                          value: '${provider.todayTotal}',
                          icon: Icons.today_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryCard(
                          title: 'Bulan Ini',
                          value: '${provider.monthTotal}',
                          icon: Icons.calendar_month_rounded,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title: 'Tahun Ini',
                          value: '${provider.yearTotal}',
                          icon: Icons.calendar_today_rounded,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryCard(
                          title: 'Wilayah Teraktif',
                          value: provider.bestWilayah,
                          icon: Icons.map_rounded,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SummaryCard(
                    title: 'Sumber Leads Terbaik',
                    value: provider.bestSumber,
                    icon: Icons.campaign_rounded,
                    color: const Color(0xFF9C27B0),
                  ),
                  const SizedBox(height: 28),

                  if (!hasData)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada data leads.',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Data input leads akan otomatis tampil di sini.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'Visualisasi & Analitik',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onBackground,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    ChartCard(
                      title: 'Trend Leads Harian (7 Hari Terakhir)',
                      chart: DailyTrendChart(data: dailyTrend),
                    ),
                    const SizedBox(height: 8),
                    ChartCard(
                      title: 'Leads Berdasarkan Wilayah (Top 5)',
                      chart: WilayahBarChart(data: wilayahChart),
                    ),
                    const SizedBox(height: 8),
                    ChartCard(
                      title: 'Persentase Sumber Leads (Top 5)',
                      chart: SumberPieChart(data: sumberChart),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
