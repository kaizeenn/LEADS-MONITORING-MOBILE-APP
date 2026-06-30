import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/leads_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_button.dart';
import '../../core/theme/app_colors.dart';

class AddDataScreen extends StatefulWidget {
  const AddDataScreen({super.key});

  @override
  State<AddDataScreen> createState() => _AddDataScreenState();
}

class _AddDataScreenState extends State<AddDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController();
  final _namaClientController = TextEditingController();
  final _asalClientController = TextEditingController();
  final _noHpClientController = TextEditingController();

  int? _selectedWilayahId;
  int? _selectedSumberId;
  String? _selectedLokasi;
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

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
  void dispose() {
    _jumlahController.dispose();
    _namaClientController.dispose();
    _asalClientController.dispose();
    _noHpClientController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _selectedWilayahId = null;
      _selectedSumberId = null;
      _selectedLokasi = null;
      _selectedDate = DateTime.now();
      _jumlahController.clear();
      _namaClientController.clear();
      _asalClientController.clear();
      _noHpClientController.clear();
    });
  }

  Future<void> _saveLead() async {
    final authProvider = context.read<AuthProvider>();
    final isTour = authProvider.userBagian == 'tour';

    if (isTour) {
      if (_selectedLokasi == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih lokasi tujuan'), backgroundColor: AppColors.danger),
        );
        return;
      }
    } else {
      if (_selectedWilayahId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih wilayah'), backgroundColor: AppColors.danger),
        );
        return;
      }
    }

    if (_selectedSumberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih sumber leads'), backgroundColor: AppColors.danger),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    final leadsProvider = context.read<LeadsProvider>();
    final df = DateFormat('yyyy-MM-dd');
    final token = authProvider.token ?? '';
    
    final bool success;
    if (isTour) {
      success = await leadsProvider.addLeadTour(
        token,
        lokasi: _selectedLokasi!,
        sumberId: _selectedSumberId!,
        tanggal: df.format(_selectedDate),
        namaClient: _namaClientController.text,
        asalClient: _asalClientController.text,
        noHpClient: _noHpClientController.text,
      );
    } else {
      success = await leadsProvider.addLead(
        token,
        wilayahId: _selectedWilayahId!,
        sumberId: _selectedSumberId!,
        tanggal: df.format(_selectedDate),
        jumlah: int.parse(_jumlahController.text),
      );
    }

    setState(() {
      _isSaving = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data leads berhasil disimpan!'),
          backgroundColor: AppColors.success,
        ),
      );
      _resetForm();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan data leads.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showManageWilayahBottomSheet(BuildContext context) {
    final textController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Consumer<LeadsProvider>(
            builder: (context, provider, child) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kelola Wilayah',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Form(
                    key: formKey,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: textController,
                            decoration: const InputDecoration(
                              hintText: 'Nama wilayah baru',
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Nama wilayah wajib diisi';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final name = textController.text.trim();
                            final token = context.read<AuthProvider>().token ?? '';
                            final success = await provider.addWilayah(token, name);
                            if (success) {
                              textController.clear();
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Wilayah berhasil ditambahkan!'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(80, 48),
                            backgroundColor: AppColors.primary,
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Daftar Wilayah',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                    ),
                    child: provider.wilayahList.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text('Belum ada wilayah.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: provider.wilayahList.length,
                            itemBuilder: (context, idx) {
                              final w = provider.wilayahList[idx];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(w.namaWilayah, style: const TextStyle(fontWeight: FontWeight.w500)),
                                trailing: InkWell(
                                  onTap: () async {
                                    final confirm = await showDialog<bool>(
                                      context: ctx,
                                      builder: (dialogCtx) => AlertDialog(
                                        title: const Text('Hapus Wilayah'),
                                        content: Text('Apakah Anda yakin ingin menghapus wilayah "${w.namaWilayah}"?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(dialogCtx, false),
                                            child: const Text('Batal'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(dialogCtx, true),
                                            child: const Text('Hapus', style: TextStyle(color: AppColors.danger)),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      try {
                                        final token = context.read<AuthProvider>().token ?? '';
                                        final success = await provider.deleteWilayah(token, w.id!);
                                        if (success) {
                                          if (_selectedWilayahId == w.id) {
                                            setState(() {
                                              _selectedWilayahId = null;
                                            });
                                          }
                                          ScaffoldMessenger.of(ctx).showSnackBar(
                                            const SnackBar(
                                              content: Text('Wilayah berhasil dihapus!'),
                                              backgroundColor: AppColors.success,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(
                                          const SnackBar(
                                            content: Text('Wilayah tidak bisa dihapus karena sedang digunakan oleh data leads.'),
                                            backgroundColor: AppColors.danger,
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.danger.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final leadsProvider = context.watch<LeadsProvider>();
    final authProvider = context.watch<AuthProvider>();
    final isTour = authProvider.userBagian == 'tour';

    return Scaffold(
      appBar: AppBar(
        title: Text(isTour ? 'Input Data Leads Tour' : 'Input Data Leads Marketing'),
      ),
      body: leadsProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!isTour) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Wilayah Pariwisata',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onBackground,
                                      letterSpacing: -0.1,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _showManageWilayahBottomSheet(context),
                                    icon: const Icon(Icons.edit_location_alt_rounded, size: 14, color: AppColors.secondary),
                                    label: const Text(
                                      'Kelola Wilayah',
                                      style: TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.bold),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              CustomDropdown<int?>(
                                label: '',
                                value: _selectedWilayahId,
                                hint: 'Pilih Wilayah Tujuan',
                                items: leadsProvider.wilayahList.map((w) {
                                  return DropdownMenuItem<int?>(
                                    value: w.id,
                                    child: Text(w.namaWilayah),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedWilayahId = val;
                                  });
                                },
                              ),
                            ] else ...[
                              const Text(
                                'Lokasi / Daerah Tujuan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onBackground,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              CustomDropdown<String?>(
                                label: '',
                                value: _selectedLokasi,
                                hint: 'Pilih Lokasi Tujuan',
                                items: _tourLocations.map((loc) {
                                  return DropdownMenuItem<String?>(
                                    value: loc,
                                    child: Text(loc),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedLokasi = val;
                                  });
                                },
                              ),
                            ],
                            const SizedBox(height: 20),
                            CustomDropdown<int?>(
                              label: 'Sumber Leads',
                              value: _selectedSumberId,
                              hint: 'Pilih Sumber Leads',
                              items: leadsProvider.sumberLeadsList.map((s) {
                                return DropdownMenuItem<int?>(
                                  value: s.id,
                                  child: Text(s.namaSumber),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedSumberId = val;
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Tanggal',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onBackground,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _selectDate(context),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 18),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'PILIH TANGGAL',
                                                style: TextStyle(
                                                  fontSize: 8.5,
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                DateFormat('dd MMMM yyyy').format(_selectedDate),
                                                style: const TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.onBackground,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (!isTour) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Jumlah Leads',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onBackground,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _jumlahController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: 'Masukkan jumlah leads',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Jumlah leads wajib diisi';
                                      }
                                      final number = int.tryParse(value);
                                      if (number == null) {
                                        return 'Hanya angka yang diperbolehkan';
                                      }
                                      if (number < 0) {
                                        return 'Minimal 0';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ] else ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Nama / Instansi Client',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onBackground,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _namaClientController,
                                    decoration: const InputDecoration(
                                      hintText: 'Contoh: SMA 1 Surabaya / Bpk. Adi',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Nama/Instansi client wajib diisi';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Asal Client (Kota)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onBackground,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _asalClientController,
                                    decoration: const InputDecoration(
                                      hintText: 'Contoh: Sidoarjo',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Asal client wajib diisi';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Nomor HP Client',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.onBackground,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _noHpClientController,
                                    keyboardType: TextInputType.phone,
                                    decoration: const InputDecoration(
                                      hintText: 'Contoh: 08123456789',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Nomor HP client wajib diisi';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Simpan Data',
                      icon: Icons.save_rounded,
                      isLoading: _isSaving,
                      onPressed: _saveLead,
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }
}
