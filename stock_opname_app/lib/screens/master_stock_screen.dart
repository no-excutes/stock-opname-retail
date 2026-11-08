// lib/screens/master_stock_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import '../database/db_helper.dart';

class MasterStockScreen extends StatefulWidget {
  final VoidCallback onDataLoaded;

  const MasterStockScreen({super.key, required this.onDataLoaded});

  @override
  State<MasterStockScreen> createState() => _MasterStockScreenState();
}

class _MasterStockScreenState extends State<MasterStockScreen> {
  int _productCount = 0;
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _checkCount();
  }

  Future<void> _checkCount() async {
    final count = await DbHelper.instance.getProductCount();
    setState(() => _productCount = count);
  }

  // Muat master data bawaan 5.795 item dari asset lokal
  Future<void> _loadBuiltInMaster() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Membaca 5.795 master produk ritel...";
    });

    try {
      final dataStr = await rootBundle.loadString('assets/master_sb.txt');
      final lines = const LineSplitter().convert(dataStr);
      final count = await DbHelper.instance.importFromSbLines(lines);

      setState(() {
        _isLoading = false;
        _productCount = count;
        _statusMessage = "Berhasil mengimpor $count produk master toko!";
      });
      widget.onDataLoaded();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Gagal memuat master bawaan: $e";
      });
    }
  }

  // Impor file SB Excel baru (.xlsx) dari HP
  Future<void> _pickAndImportExcel() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'txt', 'csv'],
      );

      if (result == null || result.files.single.path == null) return;

      setState(() {
        _isLoading = true;
        _statusMessage = "Memproses file: ${result.files.single.name}...";
      });

      final filePath = result.files.single.path!;
      final file = File(filePath);
      List<String> lines = [];

      if (filePath.endsWith('.xlsx')) {
        final bytes = await file.readAsBytes();
        final excel = Excel.decodeBytes(bytes);
        final sheetName = excel.tables.keys.first;
        final sheet = excel.tables[sheetName];

        if (sheet != null) {
          for (var row in sheet.rows) {
            if (row.isNotEmpty && row[0]?.value != null) {
              lines.add(row[0]!.value.toString());
            }
          }
        }
      } else {
        lines = await file.readAsLines();
      }

      final count = await DbHelper.instance.importFromSbLines(lines);

      setState(() {
        _isLoading = false;
        _productCount = count;
        _statusMessage = "Berhasil mengimpor $count item dari ${result.files.single.name}";
      });
      widget.onDataLoaded();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Gagal impor file: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Langkah 1: Impor Data Stok"),
        backgroundColor: Colors.blue[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue[50],
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 50, color: Colors.blue[800]),
                    const SizedBox(height: 8),
                    const Text("Status Master Data Produk", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      "$_productCount SKU Terdaftar di HP",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _productCount > 0
                          ? "Master data siap digunakan untuk penghitungan fisik."
                          : "Silakan impor master stok toko terlebih dahulu.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.flash_on, color: Colors.amber),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text("Muat Master Toko Bawaan (5.795 Item)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isLoading ? null : _loadBuiltInMaster,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.file_upload, color: Colors.blue),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text("Pilih File Excel SB Klien (.xlsx)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.blue[800]!, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isLoading ? null : _pickAndImportExcel,
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
