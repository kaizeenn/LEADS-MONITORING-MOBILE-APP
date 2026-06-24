class WilayahModel {
  final int? id;
  final String namaWilayah;

  WilayahModel({
    this.id,
    required this.namaWilayah,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama_wilayah': namaWilayah,
    };
  }

  factory WilayahModel.fromMap(Map<String, dynamic> map) {
    return WilayahModel(
      id: map['id'] as int?,
      namaWilayah: map['nama_wilayah'] as String,
    );
  }
}
