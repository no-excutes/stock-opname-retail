// lib/screens/scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';

import '../models/product.dart';
import '../models/scan_record.dart';
import '../database/db_helper.dart';

/// Halaman pemindai barcode menggunakan kamera HP bawaan.
class ScannerScreen extends StatefulWidget {
  final String sessionId;
  final String storeCode;
  final String nik;
  final String nama;
  final int lokasi; // 1: Toko, 2: Gudang
  final bool isEvaluasi;
  final String? nikShift;
  final String? namaShift;

  const ScannerScreen({
    Key? key,
    required this.sessionId,
    required this.storeCode,
    required this.nik,
    required this.nama,
    required this.lokasi,
    this.isEvaluasi = false,
    this.nikShift,
    this.namaShift,
  }) : super(key: key);

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  bool _isTorchOn = false;
  Product? _lastScannedProduct;
  int _lastScannedQty = 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code.trim().isEmpty) return;

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    await _processCode(code.trim());
  }

  Future<void> _processCode(String code) async {
    Product? product = await DbHelper.instance.findProduct(code);

    if (!mounted) return;

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Data berhasil dicatat"), duration: Duration(seconds: 1)));
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _isProcessing = false);
      return;
    }

    _showQtyDialog(product);
  }

  void _showQtyDialog(Product product) {
    final qtyCtrl = TextEditingController(text: '1');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(widget.isEvaluasi ? "Scan Koreksi Evaluasi" : "Input Jumlah Fisik"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(product.desc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text("PLU: ${product.prdcd} | Satuan: ${product.unit}"),
            Text("Rak: ${product.tiperak} / ${product.norak} / Shelf ${product.noshelf}"),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: "Jumlah Fisik (Qty)",
                helperText: widget.isEvaluasi ? "Gunakan minus (-) untuk koreksi" : "Kuantitas di rak",
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isProcessing = false);
            },
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
              Navigator.pop(ctx);
              await _saveScanRecord(product, qty);
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  Future<void> _saveScanRecord(Product product, int qty) async {
    final now = DateTime.now();
    final sotgl = DateFormat('yyyy-MM-dd 00:00:00').format(now);
    final sotime = DateFormat('HH:mm:ss').format(now);

    final record = ScanRecord(
      sessionId: widget.sessionId,
      prdcd: product.prdcd,
      ttl: qty,
      lokasi: widget.lokasi,
      sotgl: sotgl,
      sotime: sotime,
      nik: widget.nik,
      nama: widget.nama,
      nikPemegangShift: widget.nikShift,
      namaPemegangShift: widget.namaShift,
      isEvaluasi: widget.isEvaluasi,
    );

    await DbHelper.instance.insertScan(record);

    setState(() {
      _lastScannedProduct = product;
      _lastScannedQty = qty;
      _isProcessing = false;
    });

      msg: "Berhasil catat: ${product.singkat} ($qty)",
      backgroundColor: Colors.green,
      textColor: Colors.white,
    );
  }

  void _manualInputDialog() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Input Manual Barcode / PLU"),
        content: TextField(
          controller: codeCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Ketik Barcode atau PLU 8 digit",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeCtrl.text.trim();
              Navigator.pop(ctx);
              if (code.isNotEmpty) {
                _processCode(code);
              }
            },
            child: const Text("Cari"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEvaluasi ? "Scan Evaluasi (SBDE)" : "Scan Fisik (SBD)"),
        backgroundColor: widget.isEvaluasi ? Colors.orange[800] : Colors.blue[800],
        actions: [
          IconButton(
            icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
          IconButton(
            icon: const Icon(Icons.keyboard),
            tooltip: "Input Manual PLU",
            onPressed: _manualInputDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),
          Center(
            child: Container(
              width: 280,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Area: ${widget.lokasi == 1 ? '1 - Toko' : '2 - Gudang'}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "NIK: ${widget.nik}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          if (_lastScannedProduct != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Card(
                elevation: 6,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _lastScannedProduct!.desc,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "PLU: ${_lastScannedProduct!.prdcd} | Qty Terinput: $_lastScannedQty ${_lastScannedProduct!.unit}",
                              style: const TextStyle(color: Colors.black87, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
