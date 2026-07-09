# MODULAR_IMPLEMENTATION.md

# MoneyPilot — Modular Implementation Guide

## 1. Tujuan Dokumen

Dokumen ini menjadi panduan eksekusi bertahap untuk membangun aplikasi **MoneyPilot** menggunakan Codex atau asisten pemrograman AI lain.

MoneyPilot adalah aplikasi personal finance intelligence berbasis Flutter yang membantu pengguna mencatat keuangan harian, mencatat transaksi melalui suara Bahasa Indonesia, menyinkronkan data dua arah dengan Google Spreadsheet, memantau portofolio saham manual, mengambil harga saham melalui backend, serta membaca berita ekonomi dengan analisis dampak berbasis AI.

Tujuan utama dokumen ini adalah memastikan implementasi dilakukan secara:

- modular,
- bertahap,
- mudah diuji,
- tidak melebar dari scope MVP,
- tidak merusak fitur yang sudah selesai,
- dan selalu mengikuti dokumen `prd.md`, `user_flow.md`, `erd.md`, serta `DESIGN_SYSTEM.md`.

Codex tidak boleh membangun semua fitur sekaligus. Setiap tahap harus menghasilkan aplikasi yang tetap bisa dijalankan dan diuji.

---

## 2. Prinsip Implementasi Utama

### 2.1 Kerjakan Bertahap

Setiap tahap hanya boleh fokus pada satu kelompok fitur. Jika satu tahap terlalu besar, pecah menjadi sub-tahap.

Contoh buruk:

```text
Bangun seluruh aplikasi MoneyPilot lengkap dengan finance, voice, spreadsheet, backend, portfolio, dan AI analysis.
```

Contoh benar:

```text
Bangun fondasi Flutter project, routing, theme, bottom navigation, dan placeholder screen terlebih dahulu. Jangan implementasikan fitur bisnis dulu.
```

### 2.2 Aplikasi Harus Tetap Bisa Run Setelah Setiap Tahap

Setiap tahap wajib memenuhi kondisi berikut:

- `flutter pub get` berhasil.
- `flutter analyze` tidak menghasilkan error fatal.
- aplikasi bisa dibuka di emulator/perangkat fisik.
- navigasi utama tetap berjalan.
- fitur lama tidak hilang.

### 2.3 Jangan Menghapus Fitur Lama

Codex harus dilarang menghapus file, model, provider, repository, atau UI yang sudah berfungsi kecuali diminta secara eksplisit.

Instruksi wajib untuk Codex:

```text
Jangan hapus atau rewrite file besar tanpa alasan. Jika perlu mengubah file yang sudah ada, lakukan perubahan minimal dan jelaskan bagian yang diubah.
```

### 2.4 Ikuti Clean Architecture Sederhana

Struktur kode harus memisahkan:

- presentation layer,
- application/provider layer,
- domain/repository interface bila diperlukan,
- data layer,
- local database,
- remote service,
- utility/helper.

Untuk MVP, Clean Architecture tidak perlu terlalu berat. Prioritasnya adalah rapi, mudah dipahami, dan mudah dikembangkan.

### 2.5 Bahasa Aplikasi Sepenuhnya Bahasa Indonesia

Semua teks UI, tombol, label, error message, empty state, dan microcopy harus menggunakan Bahasa Indonesia.

Contoh:

```text
Beranda
Berita
Keuangan
Portofolio
Analisis
Tambah Transaksi
Konfirmasi Transaksi
Sinkronisasi Gagal
```

Bukan:

```text
Home
News
Finance
Portfolio
Analysis
Add Transaction
```

### 2.6 UI Mengikuti Design System

UI MoneyPilot harus minimalis putih, hitam, dan biru seperti aplikasi bank modern. Hindari terlalu banyak card. Gunakan whitespace, list bersih, separator tipis, dan komponen yang sederhana.

---

## 3. Stack Teknologi Final

### 3.1 Mobile App

```text
Framework: Flutter
Bahasa: Dart
State Management: Riverpod
Routing: go_router
Local Database: Isar
Authentication Lokal: local_auth untuk fingerprint/biometric
Charts: fl_chart
HTTP Client: dio atau http
Icons: lucide_icons atau package ikon minimalis sejenis
Fonts: google_fonts dengan Inter atau Plus Jakarta Sans
```

### 3.2 Local Database

```text
Database: Isar
Identitas utama lintas sistem: UUIDv4
Delete strategy: soft delete
Sync marker: syncStatus / isSynced / lastSyncedAt
Conflict strategy: latest updatedAt wins
```

### 3.3 Google Spreadsheet Sync

```text
Bridge: Google Apps Script Web App
Sync mode: dua arah sejak MVP
Operation: upsert by UUID
Security: secret token
Conflict resolution: latest updatedAt wins
```

### 3.4 Backend

```text
Framework: Flask
Bahasa: Python
Cache DB: SQLite
Fungsi utama:
- menyimpan API key secara aman
- mengambil berita Google News RSS
- mengambil data harga saham/market
- melakukan caching
- menjalankan AI news impact analysis
```

### 3.5 AI Backend

```text
Fungsi:
- menganalisis dampak berita
- menghasilkan impact score
- menghasilkan confidence score
- menyebutkan data pendukung
- tidak memberikan rekomendasi beli/jual
- output JSON valid
```

---

