// lib/database/db_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/scan_record.dart';

/// Database Manager berbasis SQLite offline-first di smartphone Android.
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
    // 1. Tabel Master Produk
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

    // 2. Index untuk pencarian barcode instan
    await db.execute('CREATE INDEX idx_products_barcode ON products(barcode)');
    await db.execute('CREATE INDEX idx_products_barcode2 ON products(barcode2)');

    // 3. Tabel Log Scan Transaksi (SBD & SBDE)
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

    // Seed beberapa data contoh untuk mempermudah testing pemula
    await _seedDemoProducts(db);
  }

  Future<void> _seedDemoProducts(Database db) async {
    final demoItems = [
      Product(
        prdcd: '10000021',
        barcode: '8992702000025',
        barcode2: '18992702000022',
        desc: 'CAP ENAK KENTAL MANIS PUTIH 370g KLG',
        singkat: 'ENAK K/MNS PUTIH 370',
        tiperak: 'A',
        norak: '30441',
        noshelf: '9',
        kirikanan: '9',
        div: '02',
        catCod: '010201',
        unit: 'KLG',
        price: 11700,
        acost: 9678,
        comQty: 1,
      ),
      Product(
        prdcd: '10000052',
        barcode: '8999918181685',
        barcode2: '18999918457169',
        desc: 'AIM CRACKERS CRISPY 150g PCK',
        singkat: 'AIM CRACK CRISPY 150',
        tiperak: 'A',
        norak: '48996',
        noshelf: '34',
        kirikanan: '5',
        div: '11',
        catCod: '011104',
        unit: 'PCK',
        price: 10900,
        acost: 6943,
        comQty: 2,
      ),
      Product(
        prdcd: '10000060',
        barcode: '8992903113203',
        barcode2: '',
        desc: 'JEMPOL SAMBAL PEDAS 320mL BTL',
        singkat: 'JEMPOL SMBL PDS 320',
        tiperak: 'A',
        norak: '58786',
        noshelf: '12',
        kirikanan: '14',
        div: '07',
        catCod: '010706',
        unit: 'BTL',
        price: 23300,
        acost: 16917,
        comQty: 3,
      ),
      Product(
        prdcd: '10000069',
        barcode: '8995858999991',
        barcode2: '8995858999953',
        desc: 'MIXAGRIP OBAT SAKIT FLU (4)',
        singkat: 'MIXAGRIP O.SKT FLU4S',
        tiperak: 'A',
        norak: '57675',
        noshelf: '6',
        kirikanan: '11',
        div: '15',
        catCod: '021504',
        unit: 'STR',
        price: 4500,
        acost: 2779,
        comQty: 5,
      ),
    ];

    for (var item in demoItems) {
      await db.insert('products', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // Cari produk berdasarkan Barcode satuan, Barcode kartonan, atau PLU
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

  // Tambah log scan
  Future<int> insertScan(ScanRecord record) async {
    final db = await database;
    return await db.insert('scan_records', record.toMap());
  }

  // Ambil semua scan untuk sesi tertentu
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

  // Ambil rekap total kuantitas fisik per produk
  Future<Map<String, Map<String, int>>> getSummaryPerProduct(String sessionId) async {
    final db = await database;
    final res = await db.rawQuery('''
      SELECT prdcd, lokasi, SUM(ttl) as total_qty
      FROM scan_records
      WHERE session_id = ?
      GROUP BY prdcd, lokasi
    ''', [sessionId]);

    // Map: { prdcd: { 'toko': int, 'gudang': int } }
    Map<String, Map<String, int>> summary = {};
    for (var row in res) {
      final prdcd = row['prdcd'] as String;
      final lokasi = row['lokasi'] as int;
      final qty = (row['total_qty'] as num?)?.toInt() ?? 0;

      summary.putIfAbsent(prdcd, () => {'toko': 0, 'gudang': 0});
      if (lokasi == 1) {
        summary[prdcd]!['toko'] = (summary[prdcd]!['toko'] ?? 0) + qty;
      } else {
        summary[prdcd]!['gudang'] = (summary[prdcd]!['gudang'] ?? 0) + qty;
      }
    }
    return summary;
  }

  // Ambil semua master produk
  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final res = await db.query('products');
    return res.map((e) => Product.fromMap(e)).toList();
  }
}
