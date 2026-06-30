class LeadsTourModel {
  final int? id;
  final String lokasi;
  final int sumberId;
  final int? userId;
  final String tanggal; // Format: YYYY-MM-DD
  final String namaClient;
  final String asalClient;
  final String noHpClient;
  final String createdAt;

  // Joined properties to display in UI
  final String? namaSumber;
  final String? namaInputter;

  LeadsTourModel({
    this.id,
    required this.lokasi,
    required this.sumberId,
    this.userId,
    required this.tanggal,
    required this.namaClient,
    required this.asalClient,
    required this.noHpClient,
    required this.createdAt,
    this.namaSumber,
    this.namaInputter,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'lokasi': lokasi,
      'sumber_id': sumberId,
      if (userId != null) 'user_id': userId,
      'tanggal': tanggal,
      'nama_client': namaClient,
      'asal_client': asalClient,
      'no_hp_client': noHpClient,
      'created_at': createdAt,
    };
  }

  factory LeadsTourModel.fromMap(Map<String, dynamic> map) {
    return LeadsTourModel(
      id: map['id'] as int?,
      lokasi: map['lokasi'] as String,
      sumberId: map['sumber_id'] as int,
      userId: map['user_id'] as int?,
      tanggal: map['tanggal'] as String,
      namaClient: map['nama_client'] as String,
      asalClient: map['asal_client'] as String,
      noHpClient: map['no_hp_client'] as String,
      createdAt: map['created_at'] as String,
      namaSumber: map['nama_sumber'] as String?,
      namaInputter: map['nama_inputter'] as String?,
    );
  }
}