## 4. Struktur Folder Flutter yang Direkomendasikan

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── api_constants.dart
│   │   ├── sheet_constants.dart
│   │   └── route_constants.dart
│   ├── router/
│   │   └── app_router.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_theme.dart
│   │   ├── app_spacing.dart
│   │   └── app_text_styles.dart
│   ├── utils/
│   │   ├── currency_formatter.dart
│   │   ├── date_formatter.dart
│   │   ├── id_generator.dart
│   │   ├── indonesian_number_parser.dart
│   │   └── validators.dart
│   └── errors/
│       ├── app_exception.dart
│       └── failure.dart
├── data/
│   ├── local/
│   │   ├── isar_service.dart
│   │   └── isar_collections.dart
│   ├── models/
│   │   ├── app_setting.dart
│   │   ├── category.dart
│   │   ├── money_transaction.dart
│   │   ├── voice_transcript.dart
│   │   ├── sync_log.dart
│   │   ├── stock_transaction.dart
│   │   ├── dividend.dart
│   │   ├── watchlist_item.dart
│   │   ├── news_article.dart
│   │   ├── news_impact_analysis.dart
│   │   ├── market_snapshot.dart
│   │   └── evidence_item.dart
│   ├── repositories/
│   │   ├── settings_repository.dart
│   │   ├── category_repository.dart
│   │   ├── transaction_repository.dart
│   │   ├── sync_repository.dart
│   │   ├── portfolio_repository.dart
│   │   ├── news_repository.dart
│   │   └── market_repository.dart
│   └── services/
│       ├── biometric_service.dart
│       ├── speech_service.dart
│       ├── transaction_parser_service.dart
│       ├── spreadsheet_sync_service.dart
│       ├── backend_api_service.dart
│       ├── portfolio_calculator_service.dart
│       └── news_analysis_service.dart
├── providers/
│   ├── app_startup_provider.dart
│   ├── auth_lock_provider.dart
│   ├── dashboard_provider.dart
│   ├── transaction_provider.dart
│   ├── voice_provider.dart
│   ├── sync_provider.dart
│   ├── portfolio_provider.dart
│   ├── news_provider.dart
│   └── analysis_provider.dart
├── features/
│   ├── startup/
│   │   ├── splash_screen.dart
│   │   └── biometric_lock_screen.dart
│   ├── onboarding/
│   │   └── onboarding_screen.dart
│   ├── shell/
│   │   └── main_shell_screen.dart
│   ├── beranda/
│   │   └── beranda_screen.dart
│   ├── berita/
│   │   ├── berita_screen.dart
│   │   ├── detail_berita_screen.dart
│   │   └── analisis_berita_screen.dart
│   ├── keuangan/
│   │   ├── keuangan_screen.dart
│   │   ├── tambah_transaksi_screen.dart
│   │   ├── konfirmasi_suara_screen.dart
│   │   └── kategori_screen.dart
│   ├── portofolio/
│   │   ├── portofolio_screen.dart
│   │   ├── tambah_transaksi_saham_screen.dart
│   │   ├── detail_saham_screen.dart
│   │   └── tambah_dividen_screen.dart
│   ├── analisis/
│   │   └── analisis_screen.dart
│   └── settings/
│       └── settings_screen.dart
└── shared/
    ├── widgets/
    │   ├── app_button.dart
    │   ├── app_text_field.dart
    │   ├── app_empty_state.dart
    │   ├── app_error_state.dart
    │   ├── app_loading_state.dart
    │   ├── app_list_tile.dart
    │   ├── app_section_header.dart
    │   ├── sync_status_indicator.dart
    │   └── disclaimer_box.dart
    └── layouts/
        └── app_page.dart
```

---

## 5. Struktur Folder Backend Flask

```text
backend/
├── app.py
├── config.py
├── requirements.txt
├── .env.example
├── database/
│   ├── sqlite.py
│   └── migrations.sql
├── routes/
│   ├── health_routes.py
│   ├── news_routes.py
│   ├── market_routes.py
│   ├── portfolio_routes.py
│   └── cache_routes.py
├── services/
│   ├── google_news_service.py
│   ├── market_data_service.py
│   ├── ai_analysis_service.py
│   ├── cache_service.py
│   └── prompt_builder.py
├── schemas/
│   ├── news_schema.py
│   ├── market_schema.py
│   └── analysis_schema.py
└── tests/
    ├── test_health.py
    ├── test_market.py
    └── test_analysis_schema.py
```

---

## 6. Roadmap Implementasi Modular

## Tahap 0 — Persiapan Project dan Dokumen

### Tujuan

Memastikan Codex memahami seluruh dokumen sebelum menulis kode.

### Input dokumen

```text
docs/prd.md
docs/user_flow.md
docs/erd.md
docs/DESIGN_SYSTEM.md
docs/MODULAR_IMPLEMENTATION.md
```

### Tugas

- Baca seluruh dokumen.
- Jangan langsung coding.
- Buat ringkasan pemahaman project.
- Buat daftar fitur MVP.
- Buat daftar risiko implementasi.
- Tanya jika ada bagian yang ambigu.

### Definition of Done

- Codex dapat menjelaskan scope MoneyPilot dengan benar.
- Tidak ada kode dibuat pada tahap ini.

---

## Tahap 1 — Setup Flutter Project Foundation

### Tujuan

Membangun fondasi Flutter agar aplikasi bisa berjalan dengan navigasi utama dan tema dasar.

### Scope

- setup dependency awal,
- setup folder structure,
- setup theme,
- setup router,
- setup bottom navigation,
- buat placeholder screen untuk 5 tab utama,
- buat splash screen awal.

### Dependencies awal

```yaml
flutter_riverpod: ^2.0.0
go_router: ^14.0.0
isar: ^3.1.0
isar_flutter_libs: ^3.1.0
path_provider: ^2.0.0
uuid: ^4.0.0
intl: ^0.19.0
dio: ^5.0.0
local_auth: ^2.0.0
speech_to_text: ^6.0.0
fl_chart: ^0.68.0
google_fonts: ^6.0.0
lucide_icons: ^0.257.0
shimmer: ^3.0.0
connectivity_plus: ^6.0.0
```

Catatan: versi boleh disesuaikan dengan versi Flutter terbaru yang kompatibel.

### File yang dibuat

```text
lib/main.dart
lib/app.dart
lib/core/router/app_router.dart
lib/core/theme/app_theme.dart
lib/core/theme/app_colors.dart
lib/core/theme/app_text_styles.dart
lib/core/theme/app_spacing.dart
lib/features/shell/main_shell_screen.dart
lib/features/beranda/beranda_screen.dart
lib/features/berita/berita_screen.dart
lib/features/keuangan/keuangan_screen.dart
lib/features/portofolio/portofolio_screen.dart
lib/features/analisis/analisis_screen.dart
lib/shared/layouts/app_page.dart
```

### Acceptance Criteria

- Aplikasi bisa dibuka.
- Bottom navigation berisi:
  - Beranda
  - Berita
  - Keuangan
  - Portofolio
  - Analisis
- Semua tab menampilkan placeholder Bahasa Indonesia.
- Theme sudah memakai gaya putih, hitam, dan biru.
- Tidak ada fitur bisnis yang dibuat dulu.

### Manual Test

1. Jalankan aplikasi.
2. Pastikan splash/halaman awal muncul.
3. Klik setiap tab bottom navigation.
4. Pastikan tidak ada crash.
5. Pastikan teks UI Bahasa Indonesia.

### Prompt Codex Tahap 1

```text
Baca docs/prd.md, docs/user_flow.md, docs/erd.md, docs/DESIGN_SYSTEM.md, dan docs/MODULAR_IMPLEMENTATION.md.

