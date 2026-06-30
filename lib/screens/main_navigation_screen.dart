import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/leads_model.dart';
import '../models/leads_tour_model.dart';
import '../providers/auth_provider.dart';
import '../providers/leads_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/laporan_provider.dart';
import 'add_data/add_data_screen.dart';
import '../widgets/chart_card.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/empty_state.dart';
import '../core/theme/app_colors.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  String _viewMode = 'list'; // 'list' or 'chart'
  
  final List<String> _tourLocations = [
    'Bogor',
    'Bandung',
    'Jogja',
    'Malang',
    'Bromo',
    'Banyuwangi',
    'Bali',
    'Lombok',
    'Labuan Bajo'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token ?? '';
      final division = authProvider.userBagian.isNotEmpty ? authProvider.userBagian : 'marketing';
      
      context.read<LeadsProvider>().loadInitialData(token);
      context.read<DashboardProvider>().initializeDivision(division);
      context.read<DashboardProvider>().refreshDashboard(token);
      context.read<LaporanProvider>().setDivision(division, token);
    });
  }

  void _refreshData() {
    final token = context.read<AuthProvider>().token ?? '';
    context.read<DashboardProvider>().refreshDashboard(token);
    context.read<LaporanProvider>().loadReport(token);
  }

  void _changeDivision(String division) {
    final token = context.read<AuthProvider>().token ?? '';
    context.read<DashboardProvider>().setDivision(division, token);
    context.read<LaporanProvider>().setDivision(division, token);
  }

  Future<void> _selectDateRange(BuildContext context, LaporanProvider provider) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: provider.startDate, end: provider.endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      provider.setStartDate(picked.start);
      provider.setEndDate(picked.end);
      final token = context.read<AuthProvider>().token ?? '';
      provider.loadReport(token);
    }
  }

  // Show Edit Dialog (Marketing)
  void _showEditDialog(BuildContext context, LeadsModel lead) {
    final formKey = GlobalKey<FormState>();
    final jumlahController = TextEditingController(text: lead.jumlah.toString());
    int selectedWilayahId = lead.wilayahId;
    int selectedSumberId = lead.sumberId;
    DateTime selectedDate = DateTime.parse(lead.tanggal);

    final leadsProvider = context.read<LeadsProvider>();

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

                    final token = context.read<AuthProvider>().token ?? '';
                    final success = await leadsProvider.updateLead(token, updated);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Data leads berhasil diupdate!'), backgroundColor: AppColors.success),
                      );
                      _refreshData();
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

  // Show Edit Tour Dialog
  void _showEditTourDialog(BuildContext context, LeadsTourModel lead) {
    final formKey = GlobalKey<FormState>();
    final namaClientController = TextEditingController(text: lead.namaClient);
    final asalClientController = TextEditingController(text: lead.asalClient);
    final noHpClientController = TextEditingController(text: lead.noHpClient);
    String selectedLokasi = lead.lokasi;
    int selectedSumberId = lead.sumberId;
    DateTime selectedDate = DateTime.parse(lead.tanggal);

    final leadsProvider = context.read<LeadsProvider>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Data Lead Tour'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedLokasi,
                        decoration: const InputDecoration(labelText: 'Lokasi Tujuan'),
                        items: _tourLocations.map((loc) {
                          return DropdownMenuItem<String>(
                            value: loc,
                            child: Text(loc),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedLokasi = val);
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
                        controller: namaClientController,
                        decoration: const InputDecoration(labelText: 'Nama Client'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: asalClientController,
                        decoration: const InputDecoration(labelText: 'Asal Client'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: noHpClientController,
                        decoration: const InputDecoration(labelText: 'Nomor HP Client'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Wajib diisi' : null,
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

                    final updated = LeadsTourModel(
                      id: lead.id,
                      lokasi: selectedLokasi,
                      sumberId: selectedSumberId,
                      userId: lead.userId,
                      tanggal: DateFormat('yyyy-MM-dd').format(selectedDate),
                      namaClient: namaClientController.text,
                      asalClient: asalClientController.text,
                      noHpClient: noHpClientController.text,
                      createdAt: lead.createdAt,
                    );

                    final token = context.read<AuthProvider>().token ?? '';
                    final success = await leadsProvider.updateLeadTour(token, updated);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Data leads tour berhasil diupdate!'), backgroundColor: AppColors.success),
                      );
                      _refreshData();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gagal mengupdate data leads tour.'), backgroundColor: AppColors.danger),
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

  // Show Delete Confirmation Dialog (Marketing)
  void _showDeleteDialog(BuildContext context, LeadsModel lead) {
    final leadsProvider = context.read<LeadsProvider>();

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
                final token = context.read<AuthProvider>().token ?? '';
                final success = await leadsProvider.deleteLead(token, lead.id!);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data leads berhasil dihapus!'), backgroundColor: AppColors.success),
                  );
                  _refreshData();
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

  // Show Delete Confirmation Dialog (Tour)
  void _showDeleteTourDialog(BuildContext context, LeadsTourModel lead) {
    final leadsProvider = context.read<LeadsProvider>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Hapus Data Lead Tour'),
          content: Text('Apakah Anda yakin ingin menghapus data lead tour client "${lead.namaClient}" tujuan ${lead.lokasi}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final token = context.read<AuthProvider>().token ?? '';
                final success = await leadsProvider.deleteLeadTour(token, lead.id!);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data leads tour berhasil dihapus!'), backgroundColor: AppColors.success),
                  );
                  _refreshData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal menghapus data leads tour.'), backgroundColor: AppColors.danger),
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

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final laporanProvider = context.watch<LaporanProvider>();
    final leadsProvider = context.watch<LeadsProvider>();
    
    final isOwner = authProvider.userRole == 'owner';
    final isAdmin = authProvider.userRole == 'admin';
    final showTabs = isOwner || isAdmin;

    final dailyTrend = dashboardProvider.dailyTrend;
    final wilayahChart = dashboardProvider.wilayahChart;
    final sumberChart = dashboardProvider.sumberChart;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bus_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text(
              'Leads Pariwisata',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.3),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_on_rounded),
            tooltip: 'Export Excel',
            onPressed: laporanProvider.filteredLeads.isEmpty ? null : () => _exportExcel(context, laporanProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            tooltip: 'Logout',
            onPressed: () {
              context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Division Switcher Tabs
              if (showTabs) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SegmentedButton<String>(
                    segments: const <ButtonSegment<String>>[
                      ButtonSegment<String>(
                        value: 'marketing',
                        label: Text('Marketing'),
                        icon: Icon(Icons.campaign_rounded),
                      ),
                      ButtonSegment<String>(
                        value: 'tour',
                        label: Text('Tour'),
                        icon: Icon(Icons.directions_bus_rounded),
                      ),
                    ],
                    selected: <String>{dashboardProvider.currentDivision},
                    onSelectionChanged: (Set<String> newSelection) {
                      _changeDivision(newSelection.first);
                    },
                  ),
                ),
              ],

              // 2. Summary stats cards
              Row(
                children: [
                  Expanded(
                    child: _buildMainStatCard(
                      'Hari Ini',
                      '${dashboardProvider.todayTotal}',
                      Icons.today_rounded,
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMainStatCard(
                      'Bulan Ini',
                      '${dashboardProvider.monthTotal}',
                      Icons.calendar_month_rounded,
                      AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMainStatCard(
                      'Tahun Ini',
                      '${dashboardProvider.yearTotal}',
                      Icons.calendar_today_rounded,
                      AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMainStatCard(
                      dashboardProvider.currentDivision == 'marketing' ? 'Wilayah Teraktif' : 'Lokasi Teraktif',
                      dashboardProvider.bestWilayah,
                      Icons.map_rounded,
                      AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildMainStatCard(
                'Sumber Leads Terbaik',
                dashboardProvider.bestSumber,
                Icons.campaign_rounded,
                const Color(0xFF9C27B0),
              ),
              const SizedBox(height: 24),

              // 3. View Mode Toggle (Data List vs Charts)
              Center(
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'list',
                      label: Text('Daftar Data'),
                      icon: Icon(Icons.list_alt_rounded),
                    ),
                    ButtonSegment<String>(
                      value: 'chart',
                      label: Text('Grafik & Analisis'),
                      icon: Icon(Icons.analytics_rounded),
                    ),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (val) {
                    setState(() {
                      _viewMode = val.first;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 4. Conditional Content
              if (_viewMode == 'list') ...[
                // Collapsible Filter Panel
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ExpansionTile(
                        title: const Text(
                          'Filter Pencarian',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: AppColors.onBackground,
                          ),
                        ),
                        leading: const Icon(Icons.filter_list_rounded, color: AppColors.primary, size: 20),
                        initiallyExpanded: false,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          InkWell(
                            onTap: () => _selectDateRange(context, laporanProvider),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'PERIODE LAPORAN',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${DateFormat('dd/MM/yy').format(laporanProvider.startDate)} - ${DateFormat('dd/MM/yy').format(laporanProvider.endDate)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.onBackground),
                                      ),
                                    ],
                                  ),
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: laporanProvider.currentDivision == 'marketing'
                                    ? CustomDropdown<int?>(
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
                                          laporanProvider.loadReport(authProvider.token ?? '');
                                        },
                                      )
                                    : CustomDropdown<String?>(
                                        label: 'Lokasi / Daerah',
                                        value: laporanProvider.lokasi,
                                        hint: 'Semua Lokasi',
                                        items: [
                                          const DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text('Semua Lokasi'),
                                          ),
                                          ..._tourLocations.map((loc) {
                                            return DropdownMenuItem<String?>(
                                              value: loc,
                                              child: Text(loc),
                                            );
                                          }),
                                        ],
                                        onChanged: (val) {
                                          laporanProvider.setLokasi(val);
                                          laporanProvider.loadReport(authProvider.token ?? '');
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
                                    laporanProvider.loadReport(authProvider.token ?? '');
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Sorting & total data count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total ${laporanProvider.filteredLeads.length} data',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => laporanProvider.sortData('Tanggal'),
                        icon: Icon(
                          laporanProvider.isAscending 
                              ? Icons.arrow_upward_rounded 
                              : Icons.arrow_downward_rounded,
                          size: 14,
                        ),
                        label: const Text(
                          'Urut Tanggal',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Card List View
                laporanProvider.filteredLeads.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.only(top: 32),
                        child: EmptyState(subtitle: 'Belum ada data leads untuk filter ini.'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: laporanProvider.filteredLeads.length,
                        itemBuilder: (ctx, index) {
                          final lead = laporanProvider.filteredLeads[index];
                          return _LeadListItem(
                            lead: lead,
                            division: laporanProvider.currentDivision,
                            isOwner: isOwner,
                            onEdit: () {
                              if (laporanProvider.currentDivision == 'marketing') {
                                _showEditDialog(context, lead as LeadsModel);
                              } else {
                                _showEditTourDialog(context, lead as LeadsTourModel);
                              }
                            },
                            onDelete: () {
                              if (laporanProvider.currentDivision == 'marketing') {
                                _showDeleteDialog(context, lead as LeadsModel);
                              } else {
                                _showDeleteTourDialog(context, lead as LeadsTourModel);
                              }
                            },
                          );
                        },
                      ),
              ] else ...[
                // Visualisation & Charts
                if (dailyTrend.isEmpty && wilayahChart.isEmpty && sumberChart.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 32),
                    child: EmptyState(subtitle: 'Belum ada data untuk dianalisis.'),
                  )
                else ...[
                  ChartCard(
                    title: 'Trend Leads Harian (7 Hari Terakhir)',
                    chart: DailyTrendChart(data: dailyTrend),
                  ),
                  const SizedBox(height: 12),
                  ChartCard(
                    title: dashboardProvider.currentDivision == 'marketing'
                        ? 'Leads Berdasarkan Wilayah (Top 5)'
                        : 'Leads Berdasarkan Lokasi (Top 5)',
                    chart: WilayahBarChart(data: wilayahChart),
                  ),
                  const SizedBox(height: 12),
                  ChartCard(
                    title: 'Persentase Sumber Leads (Top 5)',
                    chart: SumberPieChart(data: sumberChart),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: isOwner
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddDataScreen()),
                );
                _refreshData();
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Tambah Leads', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              backgroundColor: dashboardProvider.currentDivision == 'marketing'
                  ? AppColors.primary
                  : const Color(0xFF0D9488),
            ),
    );
  }

  Widget _buildMainStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onBackground,
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
}

class _LeadListItem extends StatelessWidget {
  final dynamic lead;
  final String division;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LeadListItem({
    required this.lead,
    required this.division,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = lead is LeadsModel
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(lead.tanggal))
        : DateFormat('dd MMM yyyy').format(DateTime.parse((lead as LeadsTourModel).tanggal));

    if (division == 'marketing') {
      final l = lead as LeadsModel;
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.namaWilayah ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.onBackground),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sumber: ${l.namaSumber ?? "-"}  •  $dateStr',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${l.jumlah} Leads',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.primary),
                    ),
                  ),
                  if (!isOwner) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: onEdit,
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      final l = lead as LeadsTourModel;
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l.namaClient,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.onBackground),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l.lokasi,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0D9488)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.campaign_rounded, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    l.namaSumber ?? '-',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.place_rounded, size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Asal: ${l.asalClient}',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'No HP: ${l.noHpClient}  •  $dateStr',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isOwner)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: onEdit,
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }
}
