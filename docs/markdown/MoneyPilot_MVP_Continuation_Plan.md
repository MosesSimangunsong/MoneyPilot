# MoneyPilot MVP Continuation Plan

## Tujuan Dokumen

Dokumen ini menjadi pegangan lanjutan untuk menyelesaikan MoneyPilot agar sistem benar-benar sesuai dengan detail yang sudah ditulis di CV, bukan sebaliknya. Fokus utama bukan menambah fitur sembarangan, tetapi menutup gap yang ditemukan dari audit Codex terhadap klaim CV.

Status saat ini: **MVP Candidate-Ready**.
Target akhir: **MVP Final-Ready dan Demo-Ready**.

---

## CV Claim Target

Detail CV yang harus dipenuhi oleh sistem:

> MoneyPilot Personal Finance Intelligence Application — Jul 2026 – Present
>
> Developed and actively use a Flutter-based personal finance intelligence application to record daily income and expenses, manage stock portfolios, track dividends, monitor watchlists, read financial news, and analyze market-related information in one integrated mobile app.
>
> Built offline-first local data storage with Isar, supporting manual transaction input, Indonesian voice-based transaction recording, biometric protection, category management, soft delete, and monthly financial summaries.
>
> Integrated Google Spreadsheet two-way synchronization through Google Apps Script, enabling secure backup, UUID-based upsert, conflict handling, and personal finance data access across local mobile storage and spreadsheet records.
>
> Developed a Flask backend to provide market price data, Google News RSS feeds, caching, and AI-powered news impact analysis with educational insights, confidence scoring, affected assets, scenario analysis, and investment disclaimers without generating direct buy/sell recommendations.
>
> Designed the system for daily personal use, allowing consistent tracking of spending, portfolio movement, watchlist updates, and economic news impact in Bahasa Indonesia.

---

## Prinsip Lanjutan

1. Sistem harus disesuaikan agar klaim CV benar.
2. Jangan menurunkan klaim CV kecuali setelah semua opsi implementasi realistis sudah dicoba.
3. Jangan menambah fitur besar di luar klaim CV.
4. Jangan merusak fitur yang sudah stabil.
5. Semua fitur utama harus bisa didemokan di UI atau dijelaskan dengan bukti file/test yang jelas.
6. Semua UI utama harus menggunakan Bahasa Indonesia.
7. Aplikasi harus tetap local-first.
8. Backend tidak boleh menyimpan data transaksi pribadi user.
9. Analisis investasi tidak boleh memberi rekomendasi beli/jual langsung.
10. Setelah setiap tahap, wajib menjalankan `flutter analyze`, `flutter test`, dan `pytest` jika backend berubah.

---

## Gap Utama dari Audit

Berdasarkan audit Codex, gap terbesar yang harus ditutup adalah:

1. **Category management belum matang**
   - Model dan repository ada.
   - Default category ada.
   - Tetapi UI category management belum benar-benar bisa digunakan.
   - `kategori_screen.dart` masih kosong atau belum diroute dengan benar.

2. **Spreadsheet sync belum mencakup seluruh domain yang diklaim**
   - Sync dua arah sudah kuat untuk categories dan money transactions.
   - Tetapi CV mengesankan data personal finance bisa diakses lintas local mobile storage dan spreadsheet records secara lebih luas.
   - Perlu menambahkan sync untuk stock transactions, dividends, dan watchlist agar klaim lebih kuat.

3. **Secure backup masih lemah secara istilah**
   - Token-based sync sudah ada.
   - Namun belum ada penguatan keamanan lokal seperti penyembunyian token di UI atau penyimpanan yang lebih aman.
   - Minimal perlu perapian UX/security handling agar klaim secure backup lebih layak.

4. **Market price data masih mock**
   - Backend market endpoint ada.
   - Tetapi provider masih mock.
   - Untuk memenuhi CV, sistem harus menyediakan market price data yang lebih nyata atau setidaknya jelas sebagai delayed/mock development source.
   - Karena CV menyebut “market price data”, lebih baik implementasikan provider nyata sederhana jika memungkinkan.

5. **AI-powered news impact analysis bergantung environment**
   - Kode AI analysis ada.
   - Jika `OPENAI_API_KEY` tidak tersedia, fallback mock dipakai.
   - Untuk demo, perlu mode yang jelas: AI aktif jika key ada, fallback aman jika key tidak ada.
   - UI perlu menunjukkan status analisis secara rapi tanpa menipu user.