Kerjakan hanya Tahap 1: setup fondasi Flutter MoneyPilot.

Tugas:
1. Setup struktur folder sesuai MODULAR_IMPLEMENTATION.md.
2. Tambahkan dependencies awal yang dibutuhkan.
3. Buat AppTheme minimalis putih-hitam-biru sesuai DESIGN_SYSTEM.md.
4. Buat go_router.
5. Buat MainShellScreen dengan bottom navigation: Beranda, Berita, Keuangan, Portofolio, Analisis.
6. Buat placeholder screen untuk setiap tab.

Batasan:
- Jangan implementasikan database.
- Jangan implementasikan transaksi.
- Jangan implementasikan voice.
- Jangan implementasikan backend.
- Jangan membuat UI terlalu banyak card.
- Semua teks UI harus Bahasa Indonesia.

Output:
- Jelaskan file yang dibuat/diubah.
- Pastikan aplikasi bisa run.
```

---

## Tahap 2 — Biometric Lock dan Onboarding Awal

### Tujuan

Menambahkan keamanan fingerprint/biometric sejak awal MVP dan onboarding sederhana.

### Scope

- cek biometric tersedia,
- autentikasi fingerprint saat membuka aplikasi,
- fallback jika biometric gagal,
- onboarding pertama kali,
- simpan status onboarding di AppSetting.

### File yang dibuat/diubah

```text
lib/data/models/app_setting.dart
lib/data/services/biometric_service.dart
lib/data/repositories/settings_repository.dart
lib/providers/auth_lock_provider.dart
lib/providers/app_startup_provider.dart
lib/features/startup/splash_screen.dart
lib/features/startup/biometric_lock_screen.dart
lib/features/onboarding/onboarding_screen.dart
```

### Acceptance Criteria

- Saat aplikasi pertama dibuka, user melihat onboarding singkat.
- Setelah onboarding selesai, user diminta autentikasi fingerprint jika tersedia.
- Jika fingerprint berhasil, user masuk ke Beranda.
- Jika gagal, tampil pesan Bahasa Indonesia.
- Jika perangkat tidak mendukung biometric, aplikasi tetap bisa masuk dengan peringatan.

### Manual Test

1. Install aplikasi fresh.
2. Buka aplikasi.
3. Pastikan onboarding muncul.
4. Selesaikan onboarding.
5. Pastikan biometric prompt muncul.
6. Coba berhasil dan gagal fingerprint.

### Prompt Codex Tahap 2

```text
Kerjakan hanya Tahap 2: biometric lock dan onboarding awal.

Gunakan package local_auth.

Tugas:
1. Buat BiometricService.
2. Buat onboarding sederhana 3 langkah dalam Bahasa Indonesia.
3. Simpan status onboarding di AppSetting.
4. Tambahkan BiometricLockScreen.
5. Setelah biometric berhasil, arahkan ke Beranda.

Batasan:
- Jangan implementasikan transaksi.
- Jangan implementasikan sync.
- Jangan implementasikan portfolio.
- Jangan implementasikan berita.
- UI harus minimalis dan mengikuti DESIGN_SYSTEM.md.

Output:
- Jelaskan file yang dibuat/diubah.
- Jelaskan cara testing manual.
```

---

## Tahap 3 — Setup Isar dan Model Dasar

### Tujuan

Membuat local database Isar dan model inti untuk fitur MoneyPilot.

### Scope

- setup IsarService,
- buat model Isar,
- generate `.g.dart`,
- setup repository dasar,
- seed kategori default.

### Model Isar MVP

```text
AppSetting
Category
MoneyTransaction
VoiceTranscript
SyncLog
StockTransaction
Dividend
WatchlistItem
NewsArticle
NewsImpactAnalysis
MarketSnapshot
EvidenceItem
```

### Prinsip Data

- Semua entity penting memiliki `uuid`.
- Gunakan soft delete.
- Gunakan `createdAt`, `updatedAt`, `deletedAt`.
- Gunakan `syncStatus` untuk entity yang perlu sync.
- Relasi memakai UUID, bukan foreign key kompleks.

### Kategori Default

```text
Makanan & Minuman
Transportasi
Kos/Asrama
Kuliah
Hiburan
Investasi
Tabungan
Freelance
Uang Orang Tua
Lainnya
```

### Acceptance Criteria

- Isar berhasil dibuka saat aplikasi start.
- Model berhasil di-generate.
- Kategori default dibuat jika belum ada.
- Tidak ada error build.

### Manual Test

1. Jalankan `flutter pub run build_runner build` atau perintah build_runner yang sesuai.
2. Jalankan aplikasi.
3. Pastikan tidak crash saat membuka database.
4. Pastikan kategori default tersedia.

### Prompt Codex Tahap 3

```text
Kerjakan hanya Tahap 3: setup Isar dan model dasar.

Tugas:
1. Buat IsarService.
2. Buat model Isar sesuai docs/erd.md.
3. Tambahkan UUID, soft delete, createdAt, updatedAt, deletedAt, dan syncStatus jika relevan.
4. Buat CategoryRepository dan seed kategori default.
5. Pastikan build_runner berhasil menghasilkan file .g.dart.

Batasan:
- Jangan implementasikan UI transaksi lengkap.
- Jangan implementasikan sync spreadsheet.
- Jangan implementasikan backend.
- Jangan mengubah desain navigasi utama.

