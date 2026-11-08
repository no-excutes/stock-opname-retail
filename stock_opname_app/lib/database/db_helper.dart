// lib/database/db_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/scan_record.dart';

class VarianceItem {
  final Product product;
  final int ttlToko;
  final int ttlGudang;
  final int totalFisik;
  final int com;
  final int selisihQty;
  final double selisihRp;

  VarianceItem({
    required this.product,
    required this.ttlToko,
    required this.ttlGudang,
    required this.totalFisik,
    required this.com,
    required this.selisihQty,
    required this.selisihRp,
  });

  bool get isKlop => selisihQty == 0;
  bool get isLebih => selisihQty > 0;
  bool get isKurang => selisihQty < 0;
}

class DbHelper {
  static final DbHelper instance = DbHelper._init();
  static Database? _database;

  DbHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('stock_opname.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        prdcd TEXT PRIMARY KEY,
        barcode TEXT,
        barcode2 TEXT,
        desc TEXT,
        singkat TEXT,
        tiperak TEXT,
        norak TEXT,
        noshelf TEXT,
        kirikanan TEXT,
        div TEXT,
        cat_cod TEXT,
        unit TEXT,
        price REAL,
        acost REAL,
        com_qty INTEGER
      )
    ''');

    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    await db.execute('CREATE INDEX idx_products_barcode2 ON products(barcode2)');

    await db.execute('''
      CREATE TABLE scan_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT,
        prdcd TEXT,
        ttl INTEGER,
        lokasi INTEGER,
        sotgl TEXT,
        sotime TEXT,
        nik TEXT,
        nama TEXT,
        nik_pemegang_shift TEXT,
        nama_pemegang_shift TEXT,
        is_evaluasi INTEGER DEFAULT 0
      )
    ''');
  }

  // Import lines of SB pipe-delimited file in batch
  Future<int> importFromSbLines(List<String> lines) async {
    final db = await database;
    final batch = db.batch();
    int count = 0;

    for (var line in lines) {
      final parts = line.split('|');
      if (parts.length >= 40) {
        // Skip header
        if (parts[0] == 'RECID' || parts[6] == 'PRDCD') continue;

        final prdcd = parts[6].trim();
        if (prdcd.isEmpty) continue;

        final product = Product(
          prdcd: prdcd,
          tiperak: parts[1].trim(),
          norak: parts[2].trim(),
          noshelf: parts[3].trim(),
          kirikanan: parts[4].trim(),
          div: parts[5].trim(),
          desc: parts[7].trim(),
          singkat: parts[8].trim(),
          barcode: parts[9].trim(),
          barcode2: parts[10].trim(),
          unit: parts[12].trim().isEmpty ? 'PCS' : parts[12].trim(),
          catCod: parts[14].trim(),
          acost: double.tryParse(parts[19].trim()) ?? 0.0,
          price: double.tryParse(parts[22].trim()) ?? 0.0,
          comQty: int.tryParse(parts[39].trim()) ?? 0,
        );

        batch.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
        count++;
      }
    }

    await batch.commit(noResult: true);
    return count;
  }

  Future<int> getProductCount() async {
    final db = await database;
    final res = await db.rawQuery('SELECT COUNT(*) as cnt FROM products');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  Future<Product?> findProduct(String code) async {
    final db = await database;
    final res = await db.query(
      'products',
      where: 'barcode = ? OR barcode2 = ? OR prdcd = ?',
      whereArgs: [code, code, code],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return Product.fromMap(res.first);
    }
    return null;
  }

  Future<int> insertScan(ScanRecord record) async {
    final db = await database;
    return await db.insert('scan_records', record.toMap());
  }

  Future<List<ScanRecord>> getScans({required String sessionId, bool? isEvaluasi}) async {
    final db = await database;
    String? whereClause = 'session_id = ?';
    List<dynamic> whereArgs = [sessionId];

    if (isEvaluasi != null) {
      whereClause += ' AND is_evaluasi = ?';
      whereArgs.add(isEvaluasi ? 1 : 0);
    }

    final res = await db.query(
      'scan_records',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'id DESC',
    );
    return res.map((e) => ScanRecord.fromMap(e)).toList();
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final res = await db.query('products', orderBy: 'norak ASC, noshelf ASC');
    return res.map((e) => Product.fromMap(e)).toList();
  }

  // Hitung komparasi fisik vs sistem untuk seluruh produk
  Future<List<VarianceItem>> getVarianceAnalysis(String sessionId) async {
    final db = await database;
    final products = await getAllProducts();

    final scanRes = await db.rawQuery('''
      SELECT prdcd, lokasi, SUM(ttl) as total_qty
      FROM scan_records
      WHERE session_id = ?
      GROUP BY prdcd, lokasi
    ''', [sessionId]);

    Map<String, Map<String, int>> scanSummary = {};
    for (var row in scanRes) {
      final prdcd = row['prdcd'] as String;
      final lokasi = row['lokasi'] as int;
      final qty = (row['total_qty'] as num?)?.toInt() ?? 0;

      scanSummary.putIfAbsent(prdcd, () => {'toko': 0, 'gudang': 0});
      if (lokasi == 1) {
        scanSummary[prdcd]!['toko'] = (scanSummary[prdcd]!['toko'] ?? 0) + qty;
      } else {
        scanSummary[prdcd]!['gudang'] = (scanSummary[prdcd]!['gudang'] ?? 0) + qty;
      }
    }

    List<VarianceItem> items = [];
    for (var prod in products) {
      final summary = scanSummary[prod.prdcd] ?? {'toko': 0, 'gudang': 0};
      final ttlToko = summary['toko'] ?? 0;
      final ttlGudang = summary['gudang'] ?? 0;
      final totalFisik = ttlToko + ttlGudang;
      final com = prod.comQty;
      final selisihQty = totalFisik - com;
      final selisihRp = selisihQty * prod.acost;

      items.add(VarianceItem(
        product: prod,
        ttlToko: ttlToko,
        ttlGudang: ttlGudang,
        totalFisik: totalFisik,
        com: com,
        selisihQty: selisihQty,
        selisihRp: selisihRp,
      ));
    }

    return items;
  }
}
