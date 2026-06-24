import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/leads_model.dart';
import '../../providers/leads_provider.dart';
import '../../providers/laporan_provider.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/chart_card.dart';
import '../../widgets/empty_state.dart';
import '../../core/theme/app_colors.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LaporanProvider>().loadReport();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context, LaporanProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.startDate,
      firstDate: DateTime(2020),
      lastDate: provider.endDate,
    );
    if (picked != null) {
      provider.setStartDate(picked);
      provider.loadReport();
    }
  }

  Future<void> _selectEndDate(BuildContext context, LaporanProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.endDate,
      firstDate: provider.startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      provider.setEndDate(picked);
      provider.loadReport();
    }
  }

  // Calculate daily trend chart data from filtered leads
  List<Map<String, dynamic>> _getDailyTrend(List<LeadsModel> leads) {
    final Map<String, int> groups = {};
    for (final l in leads) {
      groups[l.tanggal] = (groups[l.tanggal] ?? 0) + l.jumlah;
    }
    final sortedKeys = groups.keys.toList()..sort();
    return sortedKeys.map((k) {
      final parts = k.split('-');
      final label = parts.length > 2 ? '${parts[2]}/${parts[1]}' : k;
      return {
        'date': k,
        'label': label,
        'total': groups[k]!,
      };
    }).toList();
  }

  // Calculate Wilayah chart data from filtered leads
  List<Map<String, dynamic>> _getWilayahChart(List<LeadsModel> leads) {
    final Map<String, int> groups = {};
    for (final l in leads) {
      final name = l.namaWilayah ?? 'Lainnya';
      groups[name] = (groups[name] ?? 0) + l.jumlah;
    }
    final sortedEntries = groups.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.map((e) => {
      'nama_wilayah': e.key,
      'total': e.value,
    }).toList();
  }

  // Calculate Sumber chart data from filtered leads
  List<Map<String, dynamic>> _getSumberChart(List<LeadsModel> leads) {
    final Map<String, int> groups = {};
    for (final l in leads) {
      final name = l.namaSumber ?? 'Lainnya';
      groups[name] = (groups[name] ?? 0) + l.jumlah;
    }
    final sortedEntries = groups.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.map((e) => {
      'nama_sumber': e.key,
      'total': e.value,
    }).toList();
  }

  // Show Edit Dialog
  void _showEditDialog(BuildContext context, LeadsModel lead) {
    final formKey = GlobalKey<FormState>();
    final jumlahController = TextEditingController(text: lead.jumlah.toString());
    int selectedWilayahId = lead.wilayahId;
    int selectedSumberId = lead.sumberId;
    DateTime selectedDate = DateTime.parse(lead.tanggal);

    final leadsProvider = context.read<LeadsProvider>();
    final laporanProvider = context.read<LaporanProvider>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Data Lead'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<int?>(
                        value: selectedWilayahId,
                        decoration: const InputDecoration(labelText: 'Wilayah'),
                        items: leadsProvider.wilayahList.map((w) {
                          return DropdownMenuItem<int?>(
                            value: w.id,
                            child: Text(w.namaWilayah),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedWilayahId = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => selectedDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Tanggal'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('dd-MM-yyyy').format(selectedDate)),
                              const Icon(Icons.calendar_today, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int?>(
                        value: selectedSumberId,
                        decoration: const InputDecoration(labelText: 'Sumber Leads'),
                        items: leadsProvider.sumberLeadsList.map((s) {
                          return DropdownMenuItem<int?>(
                            value: s.id,
                            child: Text(s.namaSumber),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedSumberId = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: jumlahController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Jumlah Leads'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Wajib diisi';
                          final num = int.tryParse(value);
                          if (num == null) return 'Hanya angka';
                          if (num < 0) return 'Minimal 0';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(ctx);

                    final updated = LeadsModel(
                      id: lead.id,
                      wilayahId: selectedWilayahId,
                      sumberId: selectedSumberId,
                      tanggal: DateFormat('yyyy-MM-dd').format(selectedDate),
                      jumlah: int.parse(jumlahController.text),
                      createdAt: lead.createdAt,
                    );

                    final success = await leadsProvider.updateLead(updated);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Data leads berhasil diupdate!'), backgroundColor: AppColors.success),
                      );
                      laporanProvider.loadReport();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal mengupdate data leads.'), backgroundColor: AppColors.danger),
                      );
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Show Delete Confirmation Dialog
  void _showDeleteDialog(BuildContext context, LeadsModel lead) {
    final leadsProvider = context.read<LeadsProvider>();
    final laporanProvider = context.read<LaporanProvider>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Hapus Data Lead'),
          content: Text('Apakah Anda yakin ingin menghapus data lead sebanyak ${lead.jumlah} di ${lead.namaWilayah} (${lead.namaSumber})?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await leadsProvider.deleteLead(lead.id!);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data leads berhasil dihapus!'), backgroundColor: AppColors.success),
                  );
                  laporanProvider.loadReport();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal menghapus data leads.'), backgroundColor: AppColors.danger),
                  );
                }
              },
              child: const Text('Hapus', style: TextStyle(color: AppColors.danger)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openFile(String path) async {
    final Uri uri = Uri.file(path);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      print('Error opening file: $e');
    }
  }

  void _exportExcel(BuildContext context, LaporanProvider provider) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 12), Text('Mengekspor Excel...')])),
    );
    final path = await provider.exportExcel();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (path != null) {
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel disimpan di: $path'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'Buka',
              textColor: Colors.white,
              onPressed: () => _openFile(path),
            ),
          ),
        );
      } else {
        try {
          await Share.shareXFiles([XFile(path)], text: 'Laporan Leads Monitoring Excel');
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Excel disimpan di: $path'), backgroundColor: AppColors.success),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengekspor Excel'), backgroundColor: AppColors.danger),
      );
    }
  }

  void _exportPdf(BuildContext context, LaporanProvider provider) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 12), Text('Mengekspor PDF...')])),
    );
    final path = await provider.exportPdf();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (path != null) {
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF disimpan di: $path'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'Buka',
              textColor: Colors.white,
              onPressed: () => _openFile(path),
            ),
          ),
        );
      } else {
        try {
          await Share.shareXFiles([XFile(path)], text: 'Laporan Leads Monitoring PDF');
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF disimpan di: $path'), backgroundColor: AppColors.success),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengekspor PDF'), backgroundColor: AppColors.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final leadsProvider = context.watch<LeadsProvider>();
    final laporanProvider = context.watch<LaporanProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Laporan Leads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_on_rounded),
            tooltip: 'Export Excel',
            onPressed: laporanProvider.filteredLeads.isEmpty ? null : () => _exportExcel(context, laporanProvider),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Export PDF',
            onPressed: laporanProvider.filteredLeads.isEmpty ? null : () => _exportPdf(context, laporanProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Panel
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.015),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectStartDate(context, laporanProvider),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DARI TANGGAL',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('dd/MM/yy').format(laporanProvider.startDate),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onBackground),
                                  ),
                                  const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectEndDate(context, laporanProvider),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SAMPAI TANGGAL',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('dd/MM/yy').format(laporanProvider.endDate),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onBackground),
                                  ),
                                  const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CustomDropdown<int?>(
                        label: 'Wilayah',
                        value: laporanProvider.wilayahId,
                        hint: 'Semua Wilayah',
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Semua Wilayah'),
                          ),
                          ...leadsProvider.wilayahList.map((w) {
                            return DropdownMenuItem<int?>(
                              value: w.id,
                              child: Text(w.namaWilayah),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          laporanProvider.setWilayahId(val);
                          laporanProvider.loadReport();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomDropdown<int?>(
                        label: 'Sumber Leads',
                        value: laporanProvider.sumberId,
                        hint: 'Semua Sumber',
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Semua Sumber'),
                          ),
                          ...leadsProvider.sumberLeadsList.map((s) {
                            return DropdownMenuItem<int?>(
                              value: s.id,
                              child: Text(s.namaSumber),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          laporanProvider.setSumberId(val);
                          laporanProvider.loadReport();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Statistics Row
          if (laporanProvider.filteredLeads.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  _buildMiniStat('Total Leads', '${laporanProvider.totalLeads}', AppColors.primary, Icons.group_rounded),
                  _buildMiniStat('Rata-rata/Hari', laporanProvider.averageLeads.toStringAsFixed(1), AppColors.secondary, Icons.analytics_rounded),
                  _buildMiniStat('Hari Aktif', '${laporanProvider.totalActiveDays}', AppColors.success, Icons.date_range_rounded),
                  _buildMiniStat('Top Wilayah', laporanProvider.bestWilayah, AppColors.warning, Icons.map_rounded),
                  _buildMiniStat('Top Sumber', laporanProvider.bestSumber, const Color(0xFF9C27B0), Icons.campaign_rounded),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(icon: Icon(Icons.table_chart_rounded, size: 20), text: 'Data Tabel'),
              Tab(icon: Icon(Icons.analytics_rounded, size: 20), text: 'Analisis Grafik'),
            ],
          ),

          // Tab views
          Expanded(
            child: laporanProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // 1. Data Table Tab
                      laporanProvider.filteredLeads.isEmpty
                          ? const EmptyState(subtitle: 'Ubah filter untuk memuat data leads.')
                          : Column(
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(left: 12, right: 12, top: 12),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1F5F9), // slate-100
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      topRight: Radius.circular(10),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                  child: Row(
                                    children: [
                                      _buildSortHeader('Tanggal', laporanProvider, flex: 3),
                                      _buildSortHeader('Wilayah', laporanProvider, flex: 3),
                                      const Expanded(
                                        flex: 3,
                                        child: Text(
                                          'Sumber',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: AppColors.onBackground,
                                          ),
                                        ),
                                      ),
                                      _buildSortHeader('Jumlah', laporanProvider, flex: 2),
                                      const SizedBox(width: 70),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      border: Border.all(color: AppColors.border),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(10),
                                        bottomRight: Radius.circular(10),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(10),
                                        bottomRight: Radius.circular(10),
                                      ),
                                      child: ListView.builder(
                                        itemCount: laporanProvider.filteredLeads.length,
                                        padding: const EdgeInsets.only(bottom: 90),
                                        itemBuilder: (ctx, index) {
                                          final lead = laporanProvider.filteredLeads[index];
                                          final dateParsed = DateTime.parse(lead.tanggal);
                                          final dateStr = DateFormat('dd/MM/yy').format(dateParsed);
                                          final isOdd = index % 2 == 1;

                                          return Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                            decoration: BoxDecoration(
                                              color: isOdd ? const Color(0xFFF8FAFC) : AppColors.surface,
                                              border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    dateStr,
                                                    style: const TextStyle(fontSize: 12.5, color: AppColors.onBackground),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    lead.namaWilayah ?? '-',
                                                    style: const TextStyle(fontSize: 12.5, color: AppColors.onBackground, fontWeight: FontWeight.w500),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    lead.namaSumber ?? '-',
                                                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    '${lead.jumlah}',
                                                    style: const TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 70,
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.end,
                                                    children: [
                                                      InkWell(
                                                        onTap: () => _showEditDialog(context, lead),
                                                        borderRadius: BorderRadius.circular(14),
                                                        child: Container(
                                                          width: 28,
                                                          height: 28,
                                                          decoration: BoxDecoration(
                                                            color: AppColors.primary.withOpacity(0.08),
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      InkWell(
                                                        onTap: () => _showDeleteDialog(context, lead),
                                                        borderRadius: BorderRadius.circular(14),
                                                        child: Container(
                                                          width: 28,
                                                          height: 28,
                                                          decoration: BoxDecoration(
                                                            color: AppColors.danger.withOpacity(0.08),
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: const Icon(Icons.delete_outline_rounded, size: 14, color: AppColors.danger),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                      // 2. Charts Tab
                      laporanProvider.filteredLeads.isEmpty
                          ? const EmptyState(subtitle: 'Ubah filter untuk memuat visualisasi grafik.')
                          : SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                              child: Column(
                                children: [
                                  ChartCard(
                                    title: 'Leads Harian',
                                    chart: DailyTrendChart(data: _getDailyTrend(laporanProvider.filteredLeads)),
                                  ),
                                  const SizedBox(height: 12),
                                  ChartCard(
                                    title: 'Leads Wilayah (Top 5)',
                                    chart: WilayahBarChart(data: _getWilayahChart(laporanProvider.filteredLeads)),
                                  ),
                                  const SizedBox(height: 12),
                                  ChartCard(
                                    title: 'Leads Sumber (Top 5)',
                                    chart: SumberPieChart(data: _getSumberChart(laporanProvider.filteredLeads)),
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color, IconData icon) {
    return Container(
      width: 142,
      margin: const EdgeInsets.only(right: 10, bottom: 4, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 8,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortHeader(String title, LaporanProvider provider, {required int flex}) {
    final isSelected = provider.sortColumn == title;

    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => provider.sortData(title),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.onBackground,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 2),
              Icon(
                provider.isAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 12,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

}
