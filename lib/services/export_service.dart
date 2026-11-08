// lib/services/export_service.dart
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/db_helper.dart';

/// Service untuk menghasilkan file Excel (.xlsx) dengan 1 kolom pipe-delimited
/// yang 100% identik dengan format standar ritel (SBD, SBDE, SB, SBE).
class ExportService {
  /// Ekspor file SBD (Log detail scan reguler)
  static Future<File> exportSbd({
    required String sessionId,
    required String storeCode,
    required String yymmdd,
  }) async {
    final scans = await DbHelper.instance.getScans(sessionId: sessionId, isEvaluasi: false);
    
    final excel = Excel.createExcel();
    final sheet = excel['in'];
    excel.delete('Sheet1'); // Hapus sheet default

    // Header baris pertama
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue('PRDCD|TTL|Lokasi|SOTGL|SOTIME|NIK|Nama');

    // Tulis setiap baris scan
    for (int i = 0; i < scans.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1)).value =
          TextCellValue(scans[i].toSbdLine());
    }

    final filename = 'SBD$yymmdd$storeCode.xlsx';
    return await _saveExcel(excel, filename);
  }

  /// Ekspor file SBDE (Log detail scan evaluasi per shift)
  static Future<File> exportSbde({
    required String sessionId,
    required String storeCode,
    required String yymmdd,
  }) async {
    final scans = await DbHelper.instance.getScans(sessionId: sessionId, isEvaluasi: true);
    
    final excel = Excel.createExcel();
    final sheet = excel['in'];
    excel.delete('Sheet1');

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue('PRDCD|TTL|Lokasi|SOTGL|SOTIME|NIK|Nama|NIK_PEMEGANG_SHIFT|NAMA_PEMEGANG_SHIFT');

    for (int i = 0; i < scans.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: i + 1)).value =
          TextCellValue(scans[i].toSbdeLine());
    }

    final filename = 'SBDE$yymmdd$storeCode.xlsx';
    return await _saveExcel(excel, filename);
  }

  /// Ekspor file SB (Master komparasi 57 kolom pipe-delimited)
  static Future<File> exportSb({
    required String sessionId,
    required String storeCode,
    required String yymmdd,
    required String soDateFormatted, // DD-MM-YYYY
    required String soTimeFormatted, // HH:mm:ss
  }) async {
    final products = await DbHelper.instance.getAllProducts();
    final summary = await DbHelper.instance.getSummaryPerProduct(sessionId);

    final excel = Excel.createExcel();
    final sheet = excel['in'];
    excel.delete('Sheet1');

    // 57 Kolom Header Standar SB
    const sbHeader = 'RECID|TIPERAK|NORAK|NOSHELF|KIRIKANAN|DIV|PRDCD|DESC|SINGKAT|BARCODE|BARCODE2|FRAC|UNIT|PTAG|CAT_COD|BKP|SUB_BKP|CTGR|KEMASAN|ACOST|LCOST|RCOST|PRICE|TTL|TTL1|TTL2|TTL_OLD|TTL1_OLD|TTL2_OLD|SALES|SALES_2|RETUR|RETUR_2|CANCEL_S|BPB|BPB_2|BPB_3|ADJ|RETUR_K|COM|HPP|SOID|EDIT|SOTYPE|SOTGL|SOTIME|ADJDT|ADJTIME|DRAFT|DCP|CTK|JAMDLHSO|JAMLHSO|BACABPB|FLAG|SELISIH_OLD|SELISIH_NEW';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue(sbHeader);

    int rowIndex = 1;
    for (var prod in products) {
      final prdSummary = summary[prod.prdcd] ?? {'toko': 0, 'gudang': 0};
      final ttl1 = prdSummary['toko'] ?? 0;
      final ttl2 = prdSummary['gudang'] ?? 0;
      final ttl = ttl1 + ttl2;
      final com = prod.comQty;
      final selisihNew = ttl - com;

      // Susun 57 kolom pipe-delimited
      final line = '|${prod.tiperak}|${prod.norak}|${prod.noshelf}|${prod.kirikanan}|${prod.div}|${prod.prdcd}|${prod.desc}|${prod.singkat}|${prod.barcode}|${prod.barcode2}|1|${prod.unit}||${prod.catCod}|T|Y|XX|${prod.unit}|${prod.acost}|${prod.acost}|${prod.acost}|${prod.price.toInt()}|$ttl|$ttl1|$ttl2|$ttl|$ttl1|$ttl2|0|0|0|0|0|0|0|0|0|0|$com|${prod.acost.toInt()}|L||1|$soDateFormatted|$soTimeFormatted|$soDateFormatted|$soTimeFormatted|1|1||$soDateFormatted 15:00:00|$soDateFormatted 17:00:00||0|$selisihNew|$selisihNew';

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
          TextCellValue(line);
      rowIndex++;
    }

    final filename = 'SB$yymmdd$storeCode.xlsx';
    return await _saveExcel(excel, filename);
  }

  /// Ekspor file SBE (Laporan evaluasi selisih barang saja)
  static Future<File> exportSbe({
    required String sessionId,
    required String storeCode,
    required String yymmdd,
    required String soDateFormatted,
    required String soTimeFormatted,
  }) async {
    final products = await DbHelper.instance.getAllProducts();
    final summary = await DbHelper.instance.getSummaryPerProduct(sessionId);

    final excel = Excel.createExcel();
    final sheet = excel['in'];
    excel.delete('Sheet1');

    const sbHeader = 'RECID|TIPERAK|NORAK|NOSHELF|KIRIKANAN|DIV|PRDCD|DESC|SINGKAT|BARCODE|BARCODE2|FRAC|UNIT|PTAG|CAT_COD|BKP|SUB_BKP|CTGR|KEMASAN|ACOST|LCOST|RCOST|PRICE|TTL|TTL1|TTL2|TTL_OLD|TTL1_OLD|TTL2_OLD|SALES|SALES_2|RETUR|RETUR_2|CANCEL_S|BPB|BPB_2|BPB_3|ADJ|RETUR_K|COM|HPP|SOID|EDIT|SOTYPE|SOTGL|SOTIME|ADJDT|ADJTIME|DRAFT|DCP|CTK|JAMDLHSO|JAMLHSO|BACABPB|FLAG|SELISIH_OLD|SELISIH_NEW';
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value =
        TextCellValue(sbHeader);

    int rowIndex = 1;
    for (var prod in products) {
      final prdSummary = summary[prod.prdcd] ?? {'toko': 0, 'gudang': 0};
      final ttl1 = prdSummary['toko'] ?? 0;
      final ttl2 = prdSummary['gudang'] ?? 0;
      final ttl = ttl1 + ttl2;
      final com = prod.comQty;
      final selisihNew = ttl - com;

      // Hanya masukkan item yang mengalami selisih (selisihNew != 0)
      if (selisihNew != 0) {
        final line = '|${prod.tiperak}|${prod.norak}|${prod.noshelf}|${prod.kirikanan}|${prod.div}|${prod.prdcd}|${prod.desc}|${prod.singkat}|${prod.barcode}|${prod.barcode2}|1|${prod.unit}|D|${prod.catCod}|T|Y|XX|${prod.unit}|${prod.acost}|${prod.acost}|${prod.acost}|${prod.price.toInt()}|$ttl|$ttl1|$ttl2|$ttl|$ttl1|$ttl2|0|0|0|0|0|0|0|0|0|0|$com|${prod.acost.toInt()}|A||1|$soDateFormatted|$soTimeFormatted|$soDateFormatted|$soTimeFormatted|1|1||$soDateFormatted 15:00:00|$soDateFormatted 17:00:00||0|$selisihNew|$selisihNew';

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
            TextCellValue(line);
        rowIndex++;
      }
    }

    final filename = 'SBE$yymmdd$storeCode.xlsx';
    return await _saveExcel(excel, filename);
  }

  /// Simpan file biner Excel ke folder penyimpanan smartphone
  static Future<File> _saveExcel(Excel excel, String filename) async {
    final bytes = excel.encode();
    if (bytes == null) throw Exception('Gagal melakukan encoding file Excel');

    Directory? dir;
    if (Platform.isAndroid) {
      dir = await getExternalStorageDirectory(); // App-specific external storage
    }
    dir ??= await getApplicationDocumentsDirectory();

    final filePath = '${dir.path}/$filename';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Buka dialog Share Sheet bawaan Android (WhatsApp, Email, Drive, dll)
  static Future<void> shareFile(File file, String subject) async {
    final xFile = XFile(file.path);
    await Share.shareXFiles([xFile], subject: subject);
  }
}