Output:
- Jelaskan model yang dibuat.
- Jelaskan command untuk generate Isar.
- Jelaskan hasil testing.
```

---

## Tahap 4 — Keuangan Manual

### Tujuan

Membangun fitur pencatatan keuangan manual.

### Scope

- daftar transaksi,
- tambah transaksi,
- edit transaksi,
- hapus transaksi soft delete,
- filter sederhana,
- ringkasan pemasukan/pengeluaran bulan ini,
- integrasi ke Beranda.

### File utama

```text
lib/features/keuangan/keuangan_screen.dart
lib/features/keuangan/tambah_transaksi_screen.dart
lib/data/repositories/transaction_repository.dart
lib/providers/transaction_provider.dart
lib/providers/dashboard_provider.dart
lib/shared/widgets/app_list_tile.dart
lib/shared/widgets/app_empty_state.dart
```

### Acceptance Criteria

- User bisa tambah transaksi pemasukan.
- User bisa tambah transaksi pengeluaran.
- User bisa memilih kategori.
- User bisa edit transaksi.
- User bisa hapus transaksi dengan soft delete.
- Transaksi tampil di tab Keuangan.
- Ringkasan tampil di Beranda.
- Transaksi baru diberi `syncStatus = pending`.

### Manual Test

1. Tambah pengeluaran Makanan & Minuman Rp25.000.
2. Tambah pemasukan Uang Orang Tua Rp500.000.
3. Edit nominal transaksi.
4. Hapus transaksi.
5. Buka Beranda dan pastikan ringkasan berubah.

### Prompt Codex Tahap 4

```text
Kerjakan hanya Tahap 4: fitur Keuangan manual.

Tugas:
1. Buat daftar transaksi di tab Keuangan.
2. Buat halaman tambah/edit transaksi.
3. Gunakan kategori default dari Isar.
4. Simpan transaksi ke MoneyTransaction.
5. Set syncStatus menjadi pending setiap transaksi dibuat atau diedit.
6. Implementasikan soft delete.
7. Tampilkan ringkasan pemasukan, pengeluaran, dan saldo bulan ini di Beranda.

Batasan:
- Jangan implementasikan voice input.
- Jangan implementasikan spreadsheet sync.
- Jangan implementasikan portfolio.
- Jangan implementasikan backend berita.
- UI minimalis, minim card, Bahasa Indonesia penuh.

Output:
- Jelaskan file yang dibuat/diubah.
- Jelaskan manual testing.
```

---

## Tahap 5 — Voice Input dan Parser Bahasa Indonesia

### Tujuan

Membuat fitur input transaksi melalui suara dengan halaman konfirmasi sebelum disimpan.

### Scope

- speech-to-text,
- parser nominal Bahasa Indonesia,
- deteksi tipe transaksi,
- deteksi kategori,
- confidence score parser,
- simpan raw transcript,
- halaman konfirmasi,
- fallback ke form manual.

### Parser Flow

```text
User bicara
→ speech-to-text
→ normalisasi teks
→ deteksi tipe transaksi
→ deteksi nominal
→ deteksi kategori
→ buat draft transaksi
→ tampilkan halaman konfirmasi
→ user setuju/edit
→ simpan ke Isar
```

### Keyword Awal Pengeluaran

```text
beli
bayar
keluar
mengeluarkan
jajan
makan
naik
topup
top up
isi
sewa
```

### Keyword Awal Pemasukan

```text
dapat
mendapat
terima
menerima
masuk
dibayar
gajian
transfer masuk
uang dari
```

### Contoh Input

```text
Saya beli kopi 15 ribu.
Saya beli nasi goreng dua puluh lima ribu.
Saya bayar kos satu juta.
Saya dapat uang dari orang tua lima ratus ribu.
Saya mendapat uang freelance 300 ribu.
```

### Acceptance Criteria

- User bisa menekan tombol mic.
- Speech-to-text menghasilkan transcript.
- Parser bisa membaca nominal umum seperti `25 ribu`, `dua puluh lima ribu`, `1 juta`, `1,5 juta`, `25k`, `25 rb`.
- Hasil tidak langsung disimpan.
- Halaman konfirmasi wajib muncul.
- User bisa edit hasil parsing sebelum simpan.
- Raw transcript tersimpan di `VoiceTranscript`.
- Jika nominal gagal, user diarahkan ke form manual dengan catatan berisi transcript.

### Unit Test Wajib

```text
parse 25 ribu = 25000
parse dua puluh lima ribu = 25000
parse 1 juta = 1000000
parse setengah juta = 500000
parse 25k = 25000
parse 25 rb = 25000
```

### Prompt Codex Tahap 5

```text
Kerjakan hanya Tahap 5: voice input dan parser Bahasa Indonesia.

Tugas:
1. Integrasikan speech_to_text.
2. Buat SpeechService.
3. Buat IndonesianNumberParser.
4. Buat TransactionParserService.
5. Buat KonfirmasiSuaraScreen.
6. Simpan raw transcript ke VoiceTranscript.
7. Jika parsing gagal, buka form manual dengan transcript di catatan.
8. Tambahkan unit test untuk parser angka.

Batasan:
- Jangan implementasikan spreadsheet sync.
- Jangan implementasikan portfolio.
- Jangan implementasikan berita.
- Jangan memakai AI untuk parsing voice pada MVP.
- Semua hasil voice wajib dikonfirmasi sebelum disimpan.

