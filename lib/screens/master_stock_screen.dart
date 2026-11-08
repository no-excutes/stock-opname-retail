import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        _statusMessage = "Berhasil memuat $count produk master toko!";
      });
      widget.onDataLoaded();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = "Gagal memuat master: $e";
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
                          ? "Master data siap digunakan untuk hitung fisik."
                          : "Katalog toko belum dimuat.",
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
