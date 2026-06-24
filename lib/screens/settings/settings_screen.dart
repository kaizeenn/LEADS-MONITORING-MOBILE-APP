import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/leads_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/laporan_provider.dart';
import '../../core/theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _runBackup(BuildContext context) async {
    final settingsProvider = context.read<SettingsProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 12), Text('Membuat backup database...')])),
    );
    final path = await settingsProvider.runBackup();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup berhasil dibuat dan siap dibagikan!'), backgroundColor: AppColors.success),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuat backup database.'), backgroundColor: AppColors.danger),
      );
    }
  }

  void _runRestore(BuildContext context) async {
    final settingsProvider = context.read<SettingsProvider>();
    final leadsProvider = context.read<LeadsProvider>();
    final dashboardProvider = context.read<DashboardProvider>();
    final laporanProvider = context.read<LaporanProvider>();

    try {
      final backupData = await settingsProvider.pickAndValidateBackup();
      if (backupData == null) return; // Cancelled

      final List wilayah = backupData['wilayah'] ?? [];
      final List sumber = backupData['sumber_leads'] ?? [];
      final List leads = backupData['leads'] ?? [];
      final String backupDate = backupData['backup_date'] ?? '-';

      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Konfirmasi Restore Data'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PERINGATAN: Semua data lama akan dihapus dan digantikan oleh data dari file backup ini.',
                  style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text('Tanggal Backup: $backupDate'),
                const SizedBox(height: 8),
                Text('• Jumlah Wilayah: ${wilayah.length}'),
                Text('• Jumlah Sumber Leads: ${sumber.length}'),
                Text('• Jumlah Data Leads: ${leads.length}'),
                const SizedBox(height: 12),
                const Text('Apakah Anda yakin ingin melanjutkan restore?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 12), Text('Memulihkan data...')])),
                  );
                  
                  final success = await settingsProvider.executeRestore(backupData);
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();

                  if (success) {
                    await leadsProvider.loadInitialData();
                    await dashboardProvider.refreshDashboard();
                    await laporanProvider.loadReport();

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Database berhasil direstore!'), backgroundColor: AppColors.success),
                    );
                  } else {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Gagal melakukan restore data.'), backgroundColor: AppColors.danger),
                    );
                  }
                },
                child: const Text('Ya, Restore', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: settingsProvider.isOperating
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(
                    'Pencadangan & Pemulihan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onBackground,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.backup_rounded, color: AppColors.primary, size: 20),
                        ),
                        title: const Text('Backup Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: const Text('Ekspor seluruh database ke file JSON', style: TextStyle(fontSize: 12.5)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                        onTap: () => _buildBackupConfirmation(context),
                      ),
                      const Divider(height: 1, indent: 68),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.settings_backup_restore_rounded, color: AppColors.secondary, size: 20),
                        ),
                        title: const Text('Restore Data', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: const Text('Import database dari file backup JSON', style: TextStyle(fontSize: 12.5)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                        onTap: () => _runRestore(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.directions_bus_rounded, color: AppColors.textSecondary, size: 24),
                      SizedBox(height: 8),
                      Text(
                        'Leads Monitoring App v1.0.0',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Khairil Anwar PENS Sumenep',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
    );
  }

  void _buildBackupConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backup Database'),
        content: const Text('File backup JSON berisi daftar Wilayah, Sumber Leads, dan data input Leads Anda. Anda bisa membagikannya langsung setelah digenerate.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _runBackup(context);
            },
            child: const Text('Mulai Backup'),
          ),
        ],
      ),
    );
  }
}