Output:
- Jelaskan parsing rule yang dibuat.
- Jelaskan file yang dibuat/diubah.
- Jelaskan test yang ditambahkan.
```

---

## Tahap 6 — Google Spreadsheet Sync Dua Arah

### Tujuan

Membangun sinkronisasi dua arah antara Isar dan Google Spreadsheet menggunakan Google Apps Script.

### Scope

- Google Apps Script endpoint,
- secret token,
- pull data dari spreadsheet,
- push data ke spreadsheet,
- upsert by UUID,
- conflict resolution `latest updatedAt wins`,
- sync queue,
- retry sync,
- sync status indicator.

### Sync Strategy Final

```text
Sumber utama: Isar local database
Cloud backup/edit ringan: Google Spreadsheet
Identitas data: UUID
Mode sync: dua arah
Conflict resolution: latest updatedAt wins
Delete strategy: soft delete
Spreadsheet operation: upsert by UUID
```

### Sheet MVP

```text
Transactions
Categories
Sync_Log
Stock_Transactions
Dividends
Watchlist
```

`Portfolio_Holdings` boleh dibuat sebagai hasil ekspor/snapshot, bukan sumber utama kalkulasi.

### Google Apps Script Rule

Script tidak boleh hanya `appendRow`. Script wajib:

1. membaca header,
2. mencari kolom `uuid`,
3. mencari row berdasarkan `uuid`,
4. jika ada, update row,
5. jika tidak ada, insert row,
6. mengembalikan response JSON.

### Response Minimal

```json
{
  "status": "success",
  "inserted": 2,
  "updated": 1,
  "failed": 0,
  "serverTime": "2026-07-09T10:00:00Z"
}
```

### Acceptance Criteria

- Transaksi baru bisa dikirim ke spreadsheet.
- Data dari spreadsheet bisa ditarik ke Isar.
- Edit transaksi dari aplikasi meng-update row spreadsheet berdasarkan UUID.
- Jika data spreadsheet lebih baru, data lokal diperbarui.
- Jika offline, data masuk sync queue.
- Jika sync gagal, status menjadi failed dan error message tersimpan.
- Ada indikator sync di Beranda atau Settings.

### Manual Test

1. Tambah transaksi di aplikasi.
2. Jalankan sync.
3. Pastikan row muncul di spreadsheet.
4. Edit transaksi di aplikasi.
5. Jalankan sync.
6. Pastikan row yang sama berubah, bukan membuat row baru.
7. Edit row di spreadsheet dan ubah `updatedAt` lebih baru.
8. Jalankan sync pull.
9. Pastikan data lokal berubah.
10. Matikan internet dan tambah transaksi.
11. Pastikan status pending.

### Prompt Codex Tahap 6

```text
Kerjakan hanya Tahap 6: Google Spreadsheet sync dua arah.

Tugas:
1. Buat SpreadsheetSyncService.
2. Buat SyncRepository.
3. Buat sync queue berdasarkan syncStatus.
4. Implementasikan push lokal ke Google Apps Script.
5. Implementasikan pull dari Google Apps Script ke Isar.
6. Gunakan UUID untuk upsert.
7. Gunakan latest updatedAt wins untuk conflict resolution.
8. Tambahkan SyncLog.
9. Tambahkan indikator status sync di Beranda atau Settings.
10. Berikan contoh kode Google Apps Script dalam dokumentasi atau file terpisah.

Batasan:
- Jangan implementasikan portfolio jika belum ada.
- Jangan implementasikan berita.
- Jangan mengubah model Isar tanpa menjelaskan migrasi.
- Jangan append row tanpa cek UUID.

Output:
- Jelaskan strategi sync.
- Jelaskan file yang dibuat/diubah.
- Jelaskan cara setup Google Apps Script.
- Jelaskan manual testing.
```

---

## Tahap 7 — Portofolio Saham, Dividen, dan Harga Pasar Backend

### Tujuan

Membangun portofolio saham manual dengan harga pasar dari backend.

### Scope

- tambah transaksi beli saham,
- tambah transaksi jual saham,
- catat fee,
- catat dividen,
- hitung average price,
- hitung realized P/L,
- hitung unrealized P/L,
- ambil harga pasar lewat backend,
- fallback input manual jika backend gagal,
- tampilkan portofolio minimalis.

### Metode Akuntansi

```text
Metode: Weighted Average / Moving Average
Dividen: menambah total return, tidak mengubah average price
Fee beli: menambah cost basis
Fee jual: mengurangi hasil jual
Jika posisi menjadi nol: average price reset
Stock split: post-MVP/manual adjustment
```

### Endpoint Backend yang Dibutuhkan

```text
GET /market/stock/:symbol
POST /portfolio/price-update
```

### Acceptance Criteria

- User bisa input beli saham.
- User bisa input jual saham.
- User bisa input dividen.
- Sistem menghitung jumlah lot/lembar.
- Sistem menghitung average price.
- Sistem menghitung realized dan unrealized P/L.
- Sistem mencoba mengambil harga pasar dari backend.
- Jika backend gagal, user bisa input harga manual.
- Portofolio tampil dalam Bahasa Indonesia dan UI minimalis.

### Unit Test Wajib

```text
Beli BBCA 1 lot di 9000
Beli BBCA 2 lot di 8800
Jual BBCA 1 lot di 9300
Terima dividen
Harga sekarang 9500
```

Test harus memverifikasi:

- total lembar tersisa,
- average price,
- realized P/L,
- unrealized P/L,
- total return termasuk dividen.

### Prompt Codex Tahap 7

```text
Kerjakan hanya Tahap 7: Portofolio saham, dividen, dan harga pasar backend.

Tugas:
1. Buat StockTransaction form untuk beli dan jual.
2. Buat Dividend form.
3. Buat PortfolioCalculatorService dengan metode moving average.
4. Buat PortfolioRepository.
5. Tampilkan PortofolioScreen minimalis.
6. Integrasikan endpoint backend GET /market/stock/:symbol.
7. Jika backend gagal, sediakan input harga manual.
8. Tambahkan unit test untuk perhitungan portfolio.

Batasan:
- Jangan implementasikan news AI analysis.
- Jangan implementasikan corporate action otomatis.
- Jangan rekomendasikan beli/jual saham.
- Jangan membuat UI trading yang ramai.

Output:
- Jelaskan formula yang digunakan.
- Jelaskan file yang dibuat/diubah.
- Jelaskan manual dan unit testing.
```

---

## Tahap 8 — Backend Flask Skeleton dan Market Data

### Tujuan

Membangun backend Flask minimal yang siap dipakai Flutter.

### Scope

- setup Flask project,
- `.env`,
- health endpoint,
- market endpoint,
- SQLite cache,
- error response standar,
- CORS bila diperlukan.

### Endpoint

```text
GET /health
GET /market/stock/:symbol
GET /market/index/:symbol
GET /market/forex/:pair
GET /market/commodity/:symbol
GET /cache/status
```

### Data Provider MVP

```text
Saham Indonesia/IHSG: EODHD utama, yfinance hanya fallback/prototyping
Forex/komoditas: Twelve Data atau provider yang tersedia
Makro global: FRED
```

### Error Response Standar

```json
{
  "status": "error",
  "message": "Data pasar belum tersedia.",
  "code": "MARKET_DATA_UNAVAILABLE"
}
```

### Acceptance Criteria

- `GET /health` mengembalikan status OK.
- Endpoint market mengembalikan JSON konsisten.
- API key tidak ada di Flutter.
- Cache SQLite menyimpan hasil request.
- Jika provider gagal, response error tetap rapi.

### Prompt Codex Tahap 8

```text
Kerjakan hanya Tahap 8: backend Flask skeleton dan market data.

