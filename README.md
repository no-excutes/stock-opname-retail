# Stock Opname Retail Mobile (Offline-First Android App)

Aplikasi mobile Android untuk audit stok opname ritel/minimarket mandiri (*offline-first*) yang menggunakan kamera smartphone untuk memindai barcode fisik barang dan menghasilkan 4 format file standar ritel (SBD, SBDE, SB, dan SBE).

---

## 📁 Struktur Folder Proyek

```text
stock_opname_app/
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml      # Izin kamera, getar, & akses file
├── lib/
│   ├── main.dart                    # Titik masuk aplikasi
│   ├── models/
│   │   ├── product.dart             # Model Master Produk ritel
│   │   └── scan_record.dart         # Model Log Scan SBD & SBDE
│   ├── database/
│   │   └── db_helper.dart           # Database lokal SQLite offline-first
│   ├── services/
│   │   └── export_service.dart      # Generator 4 file Excel pipe-delimited
│   └── screens/
│       ├── home_screen.dart         # Dashboard pemilihan sesi & NIK
│       ├── scanner_screen.dart      # Pemindai barcode kamera HP & input manual
│       └── export_screen.dart       # Ekspor & bagikan file via WhatsApp/Email
└── pubspec.yaml                     # Dependensi paket Flutter
```

---

## 🎯 4 Format File Ritel yang Dihasilkan

Aplikasi ini menghasilkan file Excel (.xlsx) dengan 1 sheet bernama `'in'` dan setiap baris di kolom A berisi teks berpemisah pipa (`|`), sesuai dengan format asli:

1. **SBD (`SBD[YYMMDD][KodeToko].xlsx`)**:
   - Header: `PRDCD|TTL|Lokasi|SOTGL|SOTIME|NIK|Nama`
   - Berisi detail setiap scan fisik di area toko (1) atau gudang (2).

2. **SBDE (`SBDE[YYMMDD][KodeToko].xlsx`)**:
   - Header: `PRDCD|TTL|Lokasi|SOTGL|SOTIME|NIK|Nama|NIK_PEMEGANG_SHIFT|NAMA_PEMEGANG_SHIFT`
   - Berisi log evaluasi dan koreksi per shift (mendukung nilai kuantitas negatif untuk pembatalan/koreksi hitung).

3. **SB (`SB[YYMMDD][KodeToko].xlsx`)**:
   - Master komparasi komprehensif 57 kolom berpemisah pipa (`|`), mencakup kode rak, deskripsi, harga, TTL fisik (toko + gudang), saldo komputer, dan nilai selisih fisik vs komputer (`SELISIH_NEW`).

4. **SBE (`SBE[YYMMDD][KodeToko].xlsx`)**:
   - Laporan rekonsiliasi khusus item yang mengalami selisih (`SELISIH_NEW != 0`) untuk mempermudah pengecekan ulang audit.

---

## 🚀 Panduan Setup & Menjalankan di HP Android

### Prasyarat:
- Komputer / Laptop dengan [Flutter SDK](https://docs.flutter.dev/get-started/install) terpasang.
- Editor teks [VS Code](https://code.visualstudio.com/) atau Android Studio.
- Smartphone Android fisik + kabel data USB.

### Langkah-Langkah:
1. **Buka Proyek di VS Code**:
   Buka folder `stock_opname_app` di VS Code.
2. **Unduh Dependensi**:
   Jalankan perintah di terminal VS Code:
   ```bash
   flutter pub get
   ```
3. **Hubungkan HP Android**:
   - Aktifkan **Opsi Pengembang (Developer Options)** di HP Anda.
   - Aktifkan **USB Debugging**.
   - Colokkan HP ke laptop via kabel data, lalu pilih "Izinkan USB Debugging".
4. **Jalankan Aplikasi Langsung di HP**:
   ```bash
   flutter run
   ```
5. **Kompilasi Menjadi File Installer APK Mandiri**:
   Untuk membuat file APK yang bisa dibagikan langsung ke HP lain tanpa kabel data:
   ```bash
   flutter build apk --release
   ```
   File APK hasil kompilasi akan berada di:
   `build/app/outputs/flutter-apk/app-release.apk`
