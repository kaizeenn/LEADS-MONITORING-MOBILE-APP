class LeadsModel {
  final int? id;
  final int wilayahId;
  final int sumberId;
  final String tanggal; // Format: YYYY-MM-DD
  final int jumlah;
  final String createdAt;
  final String? updatedAt;

  // Joined properties to display in table/reports
  final String? namaWilayah;
  final String? namaSumber;

  LeadsModel({
    this.id,
    required this.wilayahId,
    required this.sumberId,
    required this.tanggal,
    required this.jumlah,
    required this.createdAt,
    this.updatedAt,
    this.namaWilayah,
    this.namaSumber,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'wilayah_id': wilayahId,
      'sumber_id': sumberId,
      'tanggal': tanggal,
      'jumlah': jumlah,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory LeadsModel.fromMap(Map<String, dynamic> map) {
    return LeadsModel(
      id: map['id'] as int?,
      wilayahId: map['wilayah_id'] as int,
      sumberId: map['sumber_id'] as int,
      tanggal: map['tanggal'] as String,
      jumlah: map['jumlah'] as int,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String?,
      namaWilayah: map['nama_wilayah'] as String?,
      namaSumber: map['nama_sumber'] as String?,
    );
  }
}