Tugas:
1. Buat folder backend.
2. Setup Flask app.
3. Buat /health.
4. Buat service market data.
5. Buat endpoint /market/stock/:symbol.
6. Buat SQLite cache sederhana.
7. Gunakan .env untuk API key.
8. Buat error response standar.

Batasan:
- Jangan implementasikan AI analysis dulu.
- Jangan menaruh API key di Flutter.
- yfinance hanya boleh ditulis sebagai fallback/prototyping.

Output:
- Jelaskan cara menjalankan backend.
- Jelaskan environment variables.
- Jelaskan endpoint yang tersedia.
```

---

## Tahap 9 — Berita dan AI News Impact Analysis

### Tujuan

Membangun fitur berita ekonomi dan analisis dampak berbasis AI backend.

### Scope

- Google News RSS backend,
- daftar berita di Flutter,
- detail berita,
- bookmark berita,
- AI analysis endpoint,
- impact score,
- confidence score,
- evidence,
- disclaimer,
- cache hasil analisis.

### Endpoint

```text
GET /news
GET /news/:id
POST /news/analyze
```

### Output Analisis Minimal

```json
{
  "status": "success",
  "data": {
    "newsId": "uuid",
    "judul": "...",
    "ringkasan": "...",
    "kategori": "Geopolitik",
    "asetTerdampak": ["Emas", "USD/IDR", "IHSG"],
    "impactScore": 82,
    "confidenceScore": 76,
    "dampakPotensial": "...",
    "rantaiSebabAkibat": ["..."],
    "dataPendukung": ["..."],
    "skenarioPositif": "...",
    "skenarioNegatif": "...",
    "halYangPerluDipantau": ["..."],
    "kesimpulanPemula": "...",
    "disclaimer": "Informasi ini bukan nasihat keuangan."
  }
}
```

### Aturan AI

AI wajib:

- menggunakan Bahasa Indonesia,
- tidak memberi rekomendasi beli/jual,
- menggunakan diksi probabilitas,
- mengakui jika data tidak cukup,
- menurunkan confidence score jika data bertentangan,
- mengembalikan JSON valid.

AI dilarang:

- mengatakan “saham ini pasti naik”,
- mengatakan “beli sekarang”,
- membuat data pasar palsu,
- memberi rekomendasi trading langsung.

### Acceptance Criteria

- User bisa melihat daftar berita.
- User bisa membuka detail berita.
- User bisa bookmark berita.
- User bisa menekan “Analisis Dampak”.
- Backend mengembalikan hasil analisis AI dalam JSON.
- Flutter merender analisis dengan UI minimalis dan mudah dipahami.
- Disclaimer muncul di setiap hasil analisis.
- Jika backend gagal, tampil error state Bahasa Indonesia.

### Prompt Codex Tahap 9

```text
Kerjakan hanya Tahap 9: Berita dan AI News Impact Analysis.

Tugas backend:
1. Buat Google News RSS service.
2. Buat endpoint GET /news.
3. Buat endpoint POST /news/analyze.
4. Buat prompt AI yang mengikuti aturan PRD.
5. Simpan hasil analisis ke SQLite cache.
6. Pastikan output JSON valid.

Tugas Flutter:
1. Buat BeritaScreen.
2. Buat DetailBeritaScreen.
3. Tambahkan bookmark berita.
4. Tambahkan tombol Analisis Dampak.
5. Render impact score, confidence score, evidence, dan disclaimer.

Batasan:
- Jangan memberi rekomendasi beli/jual.
- Jangan membuat UI terlalu ramai.
- Jangan menyimpan API key di Flutter.
- Semua teks Bahasa Indonesia.

Output:
- Jelaskan endpoint.
- Jelaskan prompt AI.
- Jelaskan file yang dibuat/diubah.
- Jelaskan manual testing.
```

---

## Tahap 10 — Tab Analisis dan Watchlist

### Tujuan

Membangun tab Analisis sebagai fondasi fitur analisis saham/forex di masa depan tanpa membuat fitur kompleks dulu.

### Scope

- placeholder analisis,
- watchlist saham,
- catatan analisis manual,
- link ke berita terkait jika ada,
- UI edukatif bahwa fitur analisis lanjutan masih dikembangkan.

### Acceptance Criteria

- Tab Analisis tidak kosong.
- User bisa melihat watchlist.
- User bisa menambah/menghapus item watchlist.
- User bisa menulis catatan analisis manual sederhana.
- Tidak ada rekomendasi beli/jual.

### Prompt Codex Tahap 10

```text
Kerjakan hanya Tahap 10: Tab Analisis dan Watchlist.

Tugas:
1. Buat tampilan Analisis yang minimalis.
2. Tambahkan watchlist saham.
3. Tambahkan catatan analisis manual.
4. Simpan data ke WatchlistItem.
5. Jelaskan bahwa fitur analisis lanjutan sedang disiapkan.

Batasan:
- Jangan membuat analisis saham otomatis penuh.
- Jangan membuat rekomendasi trading.
- Jangan menambah fitur forex kompleks.

Output:
- Jelaskan file yang dibuat/diubah.
- Jelaskan manual testing.
```

---

## Tahap 11 — Settings, Export, dan Privacy

### Tujuan

Menyediakan pengaturan aplikasi, keamanan, sync, export, dan reset data.

### Scope

- halaman pengaturan,
- status biometric,
- URL Google Apps Script,
- secret token,
- status backend,
- export CSV,
- reset data lokal,
- privacy/disclaimer.

### Acceptance Criteria

- User bisa membuka Settings.
- User bisa mengubah konfigurasi spreadsheet sync.
- User bisa melihat status biometric.
- User bisa export data ke CSV.
- User bisa reset data dengan konfirmasi ganda.
- Disclaimer investasi tersedia.

### Prompt Codex Tahap 11

```text
Kerjakan hanya Tahap 11: Settings, Export, dan Privacy.

