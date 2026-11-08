// lib/screens/variance_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/db_helper.dart';
import 'scanner_screen.dart';

class VarianceScreen extends StatefulWidget {
  final String sessionId;
  final String storeCode;
  final String nik;
  final String nama;

  const VarianceScreen({
    super.key,
    required this.sessionId,
    required this.storeCode,
    required this.nik,
    required this.nama,
  });

  @override
  State<VarianceScreen> createState() => _VarianceScreenState();
}

class _VarianceScreenState extends State<VarianceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<VarianceItem> _allItems = [];
  bool _isLoading = true;
  String _searchQuery = '';

  final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await DbHelper.instance.getVarianceAnalysis(widget.sessionId);
    setState(() {
      _allItems = data;
      _isLoading = false;
    });
  }

  List<VarianceItem> _filterItems(int tabIndex) {
    var filtered = _allItems;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) =>
          item.product.desc.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.product.barcode.contains(_searchQuery) ||
          item.product.prdcd.contains(_searchQuery)).toList();
    }

    switch (tabIndex) {
      case 0: // Semua yang selisih (selisihQty != 0)
        return filtered.where((item) => !item.isKlop).toList();
      case 1: // Selisih Kurang / Hilang (selisihQty < 0)
        return filtered.where((item) => item.isKurang).toList();
      case 2: // Selisih Lebih (selisihQty > 0)
        return filtered.where((item) => item.isLebih).toList();
      case 3: // Klop (selisihQty == 0)
        return filtered.where((item) => item.isKlop).toList();
      default:
        return filtered;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selisihCount = _allItems.where((i) => !i.isKlop).length;
    final kurangCount = _allItems.where((i) => i.isKurang).length;
    final lebihCount = _allItems.where((i) => i.isLebih).length;
    final klopCount = _allItems.where((i) => i.isKlop).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Langkah 3 & 4: Monitor & Re-SO Selisih"),
        backgroundColor: Colors.orange[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: "Semua Selisih ($selisihCount)"),
            Tab(text: "Kurang/Minus ($kurangCount)"),
            Tab(text: "Lebih/Plus ($lebihCount)"),
            Tab(text: "Klop ($klopCount)"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Pencarian
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Cari PLU, Barcode, atau Nama Produk...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                ),
                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildListView(_filterItems(0), isReCheck: true),
                      _buildListView(_filterItems(1), isReCheck: true),
                      _buildListView(_filterItems(2), isReCheck: true),
                      _buildListView(_filterItems(3), isReCheck: false),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.orange[800],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text("Scan Evaluasi Item Selisih"),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => ScannerScreen(
                sessionId: widget.sessionId,
                storeCode: widget.storeCode,
                nik: widget.nik,
                nama: widget.nama,
                lokasi: 1,
                isEvaluasi: true,
                nikShift: '2015019281',
                namaShift: 'SUPERVISOR EVALUASI',
              ),
            ),
          );
          _loadData();
        },
      ),
    );
  }

  Widget _buildListView(List<VarianceItem> items, {required bool isReCheck}) {
    if (items.isEmpty) {
      return const Center(child: Text("Tidak ada item dalam kategori ini."));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (ctx, idx) {
        final item = items[idx];
        final color = item.isKlop
            ? Colors.green
            : (item.isLebih ? Colors.blue : Colors.red);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          elevation: 2,
          child: ListTile(
            title: Text(item.product.desc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("PLU: ${item.product.prdcd} | Rak: ${item.product.tiperak}/${item.product.norak}"),
                Text("Komputer: ${item.com} ${item.product.unit} | Fisik: ${item.totalFisik} ${item.product.unit}"),
                Text(
                  "Selisih: ${item.selisihQty > 0 ? '+' : ''}${item.selisihQty} ${item.product.unit} (${currencyFormat.format(item.selisihRp)})",
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            trailing: isReCheck
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[800]),
                    child: const Text("Re-SO", style: TextStyle(color: Colors.white, fontSize: 12)),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => ScannerScreen(
                            sessionId: widget.sessionId,
                            storeCode: widget.storeCode,
                            nik: widget.nik,
                            nama: widget.nama,
                            lokasi: 1,
                            isEvaluasi: true,
                            nikShift: '2015019281',
                            namaShift: 'SUPERVISOR EVALUASI',
                          ),
                        ),
                      );
                      _loadData();
                    },
                  )
                : const Icon(Icons.check_circle, color: Colors.green),
          ),
        );
      },
    );
  }
}