6. **Onboarding copy tidak sinkron**
   - Ada copy lama yang menyebut voice input akan dibangun nanti.
   - Ini harus diperbaiki karena voice input sudah ada.

7. **Bahasa Indonesia belum konsisten 100%**
   - Mayoritas UI sudah Indonesia.
   - Masih ada copy Inggris di beberapa endpoint/status/message.
   - Perlu audit teks UI.

8. **Portfolio movement tracking belum kuat**
   - Saat ini ada posisi aktif, modal, harga pasar, dan recent transactions.
   - Tetapi belum ada tampilan “movement” yang jelas.
   - Minimal perlu ringkasan perubahan estimasi nilai portofolio berbasis harga pasar saat ini vs average/modal, atau riwayat transaksi sebagai movement dasar.

9. **Daily personal use readiness butuh penguatan**
   - Sistem sudah lengkap secara fitur.
   - Tetapi perlu data demo, checklist penggunaan harian, export, reset, backend fallback, dan dokumentasi run.

---

## Roadmap Implementasi Lanjutan

### Tahap 13 — CV Claim Gap Closure Foundation

**Tujuan:** Menutup gap paling kelihatan sebelum masuk perbaikan sync/backend yang lebih sensitif.

#### Scope

1. Implementasikan UI Category Management yang benar-benar bisa digunakan.
2. Perbaiki onboarding copy agar sesuai fitur aktual.
3. Audit dan rapikan copy Bahasa Indonesia di UI utama.
4. Tambahkan dokumentasi gap closure di `docs/manual/progress`.
5. Siapkan checklist manual test khusus CV claim.

#### Category Management Requirements

UI harus mendukung:

- Melihat daftar kategori aktif.
- Filter berdasarkan tipe: pemasukan/pengeluaran atau semua.
- Tambah kategori baru.
- Edit nama, ikon, dan tipe kategori.
- Soft delete kategori.
- Validasi nama kategori tidak kosong.
- Mencegah duplikasi nama kategori aktif pada tipe yang sama jika repository mendukung.
- Kategori yang sudah dipakai transaksi tidak boleh menghapus transaksi; cukup soft delete kategori.
- Kategori default tetap aman.

File yang perlu dicek:

- `lib/features/keuangan/kategori_screen.dart`
- `lib/data/repositories/category_repository.dart`
- `lib/data/models/category.dart`
- `lib/core/router/app_router.dart`
- `lib/core/constants/route_constants.dart`
- `lib/features/keuangan/keuangan_screen.dart`
- `lib/features/settings/settings_screen.dart`

#### Onboarding Copy Requirements

Perbaiki teks onboarding yang sudah ketinggalan, terutama jika masih menyebut voice input belum tersedia.

Teks harus mencerminkan fitur aktual:

- Catat pemasukan/pengeluaran manual.
- Catat transaksi dengan suara Bahasa Indonesia.
- Simpan data lokal offline-first.
- Backup/sync ke Google Spreadsheet.
- Pantau portofolio, dividen, watchlist, berita, dan analisis edukatif.

#### Bahasa Indonesia Audit

Rapikan teks campuran Inggris/Indonesia di:

- Settings
- Backend status
- News
- Analysis
- Portfolio
- Onboarding
- Empty state
- Error state

Backend response boleh tetap teknis, tetapi pesan yang tampil ke user di Flutter harus Bahasa Indonesia.

#### Deliverables

- Category management UI aktif.
- Route kategori aktif.
- Onboarding copy updated.
- UI text audit done.
- Test kategori ditambah/diperbarui.
- Manual checklist CV claim dibuat.

#### Definition of Done

- User bisa demo category management dari UI.
- Tidak ada onboarding copy yang salah.
- `flutter analyze` lulus.
- `flutter test` lulus.

---

### Tahap 14 — Full Spreadsheet Sync Expansion

**Tujuan:** Membuat klaim Google Spreadsheet two-way synchronization lebih kuat karena mencakup data personal finance dan portofolio utama.

#### Scope

Perluas sync dua arah untuk:

1. Money Transactions — sudah ada, audit ulang saja.
2. Categories — sudah ada, audit ulang saja.
3. Stock Transactions.
4. Dividends.
5. Watchlist.

#### Requirements

Untuk setiap entity sync:

- Menggunakan UUID sebagai identity utama.
- Mendukung push local to spreadsheet.
- Mendukung pull spreadsheet to local.
- Mendukung upsert by UUID.
- Mendukung latest `updatedAt` wins.
- Mendukung soft delete sync.
- Mendukung `syncStatus` atau mekanisme status yang sudah ada.
- Tidak membuat duplicate row.
- Tidak menghapus permanen data lokal kecuali memang reset lokal.

#### Google Spreadsheet Sheets

Minimal sheets yang harus ada:

- `Categories`
- `Transactions`
- `Stock_Transactions`
- `Dividends`
- `Watchlist`

#### Headers yang perlu distandarkan

Pastikan Google Apps Script dan Flutter mapper menggunakan header konsisten.

##### Stock_Transactions

- `uuid`
- `symbol`
- `companyName`
- `actionType`
- `lot`
- `shares`
- `price`
- `fee`
- `transactionDate`
- `note`
- `syncStatus`
- `syncErrorMessage`
- `isDeleted`
- `createdAt`
- `updatedAt`
- `deletedAt`

##### Dividends

- `uuid`
- `symbol`
- `companyName`
- `grossAmount`
- `tax`
- `netAmount`
- `receivedDate`
- `linkedTransactionUuid`
- `note`
- `syncStatus`
- `syncErrorMessage`
- `isDeleted`
- `createdAt`
- `updatedAt`
- `deletedAt`

##### Watchlist

- `uuid`
- `symbol`
- `companyName`
- `market`
- `targetPrice`
- `note`
- `syncStatus`
- `syncErrorMessage`
- `isDeleted`
- `createdAt`
- `updatedAt`
- `deletedAt`

#### Files to Audit/Change

- `lib/data/repositories/sync_repository.dart`
- `lib/data/services/spreadsheet_sync_service.dart`
- `lib/data/services/spreadsheet_sync_mapper.dart`
- `lib/data/models/stock_transaction.dart`
- `lib/data/models/dividend.dart`
- `lib/data/models/watchlist_item.dart`
- `lib/features/settings/settings_screen.dart`
- Google Apps Script documentation/code file if stored in repo docs.

#### Testing

Add/update tests for:

- Stock transaction serialize/deserialize.
- Dividend serialize/deserialize.
- Watchlist serialize/deserialize.
- Push/pull each entity.
- Soft delete sync.
- Latest updatedAt wins.
- No duplicate by UUID.

#### Definition of Done

- Sync manual mencakup transactions, categories, stock transactions, dividends, watchlist.
- Spreadsheet records bisa dipakai sebagai backup lintas data utama.
- `flutter analyze` lulus.
- `flutter test` lulus.
- Manual sync test di spreadsheet berhasil.

---

### Tahap 15 — Market Data Provider Hardening

**Tujuan:** Membuat klaim “market price data” lebih layak secara sistem.

#### Scope

1. Audit provider market saat ini.
2. Jika masih mock, tambahkan provider nyata sederhana dengan fallback mock.
3. Jangan mengejar real-time trading data.
4. Gunakan delayed/end-of-day price jika tersedia.
5. Tetap gunakan caching SQLite.

#### Provider Policy

Provider nyata boleh dibuat opsional via environment variable.

Contoh env:

- `MARKET_PROVIDER=mock`
- `MARKET_PROVIDER=eodhd`
- `MARKET_PROVIDER=twelvedata`
- `MARKET_CACHE_TTL_SECONDS=900`

Jika API key tidak ada:

- backend tetap hidup.
- market endpoint tetap mengembalikan fallback/mock dengan field `source: "mock"` atau `source: "fallback"`.
- UI menampilkan label “Estimasi” atau “Data contoh” jika source mock.

#### Requirements

- Endpoint tetap sama:
  - `GET /api/market/quote/<symbol>`
  - `POST /api/market/quotes`
- Response harus punya:
  - `symbol`
  - `price`
  - `currency`
  - `source`
  - `asOf`
  - `isMock` atau metadata sejenis jika perlu
- Tidak boleh membuat klaim real-time jika provider delayed/mock.
- Jangan mengirim data transaksi user ke backend.

#### Files to Audit/Change

- `backend/app/routes/market.py`
- `backend/app/services/market_data_service.py`
- `backend/app/services/cache_service.py`
- `backend/app/config.py`
- `backend/.env.example`
- `lib/data/services/market_data_api_service.dart`
- `lib/features/portofolio/portofolio_screen.dart`
- `lib/features/analisis/analisis_screen.dart`

#### Testing