Tugas:
1. Buat SettingsScreen.
2. Tambahkan pengaturan Google Apps Script URL dan secret token.
3. Tambahkan status biometric.
4. Tambahkan export CSV.
5. Tambahkan reset data dengan konfirmasi ganda.
6. Tambahkan halaman/section disclaimer.

Batasan:
- Jangan mengubah flow utama.
- Jangan menambahkan login server.
- Jangan menghapus data tanpa konfirmasi ganda.

Output:
- Jelaskan file yang dibuat/diubah.
- Jelaskan manual testing.
```

---

## Tahap 12 — Testing, Stabilization, dan Polish MVP

### Tujuan

Menstabilkan aplikasi sebelum dianggap MVP selesai.

### Scope

- unit test,
- widget test sederhana,
- integration/manual test,
- bug fixing,
- loading/error/empty state,
- performance check,
- final UI polish.

### Area Test Wajib

```text
IndonesianNumberParser
TransactionParserService
TransactionRepository
SpreadsheetSyncService
PortfolioCalculatorService
Backend API Service
NewsAnalysisService
Biometric flow
```

### Acceptance Criteria

- Semua fitur MVP bisa diuji manual.
- Tidak ada crash pada flow utama.
- UI konsisten dengan Design System.
- Semua teks Bahasa Indonesia.
- Tidak ada API key di Flutter.
- Semua analisis berita menampilkan disclaimer.

### Prompt Codex Tahap 12

```text
Kerjakan hanya Tahap 12: testing, stabilization, dan polish MVP.

Tugas:
1. Tambahkan unit test untuk parser angka.
2. Tambahkan unit test untuk parser transaksi.
3. Tambahkan unit test untuk portfolio calculator.
4. Tambahkan test sederhana untuk sync conflict resolution.
5. Rapikan loading, empty, dan error state.
6. Pastikan semua teks UI Bahasa Indonesia.
7. Pastikan tidak ada API key di Flutter.

Batasan:
- Jangan menambah fitur baru.
- Fokus hanya stabilisasi dan polish.

