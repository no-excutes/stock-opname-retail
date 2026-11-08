// lib/screens/summary_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import '../services/export_service.dart';

class SummaryScreen extends StatefulWidget {
  final String sessionId;
  final String storeCode;

  const SummaryScreen({super.key, required this.sessionId, required this.storeCode});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _isLoading = true;
  List<VarianceItem> _items = [];

  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    final data = await DbHelper.instance.getVarianceAnalysis(widget.sessionId);
    setState(() {
      _items = data;
      _isLoading = false;
    });
  }

  Future<void> _exportFile(String type) async {
    final yymmdd = DateFormat('yyMMdd').format(DateTime.now());
    final ddmmyyyy = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final hhmmss = DateFormat('HH:mm:ss').format(DateTime.now());

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Menghasilkan file $type...")));

    try {
      File file;
      switch (type) {
        case 'SBD':
          file = await ExportService.exportSbd(sessionId: widget.sessionId, storeCode: widget.storeCode, yymmdd: yymmdd);
          break;
        case 'SBDE':
          file = await ExportService.exportSbde(sessionId: widget.sessionId, storeCode: widget.storeCode, yymmdd: yymmdd);
          break;
        case 'SB':
          file = await ExportService.exportSb(sessionId: widget.sessionId, storeCode: widget.storeCode, yymmdd: yymmdd, soDateFormatted: ddmmyyyy, soTimeFormatted: hhmmss);
          break;
        case 'SBE':
          file = await ExportService.exportSbe(sessionId: widget.sessionId, storeCode: widget.storeCode, yymmdd: yymmdd, soDateFormatted: ddmmyyyy, soTimeFormatted: hhmmss);
          break;
        default:
          throw Exception("Tipe tidak dikenal");
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Berhasil membuat ${file.path.split('/').last}")));
      await ExportService.shareFile(file, "Laporan $type Toko ${widget.storeCode}");
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error ekspor: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final totalSKU = _items.length;
    final klopItems = _items.where((i) => i.isKlop).toList();
    final lebihItems = _items.where((i) => i.isLebih).toList();
    final kurangItems = _items.where((i) => i.isKurang).toList();

    int totalQtyLebih = lebihItems.fold(0, (sum, i) => sum + i.selisihQty);
    double totalRpLebih = lebihItems.fold(0.0, (sum, i) => sum + i.selisihRp);

    int totalQtyKurang = kurangItems.fold(0, (sum, i) => sum + i.selisihQty);
    double totalRpKurang = kurangItems.fold(0.0, (sum, i) => sum + i.selisihRp);

    int netQty = totalQtyLebih + totalQtyKurang;
    double netRp = totalRpLebih + totalRpKurang;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Langkah 5: Rekapitulasi Final & Ekspor"),
        backgroundColor: Colors.teal[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scorecard Utama
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text("HASIL AKHIR REKONSILIASI STOK OPNAME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total SKU Toko:", style: TextStyle(fontSize: 14)),
                        Text("$totalSKU Barang", style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Barang Klop (Sesuai):", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        Text("${klopItems.length} SKU", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Selisih Lebih (+):", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        Text("${lebihItems.length} SKU (+${totalQtyLebih} pcs | ${currencyFormat.format(totalRpLebih)})", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Selisih Kurang/Hilang (-):", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        Text("${kurangItems.length} SKU (${totalQtyKurang} pcs | ${currencyFormat.format(totalRpKurang)})", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("TOTAL SELISIH NETTO:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          "${netQty > 0 ? '+' : ''}$netQty pcs\n${currencyFormat.format(netRp)}",
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: netRp < 0 ? Colors.red : Colors.green),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Ekspor 4 File Format Standar Ritel:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            _buildExportBtn("Ekspor SBD (Log Fisik Putaran 1)", Colors.blue[800]!, () => _exportFile('SBD')),
            const SizedBox(height: 8),
            _buildExportBtn("Ekspor SBDE (Log Evaluasi Re-Check)", Colors.orange[800]!, () => _exportFile('SBDE')),
            const SizedBox(height: 8),
            _buildExportBtn("Ekspor SB (Master Komparasi 57 Kolom)", Colors.teal[800]!, () => _exportFile('SB')),
            const SizedBox(height: 8),
            _buildExportBtn("Ekspor SBE (Laporan Khusus Selisih)", Colors.deepPurple[800]!, () => _exportFile('SBE')),
          ],
        ),
      ),
    );
  }

  Widget _buildExportBtn(String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.download, color: Colors.white),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
    );
  }
}
