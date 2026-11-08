// lib/models/scan_record.dart
/// Model log pemindaian fisik untuk file SBD (Reguler) dan SBDE (Evaluasi/Koreksi).
class ScanRecord {
  final int? id;
  final String sessionId;           // ID sesi SO (misal: SO260912T79D)
  final String prdcd;               // PLU barang (8 digit)
  final int ttl;                    // Kuantitas scan (positif/negatif)
  final int lokasi;                 // 1: Toko, 2: Gudang
  final String sotgl;               // Tanggal SO (YYYY-MM-DD 00:00:00)
  final String sotime;              // Jam SO (HH:mm:ss)
  final String nik;                 // NIK petugas scan
  final String nama;                // Nama petugas scan
  final String? nikPemegangShift;   // NIK supervisor (khusus SBDE)
  final String? namaPemegangShift;  // Nama supervisor (khusus SBDE)
  final bool isEvaluasi;            // True jika masuk log evaluasi (SBDE)

  ScanRecord({
    this.id,
    required this.sessionId,
    required this.prdcd,
    required this.ttl,
    required this.lokasi,
    required this.sotgl,
    required this.sotime,
    required this.nik,
    required this.nama,
    this.nikPemegangShift,
    this.namaPemegangShift,
    this.isEvaluasi = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'prdcd': prdcd,
      'ttl': ttl,
      'lokasi': lokasi,
      'sotgl': sotgl,
      'sotime': sotime,
      'nik': nik,
      'nama': nama,
      'nik_pemegang_shift': nikPemegangShift,
      'nama_pemegang_shift': namaPemegangShift,
      'is_evaluasi': isEvaluasi ? 1 : 0,
    };
  }

  factory ScanRecord.fromMap(Map<String, dynamic> map) {
    return ScanRecord(
      id: map['id'],
      sessionId: map['session_id'] ?? '',
      prdcd: map['prdcd'] ?? '',
      ttl: map['ttl'] ?? 0,
      lokasi: map['lokasi'] ?? 1,
      sotgl: map['sotgl'] ?? '',
      sotime: map['sotime'] ?? '',
      nik: map['nik'] ?? '',
      nama: map['nama'] ?? '',
      nikPemegangShift: map['nik_pemegang_shift'],
      namaPemegangShift: map['nama_pemegang_shift'],
      isEvaluasi: (map['is_evaluasi'] ?? 0) == 1,
    );
  }

  /// Menghasilkan format baris pipe-delimited untuk file SBD
  String toSbdLine() {
    return '$prdcd|$ttl|$lokasi|$sotgl|$sotime|$nik|$nama';
  }

  /// Menghasilkan format baris pipe-delimited untuk file SBDE
  String toSbdeLine() {
    final nShift = nikPemegangShift ?? '';
    final nmShift = namaPemegangShift ?? '';
    return '$prdcd|$ttl|$lokasi|$sotgl|$sotime|$nik|$nama|$nShift|$nmShift';
  }
}