Output:
- Jelaskan test yang ditambahkan.
- Jelaskan bug yang diperbaiki.
- Jelaskan checklist MVP final.
```

---

# 7. Milestone MVP

## Milestone 1 — App Skeleton Siap

Mencakup:

- Flutter foundation,
- theme,
- routing,
- bottom navigation,
- placeholder screen.

Tahap terkait: 1

---

## Milestone 2 — Local-First Core Siap

Mencakup:

- biometric lock,
- onboarding,
- Isar,
- model dasar,
- kategori default.

Tahap terkait: 2–3

---

## Milestone 3 — Keuangan Harian Siap

Mencakup:

- transaksi manual,
- dashboard ringkasan,
- voice input,
- parser Bahasa Indonesia,
- konfirmasi voice.

Tahap terkait: 4–5

---

## Milestone 4 — Sync Spreadsheet Siap

Mencakup:

- Google Apps Script,
- sync dua arah,
- upsert UUID,
- conflict resolution,
- sync queue.

Tahap terkait: 6

---

## Milestone 5 — Portofolio Siap

Mencakup:

- transaksi beli/jual saham,
- dividen,
- kalkulasi P/L,
- harga pasar backend.

Tahap terkait: 7–8

---

## Milestone 6 — Berita dan AI Siap

Mencakup:

- news feed,
- detail berita,
- bookmark,
- AI impact analysis,
- confidence score,
- disclaimer.

Tahap terkait: 9

---

## Milestone 7 — MVP Final Siap

Mencakup:

- tab Analisis,
- settings,
- export,
- privacy,
- testing,
- polish.

Tahap terkait: 10–12

---

# 8. Testing Plan

## 8.1 Unit Test

| Test | Tujuan | Prioritas |
|---|---|---|
| IndonesianNumberParser | Memastikan angka Bahasa Indonesia diparse benar | Tinggi |
| TransactionParserService | Memastikan kalimat suara jadi draft transaksi | Tinggi |
| CurrencyFormatter | Memastikan format Rupiah benar | Sedang |
| PortfolioCalculatorService | Memastikan average price dan P/L benar | Tinggi |
| Sync conflict resolution | Memastikan latest updatedAt wins | Tinggi |
| News analysis JSON parser | Memastikan JSON backend bisa dibaca Flutter | Tinggi |

---

## 8.2 Manual Test

| Area | Langkah | Expected Result |
|---|---|---|
| Biometric | Buka aplikasi dan autentikasi fingerprint | Masuk Beranda |
| Transaksi manual | Tambah pengeluaran Rp25.000 | Muncul di Keuangan dan Beranda berubah |
| Voice input | Ucapkan “Saya beli kopi 15 ribu” | Halaman konfirmasi muncul dengan nominal 15000 |
| Sync push | Tambah transaksi lalu sync | Data muncul di spreadsheet |
| Sync pull | Edit spreadsheet lalu sync | Data lokal ikut berubah jika updatedAt lebih baru |
| Portfolio | Tambah beli/jual saham | Holding dan P/L berubah |
| Dividen | Tambah dividen | Total return bertambah |
| News | Buka tab Berita | Daftar berita tampil |
| AI Analysis | Tekan Analisis Dampak | Hasil analisis + disclaimer tampil |
| Offline | Matikan internet lalu tambah transaksi | Transaksi tersimpan pending |

---

## 8.3 Backend Test

| Endpoint | Expected Result |
|---|---|
| `GET /health` | status OK |
| `GET /market/stock/BBCA.JK` | harga saham atau error rapi |
| `GET /news` | daftar berita |
| `POST /news/analyze` | JSON analisis valid |
| `GET /cache/status` | status cache |

---

# 9. Manual Testing Checklist Final MVP

```text
[ ] Aplikasi dapat dibuka tanpa crash.
[ ] Onboarding muncul saat install pertama.
[ ] Fingerprint berjalan jika perangkat mendukung.
[ ] Bottom navigation berurutan: Beranda, Berita, Keuangan, Portofolio, Analisis.
[ ] Semua teks utama memakai Bahasa Indonesia.
[ ] User dapat tambah transaksi manual.
[ ] User dapat edit transaksi manual.
[ ] User dapat hapus transaksi dengan soft delete.
[ ] User dapat tambah transaksi via suara.
[ ] Voice input selalu masuk halaman konfirmasi.
[ ] Parser bisa membaca nominal umum.
[ ] Sync ke spreadsheet berhasil.
[ ] Pull dari spreadsheet berhasil.
[ ] Edit transaksi yang sudah sync meng-update row berdasarkan UUID.
[ ] Conflict resolution latest updatedAt wins berjalan.
[ ] User dapat tambah transaksi beli saham.
[ ] User dapat tambah transaksi jual saham.
[ ] User dapat catat dividen.
[ ] Harga saham mencoba diambil dari backend.
[ ] Jika backend gagal, user bisa input harga manual.
[ ] News feed tampil.
[ ] Detail berita tampil.
[ ] Bookmark berita berjalan.
[ ] Analisis AI berjalan.
[ ] Confidence score tampil.
[ ] Disclaimer tampil pada analisis berita.
[ ] Tab Analisis tidak kosong.
[ ] Settings tersedia.
[ ] Export data tersedia.
[ ] Reset data memakai konfirmasi ganda.
[ ] Tidak ada API key di Flutter.
```

---

# 10. Risiko Implementasi dan Mitigasi

## 10.1 Risiko Scope Terlalu Besar

### Risiko

MoneyPilot menggabungkan finance, voice, sync, portfolio, backend, market data, dan AI. Jika Codex diminta membuat semua sekaligus, kemungkinan besar kode menjadi rusak atau tidak rapi.

### Mitigasi

- Ikuti roadmap modular.
- Satu prompt hanya untuk satu tahap.
- Jangan lanjut tahap berikutnya sebelum tahap sebelumnya bisa run.

---

## 10.2 Risiko Sync Dua Arah Rumit

### Risiko

Sync dua arah bisa menyebabkan data dobel atau konflik antara Isar dan spreadsheet.

### Mitigasi

- Semua entity memakai UUID.
- Spreadsheet wajib upsert by UUID.
- Conflict resolution memakai latest updatedAt wins.
- Soft delete dipakai untuk sinkronisasi penghapusan.

---

## 10.3 Risiko Isar Build Error

### Risiko

Model Isar membutuhkan generated file. Kesalahan anotasi atau tipe data bisa membuat build gagal.

### Mitigasi

- Buat model sedikit demi sedikit.
- Jalankan build_runner setelah model dibuat.
- Jangan mengubah semua model sekaligus tanpa testing.

---

## 10.4 Risiko Parser Suara Tidak Akurat

### Risiko

Speech-to-text dan parser Bahasa Indonesia bisa salah membaca nominal atau kategori.

### Mitigasi

- Semua hasil voice wajib masuk halaman konfirmasi.
- Simpan raw transcript.
- Jika confidence rendah, buka form manual.
- Tambahkan unit test parser angka.

---

## 10.5 Risiko Data Pasar API Gagal

### Risiko

API market data bisa limit, down, atau tidak mendukung saham Indonesia dengan baik.

### Mitigasi

- Semua API lewat backend.
- Gunakan cache SQLite.
- Sediakan fallback input harga manual.
- Jangan hardcode API key di Flutter.

---

## 10.6 Risiko AI Halusinasi

### Risiko

AI bisa membuat kesimpulan terlalu percaya diri atau memberikan rekomendasi investasi.

### Mitigasi

- Prompt melarang rekomendasi beli/jual.
- Output harus JSON.
- Confidence score wajib ada.
- Jika data kurang, AI wajib menyatakan data belum cukup.
- Disclaimer wajib tampil.

---

## 10.7 Risiko UI Terlalu Ramai

### Risiko

Karena banyak fitur, UI bisa terlihat seperti dashboard trading yang padat.

### Mitigasi

- Ikuti Design System.
- Minimalis putih-hitam-biru.
- Minim card.
- Gunakan list, whitespace, dan separator tipis.
- Chart hanya untuk informasi penting.

---

# 11. Aturan Umum Prompt untuk Codex

Setiap prompt ke Codex sebaiknya memakai format berikut:

```text
Konteks:
Saya sedang membangun aplikasi MoneyPilot. Baca dan ikuti docs/prd.md, docs/user_flow.md, docs/erd.md, docs/DESIGN_SYSTEM.md, dan docs/MODULAR_IMPLEMENTATION.md.

Tahap yang dikerjakan:
[sebutkan tahap]

Tugas:
1. ...
2. ...
3. ...

Batasan:
- Jangan mengerjakan di luar tahap ini.
- Jangan menghapus fitur yang sudah ada.
- Jangan mengubah arsitektur utama tanpa alasan.
- Semua teks UI harus Bahasa Indonesia.
- UI harus mengikuti DESIGN_SYSTEM.md.

Output yang saya inginkan:
- Daftar file yang dibuat.
- Daftar file yang diubah.
- Penjelasan singkat perubahan.
- Cara menjalankan.
- Cara testing manual.
- Risiko atau catatan penting jika ada.
```

---

# 12. Definition of Done Global

Sebuah tahap dianggap selesai jika:

```text
[ ] Aplikasi bisa build/run.
[ ] Tidak ada error fatal dari flutter analyze.
[ ] Fitur sesuai scope tahap.
[ ] Tidak ada fitur di luar scope yang dibuat.
[ ] UI mengikuti Design System.
[ ] Semua teks UI Bahasa Indonesia.
[ ] Data model mengikuti ERD.
[ ] Fitur lama tidak rusak.
[ ] Manual testing tahap tersebut sudah dilakukan.
[ ] Codex menjelaskan file yang dibuat/diubah.
```

---

# 13. Catatan Final untuk Codex

MoneyPilot bukan aplikasi trading dan bukan aplikasi rekomendasi investasi. MoneyPilot adalah aplikasi personal finance intelligence yang membantu pengguna memahami uang pribadi, portofolio, dan berita ekonomi dengan gaya mentor pemula.

Codex harus selalu menjaga prinsip berikut:

```text
Keamanan data lebih penting daripada fitur cepat.
Kejelasan UI lebih penting daripada tampilan ramai.
Konfirmasi user lebih penting daripada otomatisasi.
Analisis edukatif lebih penting daripada rekomendasi beli/jual.
Stabilitas MVP lebih penting daripada fitur tambahan.
```
