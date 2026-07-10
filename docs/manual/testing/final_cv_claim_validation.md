# Final CV Claim Validation

Dokumen ini merangkum status klaim CV MoneyPilot setelah Tahap 15.

## Status Klaim CV

1. Pencatatan pemasukan dan pengeluaran harian
   - Status: siap demo

2. Voice input Bahasa Indonesia
   - Status: siap demo terbatas perangkat
   - Catatan: tetap perlu manual test di perangkat fisik

3. Offline-first local storage dengan Isar
   - Status: siap demo

4. Category management
   - Status: siap demo

5. Google Spreadsheet two-way sync
   - Status: siap demo lebih kuat
   - Catatan: Tahap 15 tidak mengubah Google Apps Script dan tidak merusak sync Tahap 14

6. Flask backend untuk market price data
   - Status: naik menjadi siap demo defensible
   - Bukti:
     - provider architecture backend jelas
     - provider `mock` tetap tersedia
     - provider eksternal `eodhd` opsional via `.env`
     - symbol dinormalisasi `BBCA -> BBCA.JK`
     - cache, timeout, fallback, dan error JSON sudah rapi
     - Flutter menampilkan sumber data, fallback, dan disclaimer secara jujur
   - Batasan jujur:
     - data market masih bersifat estimasi
     - tidak ada fitur trading
     - tidak ada rekomendasi investasi

7. Portofolio, dividen, watchlist, berita, dan analisis edukatif
   - Status: fondasi kuat
   - Catatan: tetap perlu manual validation lintas perangkat

## Ringkasan Tahap 15

- Backend market data kini memakai abstraction provider sederhana
- Mode `mock` dan mode eksternal `eodhd` bisa dipilih dari `.env`
- Fallback ke mock tersedia saat provider eksternal gagal
- Flutter membedakan sumber data real, mock, fallback, dan stale
- Backend hanya menerima symbol saham dan tidak menerima data pribadi user

## Manual Test Market Data di HP Fisik

1. Jalankan backend dengan `BACKEND_HOST=0.0.0.0`.
2. Pastikan HP dan laptop ada di jaringan Wi-Fi yang sama.
3. Jalankan Flutter dengan:
   `flutter run --dart-define=BACKEND_BASE_URL=http://IP_LAN_KOMPUTER:5000 --dart-define=MARKET_BACKEND_BASE_URL=http://IP_LAN_KOMPUTER:5000`
4. Buka tab `Portofolio` dan pastikan harga pasar muncul bila backend aktif.
5. Pastikan card menampilkan sumber data dan disclaimer estimasi.
6. Matikan backend, lalu buka ulang `Portofolio` dan `Analisis`.
7. Pastikan aplikasi tidak crash dan menampilkan pesan:
   `Server MoneyPilot belum dapat dihubungi. Data lokal tetap tersedia.`
8. Jika memakai mode eksternal, coba kosongkan API key atau putuskan internet backend.
9. Pastikan fallback mock tampil dengan label sumber data yang jujur.

## Gap Yang Masih Tersisa

- Manual regression di HP fisik belum dijalankan oleh Codex pada sesi ini
- Validasi provider eksternal real masih tergantung API key yang valid
- AI news impact analysis masih tetap perlu penguatan demo terpisah bila ingin klaim lebih tinggi
