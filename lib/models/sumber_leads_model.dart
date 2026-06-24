class SumberLeadsModel {
  final int? id;
  final String namaSumber;

  SumberLeadsModel({
    this.id,
    required this.namaSumber,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'nama_sumber': namaSumber,
    };
  }

  factory SumberLeadsModel.fromMap(Map<String, dynamic> map) {
    return SumberLeadsModel(
      id: map['id'] as int?,
      namaSumber: map['nama_sumber'] as String,
    );
  }
}
