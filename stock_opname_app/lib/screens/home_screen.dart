// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'scanner_screen.dart';
import 'export_screen.dart';

/// Halaman utama (Dashboard) aplikasi Stock Opname Mobile.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nikController = TextEditingController(text: '2015136329');
  final _namaController = TextEditingController(text: 'MOHAMMAD BAYU');
  final _storeCodeController = TextEditingController(text: 'TU4N');
  int _selectedLokasi = 1; // 1: Toko, 2: Gudang

  String get _currentSessionId => 'SO_${_storeCodeController.text.trim()}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock Opname Retail (Offline)"),
        backgroundColor: Colors.blue[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory_2, size: 40, color: Colors.blue[800]),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Mode Operasional: Mandiri / Offline", style: TextStyle(fontWeight: FontWeight.bold)),
                        Text("Scan barcode barang via kamera HP & ekspor data persis file ritel (SBD, SB, SBE, SBDE).", style: TextStyle(fontSize: 12, color: Colors.black87)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Form Pengaturan Petugas & Toko
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Informasi Sesi Stock Opname", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _storeCodeController,
                      decoration: const InputDecoration(
                        labelText: "Kode Toko (Contoh: TU4N / T79D / T94Q)",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nikController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "NIK Petugas Scan",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _namaController,
                      decoration: const InputDecoration(
                        labelText: "Nama Petugas Scan",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Area Hitung Fisik:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<int>(
                            title: const Text("1: Toko"),
                            value: 1,
                            groupValue: _selectedLokasi,
                            onChanged: (val) => setState(() => _selectedLokasi = val!),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<int>(
                            title: const Text("2: Gudang"),
                            value: 2,
                            groupValue: _selectedLokasi,
                            onChanged: (val) => setState(() => _selectedLokasi = val!),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Aksi Utama
            ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner, size: 28),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text("Mulai Scan Fisik (SBD)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => ScannerScreen(
                      sessionId: _currentSessionId,
                      storeCode: _storeCodeController.text.trim(),
                      nik: _nikController.text.trim(),
                      nama: _namaController.text.trim(),
                      lokasi: _selectedLokasi,
                      isEvaluasi: false,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              icon: const Icon(Icons.published_with_changes, color: Colors.orange),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text("Mulai Scan Evaluasi Shift (SBDE)", style: TextStyle(fontSize: 15, color: Colors.orange, fontWeight: FontWeight.bold)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => ScannerScreen(
                      sessionId: _currentSessionId,
                      storeCode: _storeCodeController.text.trim(),
                      nik: _nikController.text.trim(),
                      nama: _namaController.text.trim(),
                      lokasi: _selectedLokasi,
                      isEvaluasi: true,
                      nikShift: '2015019281',
                      namaShift: 'SUPERVISOR SHIFT',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              icon: const Icon(Icons.file_download, color: Colors.white),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text("Rekap & Ekspor 4 File (SBD/SBDE/SB/SBE)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => ExportScreen(
                      sessionId: _currentSessionId,
                      storeCode: _storeCodeController.text.trim(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