- Backend mock provider test.
- Provider fallback test.
- Cache hit test.
- Flutter quote success/failure test.
- UI tetap aman saat backend mati.

#### Definition of Done

- Backend market price data tidak hanya “hardcoded tanpa status”.
- Jika mock/fallback dipakai, sistem transparan.
- Jika API provider nyata dikonfigurasi, endpoint bisa memakainya.
- `pytest` lulus.
- `flutter analyze` lulus.
- `flutter test` lulus.

---

### Tahap 16 — AI News Impact Demo Hardening

**Tujuan:** Membuat klaim AI-powered news impact analysis aman untuk demo.

#### Scope

1. Pastikan AI analysis benar-benar memanggil OpenAI jika `OPENAI_API_KEY` tersedia.
2. Pastikan fallback development tetap aman jika API key tidak tersedia.
3. UI harus menampilkan hasil analisis secara jelas.
4. Tidak boleh ada rekomendasi beli/jual.
5. Tambahkan guardrail/output validator jika belum cukup kuat.

#### Requirements

Hasil analisis harus menampilkan:

- Ringkasan edukatif.
- Impact score.
- Confidence score.
- Affected assets.
- Scenario analysis.
- Evidence atau alasan.
- Disclaimer investasi.
- Status sumber analisis jika memungkinkan: AI / fallback.

#### Forbidden Output

Sistem tidak boleh menghasilkan:

- “Beli saham ini.”
- “Jual saham ini.”
- “Pasti naik.”
- “Pasti turun.”
- “Cuan besar.”
- “Wajib entry.”

#### Files to Audit/Change

- `backend/app/services/ai_analysis_service.py`
- `backend/app/services/prompt_builder.py`
- `backend/app/routes/news.py`
- `lib/features/berita/analisis_berita_screen.dart`
- `lib/data/models/news_impact_analysis.dart`
- `lib/data/services/news_api_service.dart`

#### Testing

- AI response schema validation.
- Fallback response schema validation.
- Forbidden phrase validation.
- UI render confidence score.
- UI render affected assets.
- UI render scenario analysis.

#### Definition of Done

- Demo analysis bisa berjalan dengan OpenAI jika env tersedia.
- Fallback aman dan jelas jika env tidak tersedia.
- Tidak ada rekomendasi beli/jual.
- `pytest` lulus.
- `flutter analyze` lulus.
- `flutter test` lulus.

---

### Tahap 17 — Portfolio Movement Tracking Strengthening

**Tujuan:** Membuat klaim “portfolio movement” lebih kuat tanpa membuat chart kompleks.

#### Scope

Tambahkan ringkasan movement sederhana:

- Total modal.
- Nilai pasar estimasi.
- Estimasi unrealized gain/loss.
- Persentase gain/loss.
- Recent stock transactions.
- Recent dividends.
- Per-symbol movement vs average price.

#### Requirements

- Tidak perlu chart besar.
- Tidak perlu historical price API kompleks.
- Movement cukup berdasarkan perbandingan posisi lokal dengan market quote saat ini.
- Jika market quote tidak tersedia, tampilkan data lokal saja.
- UI tetap Bahasa Indonesia.

#### Files to Audit/Change

- `lib/data/repositories/portfolio_repository.dart`
- `lib/features/portofolio/portofolio_screen.dart`
- `lib/features/analisis/analisis_screen.dart`
- `lib/features/analisis/analysis_service.dart`

#### Definition of Done

- User bisa menunjukkan “portfolio movement” dari UI secara masuk akal.
- Tidak ada rekomendasi investasi.
- `flutter analyze` lulus.
- `flutter test` lulus.

---

### Tahap 18 — Secure Backup UX Hardening

**Tujuan:** Membuat klaim secure backup lebih pantas secara UX dan arsitektur, tanpa harus membangun sistem security enterprise.

#### Scope

1. Pastikan secret token tidak tampil polos secara permanen.
2. Tambahkan show/hide token di Settings jika belum ada.
3. Jelaskan bahwa backup memakai token Google Apps Script.
4. Jangan log secret token.
5. Jangan export token ke CSV.
6. Pastikan reset lokal tidak menghapus konfigurasi sync kecuali user memilih opsi khusus.

#### Requirements

- Token field obscure by default.
- Ada pesan privasi bahwa data dikirim ke spreadsheet milik user.
- Ada disclaimer bahwa user bertanggung jawab menjaga URL/token.
- Tidak ada secret di log/debug/snackbar.

