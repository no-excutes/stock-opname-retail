import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/export_service.dart';

class ExportScreen extends StatefulWidget {
  final String sessionId;
  final String storeCode;

  const ExportScreen({
    super.key,
    required this.sessionId,
    required this.storeCode,
  });

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  bool _isLoading = false;
  String? _statusMessage;

  String get _yymmdd => DateFormat('yyMMdd').format(DateTime.now());
  String get _ddmmyyyy => DateFormat('dd-MM-yyyy').format(DateTime.now());
  String get _hhmmss => DateFormat('HH:mm:ss').format(DateTime.now());

  Future<void> _generateAndShare(String type) async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Menghasilkan file $type...";
    });

    try {
      File file;
      switch (type) {
        case 'SBD':
          file = await ExportService.exportSbd(
            sessionId: widget.sessionId,
            storeCode: widget.storeCode,
            yymmdd: _yymmdd,
          );
          break;
        case 'SBDE':
          file = await ExportService.exportSbde(
            sessionId: widget.sessionId,
            storeCode: widget.storeCode,
            yymmdd: _yymmdd,
          );
          break;
        case 'SB':
          file = await ExportService.exportSb(
            sessionId: widget.sessionId,
            storeCode: widget.storeCode,
            yymmdd: _yymmdd,
            soDateFormatted: _ddmmyyyy,
            soTimeFormatted: _hhmmss,
          );
          break;
        case 'SBE':
          file = await ExportService.exportSbe(
            sessionId: widget.sessionId,
            storeCode: widget.storeCode,
            yymmdd: _yymmdd,
            soDateFormatted: _ddmmyyyy,
            soTimeFormatted: _hhmmss,
          );
          break;
        default:
          throw Exception("Tipe file tidak dikenal");
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _statusMessage = "File berhasil dibuat: ${file.path.split('/').last}";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File disimpan di memori HP")),
      );

      await ExportService.shareFile(file, "Laporan $type Toko ${widget.storeCode}");
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _statusMessage = "Gagal ekspor: $e";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ekspor File Stock Opname"),
        backgroundColor: Colors.blue[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Kode Toko: ${widget.storeCode}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text("ID Sesi: ${widget.sessionId}"),
                    Text("Tanggal: $_ddmmyyyy"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Pilih Format File yang Akan Diekspor:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildExportCard(
              title: "1. File SBD (Detail Scan Fisik)",
              desc: "Format pipe-delimited hasil scan reguler per item dan lokasi rak.",
              btnLabel: "Ekspor & Bagikan SBD",
              color: Colors.blue[700]!,
              onTap: () => _generateAndShare('SBD'),
            ),
            const SizedBox(height: 12),
            _buildExportCard(
              title: "2. File SBDE (Detail Evaluasi Shift)",
              desc: "Format scan evaluasi dan koreksi selisih per shift pemegang toko.",
              btnLabel: "Ekspor & Bagikan SBDE",
              color: Colors.orange[800]!,
              onTap: () => _generateAndShare('SBDE'),
            ),
            const SizedBox(height: 12),
            _buildExportCard(
              title: "3. File SB (Master Komparasi Toko)",
              desc: "File 57 kolom lengkap berisi selisih fisik vs sistem untuk POS back-office.",
              btnLabel: "Ekspor & Bagikan SB",
              color: Colors.teal[800]!,
              onTap: () => _generateAndShare('SB'),
            ),
            const SizedBox(height: 12),
            _buildExportCard(
              title: "4. File SBE (Evaluasi Selisih Saja)",
              desc: "File rekap item yang memiliki selisih kuantitas untuk verifikasi audit.",
              btnLabel: "Ekspor & Bagikan SBE",
              color: Colors.deepPurple[700]!,
              onTap: () => _generateAndShare('SBE'),
            ),
            const Spacer(),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_statusMessage != null)
              Text(
                _statusMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCard({
    required String title,
    required String desc,
    required String btnLabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: color),
              onPressed: _isLoading ? null : onTap,
              child: const Text("Ekspor", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
