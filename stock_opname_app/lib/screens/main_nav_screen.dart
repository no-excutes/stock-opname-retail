// lib/screens/main_nav_screen.dart
import 'package:flutter/material.dart';
import 'master_stock_screen.dart';
import 'scanner_screen.dart';
import 'variance_screen.dart';
import 'summary_screen.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _currentIndex = 0;
  final String _sessionId = "SO_TU4N";
  final String _storeCode = "TU4N";
  final String _nik = "2012030817";
  final String _nama = "Wahyu Indra Kurniawan";

  @override
  Widget build(BuildContext context) {
    final screens = [
      MasterStockScreen(onDataLoaded: () => setState(() {})),
      ScannerScreen(
        sessionId: _sessionId,
        storeCode: _storeCode,
        nik: _nik,
        nama: _nama,
        lokasi: 1,
        isEvaluasi: false,
      ),
      VarianceScreen(
        sessionId: _sessionId,
        storeCode: _storeCode,
        nik: _nik,
        nama: _nama,
      ),
      SummaryScreen(
        sessionId: _sessionId,
        storeCode: _storeCode,
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.file_upload_outlined),
            selectedIcon: Icon(Icons.file_upload),
            label: "1. Impor Stok",
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: "2. Hitung Fisik",
          ),
          NavigationDestination(
            icon: Icon(Icons.compare_arrows_outlined),
            selectedIcon: Icon(Icons.compare_arrows),
            label: "3. Re-SO Selisih",
          ),
          NavigationDestination(
            icon: Icon(Icons.assessment_outlined),
            selectedIcon: Icon(Icons.assessment),
            label: "4. Rekap & Ekspor",
          ),
        ],
      ),
    );
  }
}