#### Files to Audit/Change

- `lib/features/settings/settings_screen.dart`
- `lib/data/repositories/app_setting_repository.dart`
- `lib/data/services/spreadsheet_sync_service.dart`
- `lib/data/services/csv_export_service.dart`

#### Definition of Done

- Secure backup claim lebih defensible.
- Token tidak bocor di UI/log/export.
- `flutter analyze` lulus.
- `flutter test` lulus.

---

### Tahap 19 — Final Demo Readiness

**Tujuan:** Membuat aplikasi siap demo 5–7 menit.

#### Scope

1. Buat data demo lokal.
2. Buat demo script final.
3. Buat final runbook.
4. Buat screenshot checklist.
5. Buat failure recovery guide.

#### Docs to Create/Update

- `docs/manual/testing/final_cv_claim_validation.md`
- `docs/manual/testing/final_demo_script.md`
- `docs/manual/testing/final_device_regression_checklist.md`
- `docs/manual/deployment/local_demo_runbook.md`
- `docs/manual/progress/current_roadmap_status.md`

#### Demo Script 5–7 Menit

Demo harus menunjukkan:

1. Buka aplikasi.
2. Biometric/startup jika tersedia.
3. Tambah transaksi manual.
4. Tambah transaksi voice Bahasa Indonesia.
5. Lihat monthly summary.
6. Buka category management.
7. Buka portofolio saham.
8. Tampilkan buy/sell/average price.
9. Tampilkan dividen.
10. Tampilkan watchlist.
11. Buka berita.
12. Jalankan AI news impact analysis.
13. Tampilkan confidence score, affected assets, scenario analysis, disclaimer.
14. Buka tab Analisis.
15. Tampilkan portfolio movement/watchlist/news impact.
16. Jalankan sync spreadsheet.
17. Tampilkan export CSV/privacy/settings.
18. Matikan backend sebentar jika perlu untuk menunjukkan fallback lokal.

#### Definition of Done

- Demo bisa dilakukan tanpa bingung.
- Semua klaim CV bisa ditunjukkan.
- Risiko demo sudah punya mitigasi.
- Status naik dari Candidate-Ready ke Final-Ready setelah manual test perangkat nyata.

---

## Prompt Tahap 13 untuk Codex

Gunakan prompt ini untuk memulai tahap pertama lanjutan:

