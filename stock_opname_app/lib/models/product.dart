// lib/models/product.dart
/// Model representasi data master produk ritel.
/// Menyimpan informasi PLU, Barcode satuan & kartonan, nama, harga, serta posisi rak.
class Product {
  final String prdcd;      // PLU 8 digit (misal: 10000021)
  final String barcode;    // Barcode satuan (EAN-13)
  final String barcode2;   // Barcode kartonan/dus (ITF-14 / EAN-14)
  final String desc;       // Nama panjang produk
  final String singkat;    // Nama pendek di struk kasir
  final String tiperak;    // Tipe rak (A/G/dll)
  final String norak;      // Nomor rak display
  final String noshelf;    // Nomor ambalan/susun rak
  final String kirikanan;  // Posisi kiri/kanan
  final String div;        // Kode divisi barang
  final String catCod;     // Kode kategori barang
  final String unit;       // Satuan jual (PCS, BTL, KLG, CTN)
  final double price;      // Harga jual
  final double acost;      // Harga pokok / HPP
  final int comQty;        // Kuantitas saldo sistem / komputer

  Product({
    required this.prdcd,
    required this.barcode,
    this.barcode2 = '',
    required this.desc,
    required this.singkat,
    this.tiperak = 'A',
    this.norak = '1',
    this.noshelf = '1',
    this.kirikanan = '0',
    this.div = '01',
    this.catCod = '010101',
    this.unit = 'PCS',
    this.price = 0.0,
    this.acost = 0.0,
    this.comQty = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'prdcd': prdcd,
      'barcode': barcode,
      'barcode2': barcode2,
      'desc': desc,
      'singkat': singkat,
      'tiperak': tiperak,
      'norak': norak,
      'noshelf': noshelf,
      'kirikanan': kirikanan,
      'div': div,
      'cat_cod': catCod,
      'unit': unit,
      'price': price,
      'acost': acost,
      'com_qty': comQty,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      prdcd: map['prdcd'] ?? '',
      barcode: map['barcode'] ?? '',
      barcode2: map['barcode2'] ?? '',
      desc: map['desc'] ?? '',
      singkat: map['singkat'] ?? '',
      tiperak: map['tiperak'] ?? 'A',
      norak: map['norak'] ?? '1',
      noshelf: map['noshelf'] ?? '1',
      kirikanan: map['kirikanan'] ?? '0',
      div: map['div'] ?? '01',
      catCod: map['cat_cod'] ?? '010101',
      unit: map['unit'] ?? 'PCS',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      acost: (map['acost'] as num?)?.toDouble() ?? 0.0,
      comQty: (map['com_qty'] as num?)?.toInt() ?? 0,
    );
  }
}
