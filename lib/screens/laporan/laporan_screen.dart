import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/leads_model.dart';
import '../../models/leads_tour_model.dart';
import '../../providers/leads_provider.dart';
import '../../providers/laporan_provider.dart';
import '../../providers/auth_provider.dart';
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
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final token = authProvider.token ?? '';
      final division = authProvider.userBagian.isNotEmpty ? authProvider.userBagian : 'marketing';
      context.read<LaporanProvider>().setDivision(division, token);
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
      final token = context.read<AuthProvider>().token ?? '';
      provider.loadReport(token);
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
      final token = context.read<AuthProvider>().token ?? '';
      provider.loadReport(token);
    }
  }

  // Calculate daily trend chart data from filtered leads
  List<Map<String, dynamic>> _getDailyTrend(List<dynamic> leads, String division) {
    final Map<String, int> groups = {};
    for (final l in leads) {
      final date = l is LeadsModel ? l.tanggal : (l as LeadsTourModel).tanggal;
      final amount = l is LeadsModel ? l.jumlah : 1;
      groups[date] = (groups[date] ?? 0) + amount;
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
  List<Map<String, dynamic>> _getWilayahChart(List<dynamic> leads, String division) {
    final Map<String, int> groups = {};
    for (final l in leads) {
      final name = division == 'marketing' 
          ? ((l as LeadsModel).namaWilayah ?? 'Lainnya') 
          : (l as LeadsTourModel).lokasi;
      final amount = division == 'marketing' ? (l as LeadsModel).jumlah : 1;
      groups[name] = (groups[name] ?? 0) + amount;
    }
    final sortedEntries = groups.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.map((e) => {
      'nama_wilayah': e.key,
      'total': e.value,
    }).toList();
  }

  // Calculate Sumber chart data from filtered leads
  List<Map<String, dynamic>> _getSumberChart(List<dynamic> leads, String division) {
    final Map<String, int> groups = {};
    for (final l in leads) {
      final name = l is LeadsModel ? (l.namaSumber ?? 'Lainnya') : ((l as LeadsTourModel).namaSumber ?? 'Lainnya');
      final amount = l is LeadsModel ? l.jumlah : 1;
      groups[name] = (groups[name] ?? 0) + amount;
    }
    final sortedEntries = groups.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.map((e) => {
      'nama_sumber': e.key,
      'total': e.value,
    }).toList();
  }

  // Show Edit Dialog (Marketing)
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

                    final token = context.read<AuthProvider>().token ?? '';
                    final success = await leadsProvider.updateLead(token, updated);
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Data leads berhasil diupdate!'), backgroundColor: AppColors.success),
                      );
                      laporanProvider.loadReport(token);
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
    final laporanProvider = context.read<LaporanProvider>();

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
                      laporanProvider.loadReport(token);
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
                final token = context.read<AuthProvider>().token ?? '';
                final success = await leadsProvider.deleteLead(token, lead.id!);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data leads berhasil dihapus!'), backgroundColor: AppColors.success),
                  );
                  laporanProvider.loadReport(token);
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
    final laporanProvider = context.read<LaporanProvider>();

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
                  laporanProvider.loadReport(token);
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
    final authProvider = context.watch<AuthProvider>();
    final isOwner = authProvider.userRole == 'owner';
    final isAdmin = authProvider.userRole == 'admin';
    final showTabs = isOwner || isAdmin;

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
                if (showTabs) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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
                      selected: <String>{laporanProvider.currentDivision},
                      onSelectionChanged: (Set<String> newSelection) {
                        final token = authProvider.token ?? '';
                        laporanProvider.setDivision(newSelection.first, token);
                      },
                    ),
                  ),
                ],
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
                                final token = context.read<AuthProvider>().token ?? '';
                                laporanProvider.loadReport(token);
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
                                final token = context.read<AuthProvider>().token ?? '';
                                laporanProvider.loadReport(token);
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
                          final token = context.read<AuthProvider>().token ?? '';
                          laporanProvider.loadReport(token);
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
                  _buildMiniStat(laporanProvider.currentDivision == 'marketing' ? 'Top Wilayah' : 'Top Lokasi', laporanProvider.bestWilayah, AppColors.warning, Icons.map_rounded),
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
                                      _buildSortHeader(laporanProvider.currentDivision == 'marketing' ? 'Wilayah' : 'Lokasi', laporanProvider, flex: 3),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          laporanProvider.currentDivision == 'marketing' ? 'Sumber' : 'Client',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: AppColors.onBackground,
                                          ),
                                        ),
                                      ),
                                      _buildSortHeader(laporanProvider.currentDivision == 'marketing' ? 'Jumlah' : 'No HP', laporanProvider, flex: 2),
                                      if (!isOwner) const SizedBox(width: 70),
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
                                          final isOdd = index % 2 == 1;

                                          final String dateStr;
                                          final String locName;
                                          final String thirdCol;
                                          final String fourthCol;

                                          if (laporanProvider.currentDivision == 'marketing') {
                                            final l = lead as LeadsModel;
                                            dateStr = DateFormat('dd/MM/yy').format(DateTime.parse(l.tanggal));
                                            locName = l.namaWilayah ?? '-';
                                            thirdCol = l.namaSumber ?? '-';
                                            fourthCol = '${l.jumlah}';
                                          } else {
                                            final l = lead as LeadsTourModel;
                                            dateStr = DateFormat('dd/MM/yy').format(DateTime.parse(l.tanggal));
                                            locName = l.lokasi;
                                            thirdCol = l.namaClient;
                                            fourthCol = l.noHpClient;
                                          }

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
                                                    locName,
                                                    style: const TextStyle(fontSize: 12.5, color: AppColors.onBackground, fontWeight: FontWeight.w500),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    thirdCol,
                                                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    fourthCol,
                                                    style: TextStyle(
                                                      fontSize: 11.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: laporanProvider.currentDivision == 'marketing' ? AppColors.primary : AppColors.textSecondary,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (!isOwner)
                                                  SizedBox(
                                                    width: 70,
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        InkWell(
                                                          onTap: () {
                                                            if (laporanProvider.currentDivision == 'marketing') {
                                                              _showEditDialog(context, lead as LeadsModel);
                                                            } else {
                                                              _showEditTourDialog(context, lead as LeadsTourModel);
                                                            }
                                                          },
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
                                                          onTap: () {
                                                            if (laporanProvider.currentDivision == 'marketing') {
                                                              _showDeleteDialog(context, lead as LeadsModel);
                                                            } else {
                                                              _showDeleteTourDialog(context, lead as LeadsTourModel);
                                                            }
                                                          },
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
                                    chart: DailyTrendChart(data: _getDailyTrend(laporanProvider.filteredLeads, laporanProvider.currentDivision)),
                                  ),
                                  const SizedBox(height: 12),
                                  ChartCard(
                                    title: laporanProvider.currentDivision == 'marketing' ? 'Leads Wilayah (Top 5)' : 'Leads Lokasi (Top 5)',
                                    chart: WilayahBarChart(data: _getWilayahChart(laporanProvider.filteredLeads, laporanProvider.currentDivision)),
                                  ),
                                  const SizedBox(height: 12),
                                  ChartCard(
                                    title: 'Leads Sumber (Top 5)',
                                    chart: SumberPieChart(data: _getSumberChart(laporanProvider.filteredLeads, laporanProvider.currentDivision)),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 11.5,
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

  Widget _buildSortHeader(String label, LaporanProvider provider, {required int flex}) {
    final isSorted = provider.sortColumn == label;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => provider.sortData(label),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.onBackground,
              ),
            ),
            if (isSorted)
              Icon(
                provider.isAscending ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                size: 16,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