```text
Kita akan melanjutkan MVP MoneyPilot agar sistem benar-benar sesuai dengan detail CV yang sudah ditulis, bukan menyesuaikan CV ke sistem.

Baca dokumen:
- docs/manual/progress/current_roadmap_status.md
- docs/manual/progress/codex_progress_log.md
- docs/manual/testing/manual_test_before_next_stage.md
- jika sudah ada, baca MoneyPilot_MVP_Continuation_Plan.md atau dokumen lanjutan MVP terbaru.

Masuk ke Tahap 13: CV Claim Gap Closure Foundation.

Tujuan tahap ini:
Menutup gap paling jelas dari audit CV claim, yaitu:
1. Category management UI belum matang.
2. Onboarding copy tidak sinkron dengan fitur aktual.
3. Bahasa Indonesia UX belum konsisten.
4. Perlu checklist validasi CV claim yang lebih konkret.

Jangan mengerjakan sync expansion, market provider, AI hardening, atau portfolio movement dulu. Tahap ini fokus pada foundation yang kecil tapi penting untuk demo.

Scope implementasi:

A. Category Management UI
Implementasikan atau lengkapi halaman kategori agar benar-benar bisa digunakan dari UI.

Fitur minimal:
- Lihat daftar kategori aktif.
- Filter kategori: Semua, Pemasukan, Pengeluaran.
- Tambah kategori.
- Edit kategori.
- Soft delete kategori.
- Validasi nama kategori tidak kosong.
- Tampilkan empty state jika belum ada kategori.
- Tampilkan error state yang aman jika operasi gagal.
- Gunakan Bahasa Indonesia.

Cek dan gunakan file yang sudah ada:
- lib/features/keuangan/kategori_screen.dart
- lib/data/repositories/category_repository.dart
- lib/data/models/category.dart
- lib/core/router/app_router.dart
- lib/core/constants/route_constants.dart
- lib/features/keuangan/keuangan_screen.dart

Jangan membuat model kategori baru jika model lama sudah cukup.
Jangan menghapus kategori secara permanen. Gunakan soft delete sesuai pola repository.
Jangan merusak transaksi yang memakai kategori lama.

B. Routing dan Akses UI
Pastikan user bisa membuka Category Management dari UI yang masuk akal, misalnya dari halaman Keuangan atau Settings.
Jangan membuat route mati.

C. Onboarding Copy Update
Audit onboarding screen dan teks awal aplikasi.
Jika ada teks yang menyebut voice input atau fitur lain masih akan dibangun, perbaiki agar sesuai kondisi saat ini.
Teks onboarding harus menyebut fitur aktual secara ringkas:
- pencatatan manual
- voice input Bahasa Indonesia
- local-first storage
- spreadsheet sync
- portofolio, dividen, watchlist, berita, dan analisis edukatif

D. Bahasa Indonesia UX Audit Ringan
Rapikan teks user-facing yang masih campur Inggris di area utama yang disentuh tahap ini.
Fokus pada:
- onboarding
- category management
- settings status jika ada teks mudah diperbaiki
- empty/error/loading state yang terlihat user

Jangan ubah response backend besar kecuali sangat kecil dan aman.

E. Documentation
Update atau buat:
- docs/manual/progress/codex_progress_log.md
- docs/manual/progress/current_roadmap_status.md
- docs/manual/testing/final_cv_claim_validation.md

Isi final_cv_claim_validation.md minimal:
- daftar klaim CV
- status terbaru setelah Tahap 13
- cara manual test category management
- catatan gap yang masih tersisa untuk tahap berikutnya

F. Testing
Tambahkan/update test untuk:
- CategoryRepository tambah/edit/soft delete jika belum cukup.
- Category UI atau logic validation jika pola test app mendukung.
- Pastikan existing tests tidak rusak.

Jalankan:
flutter analyze
flutter test

Jika backend tidak diubah, pytest tidak wajib.

Batasan keras:
1. Jangan mengubah sync spreadsheet besar di tahap ini.
2. Jangan mengubah backend market/news/AI di tahap ini.
3. Jangan menambahkan fitur broker/sekuritas.
4. Jangan menambahkan rekomendasi investasi.
5. Jangan membuat chart kompleks.
6. Jangan mengirim data pribadi ke backend.
7. Jangan merusak fitur yang sudah stabil.

Output akhir yang saya inginkan:
1. Ringkasan implementasi Tahap 13.
2. File yang dibuat/diubah.
3. Penjelasan category management UI.
4. Penjelasan onboarding copy yang diperbaiki.
5. Penjelasan Bahasa Indonesia UX yang dirapikan.
6. Dokumentasi yang dibuat/diubah.
7. Hasil flutter analyze.
8. Hasil flutter test.
9. Jika ada gap yang masih tersisa untuk CV claim, sebutkan jujur.
10. Langkah manual test category management.
```


## Final Acceptance Criteria

MoneyPilot boleh disebut **MVP Final-Ready** jika semua kriteria berikut terpenuhi:

1. Semua klaim CV dapat ditunjukkan di UI, test, atau dokumentasi teknis yang jelas.
2. Category management bisa didemokan.
3. Manual income/expense berjalan.
4. Voice input Bahasa Indonesia berjalan di perangkat nyata.
5. Biometric berjalan atau fallback statusnya jelas.
6. Monthly summary benar.
7. Portofolio saham buy/sell berjalan.
8. Dividen berjalan dan tercatat.
9. Watchlist berjalan.
10. Portfolio movement bisa dijelaskan dari UI.
11. Berita keuangan tampil dari backend.
12. AI news impact analysis berjalan atau fallback aman dan jelas.
13. Confidence score, affected assets, scenario analysis, disclaimer tampil.
14. Tidak ada rekomendasi beli/jual langsung.
15. Spreadsheet sync dua arah berjalan untuk data utama sesuai klaim.
16. UUID upsert dan conflict handling terbukti lewat test.
17. Soft delete sync terbukti lewat test.
18. Backend market/news/cache berjalan.
19. Backend mati tidak membuat fitur lokal crash.
20. Export CSV berjalan.
21. Reset data lokal aman dengan konfirmasi ganda.
22. Token sync tidak bocor di log/export.
23. UI utama Bahasa Indonesia konsisten.
24. Demo 5–7 menit bisa dilakukan tanpa setup mendadak.
25. `flutter analyze` lulus.
26. `flutter test` lulus.
27. `pytest` backend lulus jika backend berubah.
28. Manual regression HP fisik lulus.
