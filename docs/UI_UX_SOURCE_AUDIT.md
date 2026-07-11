# UI/UX Source Audit MoneyPilot

## 1. Executive Summary

### Scope and method

- Audit ini dibuat hanya dari source yang ada pada repo Flutter dan backend Flask.
- Tidak ada dependency baru, migrasi database, regenerasi `.g.dart`, refactor, atau perubahan source aplikasi.
- Satu-satunya file baru yang dibuat adalah dokumen audit ini.
- Validasi read-only yang dijalankan: inventaris file dengan `rg`, pembacaan source dengan `Get-Content`, pencarian pola dengan `rg -n`, dan `flutter.bat analyze`.

### Fakta utama dari source

- Arsitektur aplikasi saat ini adalah Flutter local-first dengan Isar sebagai storage utama, `SharedPreferences` untuk state onboarding/biometric session, dan backend Flask hanya untuk health, market, news, dan AI analysis.
- Routing memakai `go_router` dengan `StatefulShellRoute.indexedStack` dan lima branch utama: `Beranda`, `Berita`, `Keuangan`, `Portofolio`, `Analisis` di [lib/core/router/app_router.dart](../lib/core/router/app_router.dart).
- Theme global memakai Material 3 light theme tunggal di [lib/core/theme/app_theme.dart](../lib/core/theme/app_theme.dart); dark theme belum ada.
- Reusable widget yang benar-benar shared masih sedikit: `AppPage`, `InfoCard`, `PrimaryButton`, `SecondaryButton`, dan `SyncStatusIndicator`.
- Banyak screen membuat private component sendiri seperti `_SectionCard`, `_SectionMessage`, `_MetaItem`, `_Section`, `_NewsTile`, `_TransactionListItem`, dan `_PositionCard`, sehingga bahasa desain tersebar di banyak file.
- Backend news saat ini hanya mengirim `id`, `title`, `summary`, `source`, `url`, `category`, `publishedAt` dari RSS Google News; field gambar tidak ada pada contract backend maupun model Flutter.
- Voice transaction sudah memakai `speech_to_text` dengan `partialResults: true`, `pauseFor: 4 detik`, `listenFor: 20 detik`, dan auto process saat status `done`, tetapi UI masih mewajibkan affordance tombol stop yang sangat menonjol.
- Portfolio saat ini tetap membutuhkan input manual `price`, `lot`, dan `shares`; backend hanya menyediakan quote current price, bukan historical execution price atau symbol search endpoint.

### Temuan paling kritis

1. Beberapa source utama saat ini tidak lolos analyze sehingga audit UI/UX perlu membedakan antara pekerjaan desain dan pekerjaan stabilisasi source:
   - [lib/features/berita/berita_screen.dart](../lib/features/berita/berita_screen.dart) memiliki `AppPage` tanpa `description` dan missing comma pada sekitar baris 47-49.
   - [lib/features/analisis/analisis_screen.dart](../lib/features/analisis/analisis_screen.dart) memiliki `_DisclaimerCard` rusak pada sekitar baris 530-542.
   - [lib/features/analisis/analysis_service.dart](../lib/features/analisis/analysis_service.dart) `loadDashboard()` tidak mengembalikan `AnalysisDashboardData` pada sekitar baris 22-118.
   - [lib/features/settings/settings_screen.dart](../lib/features/settings/settings_screen.dart) `ListView` kehilangan `children:` sebelum daftar widget pada sekitar baris 98-105.
2. UI foundation belum matang: theme global ada, tetapi token belum lengkap untuk radius, shadow, duration, typography helper, empty/error/loading state, dan navigation component standar.
3. Home, Keuangan, Portofolio, Berita, dan Settings masih menampilkan banyak card utilitarian dengan pola box yang hampir sama, namun tidak disatukan menjadi shared component.
4. Inkonsistensi navigasi masih ada:
   - `context.go('/keuangan')` string literal di [lib/features/beranda/beranda_screen.dart](../lib/features/beranda/beranda_screen.dart) sekitar baris 119.
   - Banyak route child memakai string segment inline seperti `'detail'`, `'analisis'`, `'kategori'`, `'transaksi-baru'`, `'suara'`, `'konfirmasi'` di [lib/core/router/app_router.dart](../lib/core/router/app_router.dart).
5. News UX belum mungkin menampilkan thumbnail hanya dengan perubahan UI, karena backend dan model Flutter sama-sama belum menyediakan field gambar.
6. Rencana produk “hapus input harga beli saham dan pakai realtime backend” tidak aman dengan source saat ini, karena kalkulasi cost basis portofolio justru bergantung pada `price` transaksi lokal di [lib/data/repositories/portfolio_repository.dart](../lib/data/repositories/portfolio_repository.dart).

### Informasi yang belum tersedia dari source

- Tidak ditemukan dark theme.
- Tidak ditemukan chart library, skeleton loader, network image caching, atau animation helper.
- Tidak ditemukan backend endpoint untuk symbol search/autocomplete.
- Tidak ditemukan Open Graph extraction, media RSS extraction, atau thumbnail fallback service di backend.
- Tidak ditemukan UI test coverage untuk screen utama.

## 2. Current Architecture

### High-level structure

- Flutter app entrypoint: [lib/main.dart](../lib/main.dart)
- App shell: [lib/app.dart](../lib/app.dart)
- Router: [lib/core/router/app_router.dart](../lib/core/router/app_router.dart)
- Theme: [lib/core/theme](../lib/core/theme)
- Local storage: [lib/data/local/local_database_service.dart](../lib/data/local/local_database_service.dart), [lib/data/local/isar_collections.dart](../lib/data/local/isar_collections.dart)
- Repositories: [lib/data/repositories](../lib/data/repositories)
- External-facing services: [lib/data/services](../lib/data/services)
- Features/screens: [lib/features](../lib/features)
- Shared layout/widgets: [lib/shared](../lib/shared)
- Backend Flask: [backend/app](../backend/app)
- Tests: [test](../test), [backend/tests](../backend/tests)

### Actual startup and data flow

`main()` di [lib/main.dart](../lib/main.dart) melakukan:

1. `WidgetsFlutterBinding.ensureInitialized()`
2. `LocalDatabaseService.init()` untuk membuka Isar
3. `AppSettingRepository.getOrCreateSettings()`
4. `CategoryRepository.seedDefaultCategoriesIfNeeded()`
5. inisialisasi repository dan service utama
6. `AppSessionController.initialize()`
7. `runApp(MoneyPilotApp(...))`

`MoneyPilotApp` di [lib/app.dart](../lib/app.dart) membuat `AppRouter`, mendaftarkan `WidgetsBindingObserver`, meneruskan lifecycle ke session controller, dan hanya memasang `theme: AppTheme.lightTheme`.

### Local-first boundaries

- Data pribadi lokal di Isar:
  - `AppSetting`
  - `Category`
  - `MoneyTransaction`
  - `StockTransaction`
  - `Dividend`
  - `WatchlistItem`
  - `VoiceTranscript`
  - `SyncLog`
- State onboarding dan biometric session disimpan di `SharedPreferences` lewat [lib/core/session/app_session_controller.dart](../lib/core/session/app_session_controller.dart).
- Sync Spreadsheet bersifat opsional melalui [lib/data/repositories/sync_repository.dart](../lib/data/repositories/sync_repository.dart) dan [lib/data/services/spreadsheet_sync_service.dart](../lib/data/services/spreadsheet_sync_service.dart).
- Backend Flask di [backend/app/__init__.py](../backend/app/__init__.py) hanya mendaftarkan:
  - `/api/health`
  - `/api/market/*`
  - `/api/news/*`

### UI architecture summary

- Hampir semua halaman memakai `AppPage` sebagai scaffold ringan dengan title, description, dan children list di [lib/shared/layouts/app_page.dart](../lib/shared/layouts/app_page.dart).
- Banyak section dibangun sebagai `Container + Border + BorderRadius.circular(20)` berulang.
- Bottom navigation masih memakai `BottomNavigationBar` Material icon biasa di [lib/features/shell/main_shell_screen.dart](../lib/features/shell/main_shell_screen.dart), sementara bagian lain memakai `LucideIcons`, sehingga sistem ikon bercampur.

## 3. Route and Screen Inventory

| Route | Screen | Jenis | Parameter | Repository/Service | Status |
|---|---|---|---|---|---|
| `/splash` | `SplashScreen` | startup | - | - | aktif |
| `/onboarding` | `OnboardingScreen` | onboarding | - | `AppSessionController` | aktif |
| `/kunci` | `BiometricLockScreen` | biometric/security | - | `AppSessionController` | aktif |
| `/settings` | `SettingsScreen` | settings/export/sync/security | - | app setting, category, maintenance, portfolio, sync, transaction, backend status, biometric, csv export | aktif, source saat ini broken |
| `/beranda` | `BerandaScreen` | home | - | app setting, category, sync, transaction | aktif |
| `/berita` | `BeritaScreen` | news list | query internal via state category | `NewsRepository` | aktif, source saat ini broken |
| `/berita/detail` | `DetailBeritaScreen` | news detail | `NewsRouteArguments` via `state.extra` | `NewsRepository` | aktif |
| `/berita/analisis` | `AnalisisBeritaScreen` | analysis/news | `NewsRouteArguments` via `state.extra` | `NewsRepository` | aktif |
| `/keuangan` | `KeuanganScreen` | finance | filter internal state | app setting, sync, transaction | aktif |
| `/keuangan/kategori` | `KategoriScreen` | category management | - | `CategoryRepository` | aktif |
| `/keuangan/transaksi-baru` | `AddEditTransactionScreen` | manual transaction | optional `AddEditTransactionArguments` via `extra` | category, transaction, voice transcript | aktif |
| `/keuangan/:uuid/edit` | `AddEditTransactionScreen` | manual transaction edit | `uuid` path param | category, transaction, voice transcript | aktif |
| `/keuangan/suara` | `VoiceInputScreen` | voice transaction | - | speech, parser, category, voice transcript | aktif |
| `/keuangan/suara/konfirmasi` | `VoiceConfirmationScreen` | voice confirmation | `VoiceConfirmationArguments` via `extra` | category, transaction, voice transcript | aktif |
| `/portofolio` | `PortofolioScreen` | portfolio | - | portfolio, market data API | aktif |
| `/portofolio/transaksi-saham-baru` | `TambahTransaksiSahamScreen` | stock transaction | - | `PortfolioRepository` | aktif |
| `/portofolio/catat-dividen` | `TambahDividenScreen` | dividend | - | `PortfolioRepository` | aktif |
| `/portofolio/:uuid/edit` | `TambahTransaksiSahamScreen` | stock transaction edit | `uuid` path param | `PortfolioRepository` | aktif |
| `/analisis` | `AnalisisScreen` | analysis dashboard | - | portfolio, market data, news | aktif, source saat ini broken |
| `/analisis/symbol/:symbol` | `AnalysisSymbolDetailScreen` | symbol analysis detail | `symbol` path param | portfolio, market data, news | aktif |

### Grouping by product area

- Startup: `SplashScreen`
- Onboarding: `OnboardingScreen`
- Biometric/security: `BiometricLockScreen`
- Beranda: `BerandaScreen`
- Keuangan: `KeuanganScreen`, `AddEditTransactionScreen`
- Voice transaction: `VoiceInputScreen`, `VoiceConfirmationScreen`
- Kategori: `KategoriScreen`
- Portofolio: `PortofolioScreen`, `TambahTransaksiSahamScreen`, `TambahDividenScreen`
- Market/analysis: `AnalisisScreen`, `AnalysisSymbolDetailScreen`
- Berita: `BeritaScreen`, `DetailBeritaScreen`, `AnalisisBeritaScreen`
- Settings/export/sync: `SettingsScreen`

### Route issues

#### Fakta

- Constants terdefinisi di [lib/core/constants/route_constants.dart](../lib/core/constants/route_constants.dart).
- Masih ada string literal route:
  - `context.go('/keuangan')` di [lib/features/beranda/beranda_screen.dart](../lib/features/beranda/beranda_screen.dart)
  - child path inline di [lib/core/router/app_router.dart](../lib/core/router/app_router.dart)

#### Masalah

- Navigasi belum sepenuhnya konsisten memakai constant.
- `Analisis` masih menjadi tab utama sendiri di bottom nav, padahal brief UX sebelumnya dan dokumen V2 mengarah ke analisis sebagai konteks pendamping berita/portfolio, bukan tab setara home.

#### Rekomendasi

- Standarisasi seluruh navigasi ke `RouteConstants` atau helper route builder.
- Putuskan lebih dulu apakah `Analisis` tetap tab primer atau menjadi bagian dari flow berita/portfolio sebelum redesign bottom navigation.

## 4. Shared Component Inventory

| Komponen | Path | Dipakai oleh | Fungsi | Reusable? | Masalah |
|---|---|---|---|---|---|
| `AppPage` | [lib/shared/layouts/app_page.dart](../lib/shared/layouts/app_page.dart) | banyak screen utama | scaffold + title + description | ya | terlalu generic, memaksa description panjang di header |
| `InfoCard` | [lib/shared/widgets/info_card.dart](../lib/shared/widgets/info_card.dart) | onboarding, portofolio | info card standar | ya | belum cover state/variant |
| `PrimaryButton` | [lib/shared/widgets/primary_button.dart](../lib/shared/widgets/primary_button.dart) | onboarding, biometric | wrapper `ElevatedButton` | ya | tipis, tanpa variant/icon/loading |
| `SecondaryButton` | [lib/shared/widgets/secondary_button.dart](../lib/shared/widgets/secondary_button.dart) | onboarding | wrapper `OutlinedButton` | ya | belum punya density/size variants |
| `SyncStatusIndicator` | [lib/shared/widgets/sync_status_indicator.dart](../lib/shared/widgets/sync_status_indicator.dart) | beranda, keuangan, settings | badge sync status | ya | masih hard-coded color lokal, tidak jadi token |
| `_InfoBlock` | [lib/features/beranda/beranda_screen.dart](../lib/features/beranda/beranda_screen.dart) | Beranda | card pesan/status | potensial shared | duplikat dengan `_SectionMessage`, `_MessageBox`, `_RetryBox` |
| `_SectionMessage` | [lib/features/keuangan/keuangan_screen.dart](../lib/features/keuangan/keuangan_screen.dart) | Keuangan | empty/error card | potensial shared | duplikat visual |
| `_SectionMessage` | [lib/features/portofolio/portofolio_screen.dart](../lib/features/portofolio/portofolio_screen.dart) | Portofolio | empty/error card | potensial shared | duplikat visual |
| `_SectionCard` | [lib/features/settings/settings_screen.dart](../lib/features/settings/settings_screen.dart) | Settings | grouped settings card | potensial shared | duplikat dengan section card lain |
| `_SectionCard` | [lib/features/analisis/analisis_screen.dart](../lib/features/analisis/analisis_screen.dart) | Analisis | info card | potensial shared | duplikat visual |
| `_DetailSectionCard` | [lib/features/analisis/analysis_symbol_detail_screen.dart](../lib/features/analisis/analysis_symbol_detail_screen.dart) | Detail analisis | info card + action/child | potensial shared | duplikat visual |
| `_Section` | [lib/features/berita/analisis_berita_screen.dart](../lib/features/berita/analisis_berita_screen.dart) | Analisis berita | section card | potensial shared | duplikat visual |
| `_Section` | [lib/features/keuangan/konfirmasi_suara_screen.dart](../lib/features/keuangan/konfirmasi_suara_screen.dart) | Konfirmasi suara | field summary box | potensial shared | duplikat visual |
| `_TransactionListItem` | [lib/features/keuangan/keuangan_screen.dart](../lib/features/keuangan/keuangan_screen.dart) | Keuangan | item transaksi uang | ya, seharusnya shared | masih spesifik ke screen |
| `_StockTransactionTile` | [lib/features/portofolio/portofolio_screen.dart](../lib/features/portofolio/portofolio_screen.dart) | Portofolio | item transaksi saham | ya, seharusnya shared | pola sama dengan transaksi uang tapi terpisah |
| `_NewsTile` | [lib/features/berita/berita_screen.dart](../lib/features/berita/berita_screen.dart) | Berita | item berita | ya, seharusnya shared | belum support thumbnail/image |
| `_ScoreCard` | [lib/features/berita/analisis_berita_screen.dart](../lib/features/berita/analisis_berita_screen.dart) | Analisis berita | metric score card | potensial shared | domain-specific style terisolasi |

### Komponen reusable yang belum ada

- `AppEmptyState`
- `AppErrorState`
- `AppLoadingState`
- `AppSectionHeader`
- `AppCard`
- `AppListTile`
- `AppDialog` / `AppBottomSheet`
- amount input field terstandar
- image loader/cached image wrapper
- news card dengan thumbnail
- transaction tile shared
- portfolio metric tile

## 5. Theme and Token Audit

### Fakta dari source

- Material 3: `useMaterial3: true` di [lib/core/theme/app_theme.dart](../lib/core/theme/app_theme.dart).
- Theme yang ada hanya `lightTheme`.
- Typography memakai `GoogleFonts.inter`.
- Token eksplisit yang ada hanya:
  - color constants di [lib/core/theme/app_colors.dart](../lib/core/theme/app_colors.dart)
  - spacing constants di [lib/core/theme/app_spacing.dart](../lib/core/theme/app_spacing.dart)
- [lib/core/theme/app_text_styles.dart](../lib/core/theme/app_text_styles.dart) kosong.

### Jawaban spesifik

1. Material 3 digunakan: ya.
2. Light theme dan dark theme tersedia: hanya light theme, dark theme tidak ada.
3. Warna masih hard-coded di screen: ya.
   - Contoh: [lib/shared/widgets/sync_status_indicator.dart](../lib/shared/widgets/sync_status_indicator.dart) memakai `Color(0xFFE9F8EF)`, `Color(0xFFFDECEC)`, `Color(0xFFFFF7E7)`, `Color(0xFFF4F5F7)`.
4. Radius masih hard-coded: ya.
   - Nilai yang berulang: `8`, `12`, `16`, `18`, `20`, `24`, `28`, `999`.
5. Spacing konsisten: sebagian.
   - Ada `AppSpacing`, tetapi masih banyak angka langsung seperti padding `horizontal: 10, vertical: 6`.
6. Typography konsisten: sebagian.
   - Global font konsisten Inter, tetapi banyak penggunaan `TextStyle(...)` lokal dan belum ada helper text token siap pakai.
7. Aplikasi sudah memakai logo dan asset baru secara konsisten: belum.
   - Splash memakai `assets/branding/moneypilot_logo.png`.
   - Onboarding memakai `assets/icons/moneypilot_app_icon.png`.
   - Biometric lock tidak memakai logo, hanya fingerprint icon.
8. Ada komponen yang mencampur Lucide dan Material icon tanpa aturan: ya.
   - Lucide: Home actions, onboarding, biometric, finance actions.
   - Material icons: bottom nav, beberapa app bar/action, popup menu icons, voice badge.
9. Yang perlu dipertahankan:
   - Material 3 base theme
   - `AppColors`
   - `AppSpacing`
   - penggunaan global font tunggal
   - border-based card aesthetic tipis

   Yang perlu distandardisasi:
   - radius
   - section card
   - empty/error/loading states
   - icon system
   - page header pattern
   - badge/chip variants
   - sync badge palette

### Hard-coded visual values yang paling sering muncul

- Radius: `12`, `16`, `18`, `20`, `24`, `999`
- Edge padding: `AppSpacing.lg`, `AppSpacing.xl`, `AppSpacing.screenHorizontal`, plus literal `10/6`
- Card border color: `AppColors.border`
- Hard-coded colors خارج token:
  - `0xFFE9F8EF`
  - `0xFFB7E4C7`
  - `0xFFFDECEC`
  - `0xFFF7C7C7`
  - `0xFFFFF7E7`
  - `0xFFF5D48D`
  - `0xFFF4F5F7`

## 6. Dependency Audit

| Package | Versi | Dipakai di file mana | Fungsi | Masih diperlukan? | Risiko/kompatibilitas |
|---|---:|---|---|---|---|
| `go_router` | `^16.0.0` | router + banyak screen navigasi | app routing | ya | routing sudah aktif, tapi pemakaian belum konsisten |
| `google_fonts` | `^6.3.1` | [lib/core/theme/app_theme.dart](../lib/core/theme/app_theme.dart) | font Inter | ya | menambah runtime dependency font, tapi saat ini sederhana |
| `http` | `^1.5.0` | service backend status/news/market | HTTP backend | ya | backend downtime harus ditangani UI |
| `isar` | `^3.1.0+1` | models/repositories/local db/tests | local DB utama | ya | inti local-first |
| `isar_flutter_libs` | `^3.1.0+1` | local DB/tests | runtime native Isar | ya | inti local-first |
| `local_auth` | `^2.3.0` | [lib/data/services/biometric_service.dart](../lib/data/services/biometric_service.dart) | biometric | ya | flow error state di UI belum lengkap |
| `lucide_icons` | `^0.257.0` | onboarding, beranda, keuangan, analisis, biometric | icon set | ya | bercampur dengan Material icons |
| `path_provider` | `^2.1.5` | local DB, CSV export | file path lokal | ya | aman |
| `shared_preferences` | `^2.5.3` | session controller | onboarding/session flag | ya | state penting tersebar di pref + Isar |
| `speech_to_text` | `^7.3.0` | voice feature, speech service | speech recognition | ya | lifecycle UX perlu penguatan |
| `uuid` | `^4.5.1` | id generator | UUID entities | ya | inti sync/local identity |
| `permission_handler` | `^11.3.0` | speech service | microphone permission | ya | voice flow bergantung padanya |
| `flutter_launcher_icons` | `^0.14.4` | pubspec config | app icon generation dev tool | dev only, masih diperlukan | tidak relevan ke runtime UX |

### Library candidate decision

| Kandidat | Sudah ada? | Dibutuhkan? | Fitur target | Risiko | Keputusan |
|---|---|---|---|---|---|
| Material 3 | ya | ya | foundation global | rendah | gunakan |
| `fl_chart` | tidak | ya untuk roadmap chart | home cashflow, portfolio trend | tambah dependency baru | tunda sampai fase chart |
| `cached_network_image` | tidak | ya jika thumbnail berita ditambah | berita/detail berita | butuh contract image backend dulu | tunda sampai backend image siap |
| `skeletonizer` | tidak | berguna | loading states utama | tambahan dependency | tunda |
| `flutter_animate` | tidak | opsional | splash, microinteraction | tambahan dependency | tunda |
| `google_fonts` | ya | ya | theme typography | rendah | gunakan |
| Lucide Icons | ya | ya, jika distandardisasi | icon system app | bercampur dengan Material sekarang | gunakan dengan aturan tunggal |

### Dependency gaps dari source

- Chart library: tidak ada
- Network image caching: tidak ada
- Skeleton loader: tidak ada
- Animation helper: tidak ada
- Share/export package khusus: tidak ada; CSV export dilakukan via file local service internal

## 7. Page-by-Page Audit

### Splash, Onboarding, Biometric

#### Fakta

- Splash menampilkan logo di [lib/features/startup/splash_screen.dart](../lib/features/startup/splash_screen.dart).
- Onboarding menampilkan app icon di [lib/features/onboarding/onboarding_screen.dart](../lib/features/onboarding/onboarding_screen.dart).
- Biometric lock hanya menampilkan icon fingerprint dan tombol manual di [lib/features/startup/biometric_lock_screen.dart](../lib/features/startup/biometric_lock_screen.dart).
- Prompt biometric dipicu hanya saat tombol `Gunakan Fingerprint` ditekan; tidak ada auto-trigger setelah first frame.
- `AppSessionController.unlock()` mencegah concurrent auth dengan `_isAuthenticating`.
- Relock terjadi saat app resume setelah jeda >= `AppConstants.relockDelay` di [lib/core/session/app_session_controller.dart](../lib/core/session/app_session_controller.dart).

#### Masalah

- Logo tidak konsisten across startup/onboarding/lock.
- Flow biometric berbeda antara onboarding dan lock:
  - onboarding hanya toggle preference
  - lock screen baru benar-benar memanggil auth
- State gagal/batal/tidak tersedia/terkunci tidak dibedakan detail; semua kegagalan `authenticate()` berujung `false`.
- Tidak ada state khusus untuk `locked out`, `temporarily unavailable`, atau `user canceled`.

#### Rekomendasi

- Ubah nanti hanya pada `BiometricLockScreen`, `BiometricService`, dan bila perlu `AppSessionController`, tanpa menyentuh session redirect logic.
- Jika ingin auto prompt setelah frame pertama, pasang guard satu kali per screen lifecycle agar tidak looping.

### Beranda

#### Fakta

- Header memakai `AppPage` dengan description teknis “Ringkasan uang bulan ini dirangkum dari data lokal MoneyPilot.” di [lib/features/beranda/beranda_screen.dart](../lib/features/beranda/beranda_screen.dart).
- Ada card `Status sync spreadsheet`.
- Ada summary bulanan dan daftar transaksi terbaru.
- “Lihat semua” menuju `'/keuangan'` via string literal.
- Tidak ada chart, quick action group, month filter, atau insight card terpisah.

#### Masalah

- Informasi teknis terlalu menonjol.
- Sinkronisasi spreadsheet tampil sebagai blok besar di home.
- Recent transactions masih `ListTile` default look.

#### Rekomendasi

- Beranda adalah kandidat prioritas tinggi untuk:
  - hapus description teknis
  - kecilkan/relokasi status sync
  - pecah menjadi hero summary, quick action, recent transactions yang lebih visual

### Keuangan

#### Fakta

- Ada summary, sync banner, dua tombol aksi, tombol kategori tambahan, filter tipe, lalu list transaksi.
- Tombol kategori muncul dua kali: app bar action dan tombol full-width.
- Voice masuk ke `RouteConstants.transaksiSuara`.
- Manual add ke `RouteConstants.transaksiBaru`.

#### Masalah

- Sinkronisasi spreadsheet masih menonjol.
- CTA dan hierarchy belum rapi.
- Belum ada grouping per tanggal.
- Empty/error/loading state ada, tetapi semua berupa box sederhana.

#### Rekomendasi

- Konsolidasikan kategori ke satu entry point.
- Satukan action add menjadi FAB/bottom sheet action model.
- Shared transaction tile sangat layak dibuat pada fase foundation.

### Voice transaction

#### Fakta

- Package: `speech_to_text ^7.3.0`.
- Implementasi utama:
  - screen: [lib/features/keuangan/tambah_transaksi_screen.dart](../lib/features/keuangan/tambah_transaksi_screen.dart)
  - parser: [lib/data/services/transaction_parser_service.dart](../lib/data/services/transaction_parser_service.dart)
  - confirm: [lib/features/keuangan/konfirmasi_suara_screen.dart](../lib/features/keuangan/konfirmasi_suara_screen.dart)
  - save transcript: [lib/data/repositories/voice_transcript_repository.dart](../lib/data/repositories/voice_transcript_repository.dart)
- `SpeechService.listen()` memakai:
  - `partialResults: true`
  - `pauseFor: Duration(seconds: 4)`
  - `listenFor: Duration(seconds: 20)`
  - `ListenMode.dictation`
- `VoiceInputScreen._handleSpeechStatus()` memanggil `_stopAndProcess()` saat status `SpeechToText.doneStatus` dan transcript tidak kosong.
- Hasil selalu menuju screen konfirmasi sebelum `createTransaction()`.

#### Jawaban spesifik

1. Auto-stop setelah 2-3 detik diam sudah didukung implementasi sekarang?
   - Sebagian. Secara source sudah ada `pauseFor`, tetapi nilainya 4 detik, bukan 2-3 detik.
2. `pauseFor`, timeout, status callback, timer internal sudah dipakai?
   - Ya untuk `pauseFor`, `listenFor`, `onStatus`, `onError`, `onSoundLevelChange`, dan `onResult`.
   - Tidak ada timer internal custom terpisah.
3. Tombol stop manual masih diwajibkan?
   - Secara UX sekarang ya, karena tombol `Berhenti` ditampilkan sebagai aksi utama saat listening.
4. Transcript partial ditampilkan?
   - Ya, `_transcript` diupdate dari `partialResults`.
5. Hasil selalu masuk ke confirmation screen?
   - Ya, bila transcript tidak kosong dan parsing berhasil sampai membuat `VoiceTranscript`.
6. Risiko speech berhenti terlalu cepat?
   - Ada jika `pauseFor` nanti diturunkan tanpa pengujian frasa Bahasa Indonesia yang punya jeda alami.
7. File mana yang harus disentuh pada tahap implementasi?
   - minimal:
     - [lib/data/services/speech_service.dart](../lib/data/services/speech_service.dart)
     - [lib/features/keuangan/tambah_transaksi_screen.dart](../lib/features/keuangan/tambah_transaksi_screen.dart)
     - [lib/features/keuangan/konfirmasi_suara_screen.dart](../lib/features/keuangan/konfirmasi_suara_screen.dart)
8. Test yang sudah ada dan belum ada?
   - Sudah ada test parser di [test/data/services/transaction_parser_service_test.dart](../test/data/services/transaction_parser_service_test.dart).
   - Belum terlihat test widget/integration untuk voice screen lifecycle, permission UX, auto-stop timing, atau navigation after save.

### Berita dan detail berita

#### Fakta

- Berita list memakai chip kategori dan `_NewsTile` text-only.
- Detail berita menampilkan judul, metadata, summary, URL text, dan tombol `Analisis Dampak`.
- Tidak ada image widget/network image di berita list maupun detail.

#### Masalah

- Thumbnail tidak mungkin muncul dengan source sekarang tanpa backend/model change.
- Detail URL hanya `SelectableText`; belum ada launcher/open external link.
- Loading state masih card text, belum skeleton.

### Analisis berita

#### Fakta

- UI menampilkan metadata badge (`isCached`, `isFallback`, `isAiGenerated`), score, section teks/list, dan disclaimer.
- Model metadata cukup lengkap di [lib/data/models/news_impact_analysis.dart](../lib/data/models/news_impact_analysis.dart).
- Backend memaksa disclaimer aman dan memblokir frasa buy/sell tertentu di [backend/app/services/ai_analysis_service.py](../backend/app/services/ai_analysis_service.py).

#### Masalah

- Banyak section terlihat seperti rendering contract mentah, belum diolah menjadi hierarchy editorial.
- `impactScore/confidenceScore` masih ditampilkan sebagai angka mentah `/100`.

### Portofolio

#### Fakta

- Header action: tambah transaksi saham dan catat dividen.
- Ada `InfoCard` besar yang menjelaskan sync saham/dividen belum aktif.
- Portfolio summary hanya angka; tidak ada chart.
- Position card menampilkan lot, lembar, average buy price, current market price, market value, unrealized P/L.
- `TambahTransaksiSahamScreen` tetap meminta:
  - symbol
  - companyName optional
  - actionType
  - lot
  - shares
  - price
  - fee
  - transactionDate
  - note
- Lot otomatis mengisi shares x100, tetapi user tetap bisa override.

#### Jawaban spesifik

1. Field yang diminta saat menambah transaksi saham:
   - symbol, company name, action type, lot, shares, price, fee, date, note
2. Harga beli disimpan?
   - Ya, field `price`
3. Jumlah lot dan jumlah lembar disimpan?
   - Ya, `lot` dan `shares`
4. Ticker divalidasi?
   - Hanya non-empty string di UI; belum ada validasi ke backend/search
5. Backend punya endpoint search symbol/quote?
   - Quote: ya (`GET /api/market/quote/<symbol>`, `POST /api/market/quotes`)
   - Search symbol/autocomplete: tidak ditemukan
6. Harga realtime/delayed/tidak diketahui?
   - Backend mengembalikan `asOf`, `cachedAt`, `isFallback`, `isStale`, jadi bisa delayed/fallback; realtime tidak dijamin
7. Timestamp quote disimpan/ditampilkan?
   - Ditampilkan via `asOf`/`cachedAt`
8. Ada data historis untuk chart?
   - Tidak ditemukan
9. Chart dapat dibangun dari transaksi lokal sekarang?
   - Bisa untuk cost basis/history lokal sederhana, tetapi belum ada helper/chart library siap pakai
10. Current value dan cost basis dibedakan?
   - Ya
11. Dividen masih manual?
   - Ya
12. Backend punya data dividend per share/corporate action?
   - Tidak ditemukan
13. Risiko jika harga transaksi manual dihapus?
   - Cost basis, average buy price, realized/unrealized profit akan rusak
14. Perubahan minimal yang aman?
   - Tetap simpan `price` transaksi; bila menambah auto-quote, jadikan prefill/assist, bukan pengganti sumber cost basis

### Settings

#### Fakta

- Section aktual: keamanan, status backend, sinkronisasi spreadsheet, kategori transaksi, ekspor CSV, reset data lokal, privasi/disclaimer.
- Settings memuat informasi teknis panjang tentang server, sync stages, entity spreadsheet, dan reset scope.

#### Masalah

- Sangat teknis untuk halaman settings umum.
- Spreadsheet dan backend status terlalu verbose.
- Source saat ini broken secara syntax, jadi halaman belum stabil bahkan sebelum redesign.

## 8. Backend Contract Audit

### News contract

| Field | Backend | Model Flutter | Dipakai UI | Nullable | Catatan |
|---|---|---|---|---|---|
| `id` | ya | `NewsArticle.id` | tidak terlihat di UI | effectively non-null | hash dari link+title |
| `title` | ya | `title` | ya | fallback empty string | utama |
| `summary` | ya | `summary` | ya | fallback empty string | utama |
| `source` | ya | `source` | ya | fallback `Google News`/empty | metadata |
| `url` | ya | `url` | ya di detail | fallback empty string | detail only |
| `category` | ya | `category` | ya | fallback `Global` | metadata/filter |
| `publishedAt` | ya | `publishedAt` | ya | fallback now | metadata |
| `imageUrl`/thumbnail | tidak | tidak | tidak | - | tidak tersedia |

### Analysis contract

- Backend menerima `newsId`, `title`, `summary`, `url`, `category`.
- Backend mengembalikan:
  - `judul`, `ringkasan`, `kategori`
  - `asetTerdampak`
  - `impactScore`
  - `confidenceScore`
  - `dampakPotensial`
  - `rantaiSebabAkibat`
  - `dataPendukung`
  - `skenarioPositif`
  - `skenarioNegatif`
  - `halYangPerluDipantau`
  - `kesimpulanPemula`
  - metadata `isAiGenerated`, `isFallback`, `isCached`, `provider`, `model`, `fallbackReason`, `generatedAt`, `cacheTtlSeconds`, `disclaimer`

### Market contract

- `GET /api/market/quote/<symbol>`
- `POST /api/market/quotes`
- Field utama:
  - `symbol`
  - `displaySymbol`
  - `price`
  - `currency`
  - `source`
  - `provider`
  - `isMock`
  - `isFallback`
  - `isStale`
  - `asOf`
  - `cachedAt`
  - `cacheTtlSeconds`
  - `message`

## 9. Voice Capability Audit

### Capability summary

- Permission: via `permission_handler`
- Recognition: via `speech_to_text`
- Locale: mencari `id_ID` lalu locale `id*`
- Partial transcript: ya
- Sound level callback: ya
- Auto processing on done status: ya
- Manual fallback to form: ya
- Confirmation before save: ya
- Transcript persistence: ya

### Gaps

- Tidak ada test UI untuk permission denied / permanently denied / lifecycle background.
- Tidak ada semantic or accessibility treatment khusus pada visualizer.
- Timeout and silence behavior bergantung langsung pada plugin, belum ada product-level tuning wrapper.

## 10. News Thumbnail Audit

### Jawaban spesifik

1. Backend sudah mengirim `imageUrl` atau field sejenis?
   - Tidak
2. RSS source menyediakan media thumbnail?
   - Tidak diparse oleh service sekarang; source code hanya membaca title/link/description/source/pubDate
3. UI mengabaikan field gambar yang sebenarnya sudah ada?
   - Tidak, karena model Flutter juga tidak punya field gambar
4. Flutter sudah punya network image caching?
   - Tidak
5. Fallback ketika gambar tidak tersedia?
   - Belum ada, karena gambar belum didukung
6. Detail berita dan source URL sudah aman?
   - URL hanya ditampilkan sebagai teks; tidak ada launcher, preview, atau validation beyond string
7. Perubahan mana yang hanya UI dan mana yang butuh backend?
   - UI-only: card layout, typography, metadata arrangement, loading/error states
   - Butuh backend + model + UI: thumbnail/image support

## 11. Portfolio Data Audit

### Actual flow

`input user -> form stock/dividend -> PortfolioRepository -> Isar local -> optional MarketDataApiService quote pull -> PortfolioOverview recalculation -> UI`

### Safe conclusions

- Backend market hanya memberi current quote, bukan data transaksi historis.
- PortfolioRepository menghitung position dari transaksi lokal dan current market price opsional.
- Fallback saat market quote tidak ada adalah `averageBuyPrice`, bukan nol, supaya market value tidak jatuh ke 0.
- Dividen otomatis juga membuat `MoneyTransaction` income category `Dividen`.

## 12. Accessibility and State Matrix

| Screen | Loading | Empty | Error | Retry | Offline/backend unavailable | Permission denied | Success feedback | Keyboard handling | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Splash | basic | n/a | no | no | n/a | n/a | no | n/a | logo only |
| Onboarding | no async loading | n/a | snackbar name validation only | no | n/a | biometric support info only | no | text field basic | no text-scale evidence |
| Biometric lock | authenticating label | n/a | single generic error text | implicit via same button | no dedicated unavailable state | no dedicated state | no | n/a | prompt manual only |
| Beranda | spinner | yes | yes | no explicit button | sync/home data messages | n/a | no | n/a | no pull-to-refresh |
| Keuangan | spinner | yes | yes | no explicit button | sync banner only | n/a | snackbar delete | forms elsewhere | no grouping/date headers |
| Voice input | preparing spinner | transcript empty guidance | yes | yes (`Coba rekam lagi`) | speech unavailable message | yes | no success until save | n/a | lifecycle handled |
| Voice confirm | category load implicit | n/a | snackbar validation | manual edit path | n/a | n/a | snackbar save | form standard | no dedicated loading skeleton |
| Berita | message box | yes | yes | yes | backend message generic | n/a | no | n/a | no pull-to-refresh |
| Detail berita | no | n/a | no | no | n/a | n/a | no | n/a | no link action |
| Analisis berita | message box | n/a | yes | yes | backend/AI fallback metadata shown | n/a | no | n/a | strongest metadata handling |
| Portofolio | spinner | yes | yes | no explicit button | market status message | n/a | snackbar delete | n/a | no chart/visual trend |
| Tambah transaksi saham | spinner edit load | n/a | snackbar/form validation | no | n/a | n/a | snackbar save | form/date picker okay | no ticker validation |
| Tambah dividen | no | n/a | snackbar/form validation | no | n/a | n/a | snackbar save | form/date picker okay | manual-heavy |
| Settings | spinner | n/a | snackbar partial load | backend check button | yes | biometric support display only | snackbar save/export/reset | token/url forms | source currently broken |

## 13. Duplication and Technical Debt

### UI duplication

- Repeated bordered card shells across:
  - Beranda
  - Keuangan
  - Portofolio
  - Settings
  - Analisis
  - Berita
- Repeated “message box” components:
  - `_InfoBlock`
  - `_SectionMessage`
  - `_MessageBox`
  - `_RetryBox`
  - `_SectionCard`
  - `_DetailSectionCard`
- Repeated metric tile patterns:
  - `_MetricColumn`
  - `_SummaryValue`
  - `_SummaryMetric`
  - `_MetaItem`
  - `_DetailMetric`
  - `_ScoreCard`

### Technical debt

- Source compile errors on key tabs.
- `app_text_styles.dart` kosong.
- Route constants belum dipakai penuh.
- Icon system tidak tunggal.
- Theme tokens belum lengkap.
- Page headers terlalu bergantung pada description string panjang.

## 14. Library Decisions

### Use

- Material 3 built-in
- `google_fonts`
- `lucide_icons` dengan aturan tunggal

### Delay

- `fl_chart`
- `cached_network_image`
- `skeletonizer`
- `flutter_animate`

### Do not decide yet

- package tambahan untuk voice, share, atau UI kit penuh; source saat ini belum menuntut penggantian total

## 15. Prioritized Implementation Plan

### Phase 1. Design foundation

- Tujuan: token, card shell, section header, empty/error/loading state, icon policy, page header policy
- File kemungkinan disentuh:
  - `lib/core/theme/*`
  - `lib/shared/layouts/app_page.dart`
  - `lib/shared/widgets/*`
- Dependency: none required
- Risiko: mempengaruhi banyak screen
- Test: golden/widget smoke + `flutter analyze`
- Acceptance criteria: header, card, and state patterns unified
- Tidak boleh diubah: repository logic, Isar schema, backend contract

### Phase 2. Shared components

- Tujuan: ekstraksi `AppCard`, `AppSectionHeader`, `AppEmptyState`, `AppErrorState`, `AppMetricTile`, `TransactionTile`, `NewsCard`
- File kemungkinan disentuh: `lib/shared/widgets/*`, screen utama pemakai
- Dependency: none
- Risiko: regressions visual lintas screen
- Test: widget tests untuk component states
- Acceptance criteria: duplikasi container section turun signifikan
- Tidak boleh diubah: alur data/sync

### Phase 3. Beranda dan Keuangan

- Tujuan: hierarchy ulang, quick actions, hilangkan sync card utama, perbaiki list transaksi
- File kemungkinan disentuh:
  - `lib/features/beranda/beranda_screen.dart`
  - `lib/features/keuangan/keuangan_screen.dart`
- Dependency: none
- Risiko: navigation/action discoverability
- Test: manual interaction + widget smoke
- Acceptance criteria: pengguna paham cashflow dan action utama dalam <5 detik
- Tidak boleh diubah: repository transaction, sync behavior

### Phase 4. Voice UX

- Tujuan: auto-start/auto-stop UX lebih natural, state lebih jelas
- File kemungkinan disentuh:
  - `lib/data/services/speech_service.dart`
  - `lib/features/keuangan/tambah_transaksi_screen.dart`
  - `lib/features/keuangan/konfirmasi_suara_screen.dart`
- Dependency: none initially
- Risiko: speech cut too early, loop state
- Test: manual device testing + parser tests tetap hijau
- Acceptance criteria: user tidak wajib menekan stop, hasil tetap selalu ke confirmation
- Tidak boleh diubah: package speech, parser core tanpa alasan kuat

### Phase 5. News UX

- Tujuan: featured news, card layout, loading/error polish
- File kemungkinan disentuh:
  - `lib/features/berita/berita_screen.dart`
  - `lib/features/berita/detail_berita_screen.dart`
  - `lib/data/models/news_article.dart`
  - `lib/data/services/news_api_service.dart`
  - backend news service jika thumbnail ditambahkan
- Dependency: mungkin `cached_network_image` nanti
- Risiko: contract drift Flutter-backend
- Test: service tests + backend tests + manual small-screen layout
- Acceptance criteria: berita menarik tanpa mematahkan fallback
- Tidak boleh diubah: prinsip backend tidak menyimpan data pribadi

### Phase 6. Analysis UX

- Tujuan: hierarchy fakta vs interpretasi, impact display lebih aman, fallback/cached states lebih jelas
- File kemungkinan disentuh:
  - `lib/features/berita/analisis_berita_screen.dart`
  - `lib/features/analisis/*`
- Dependency: none required
- Risiko: overclaiming AI output
- Test: widget tests metadata states + backend analysis tests
- Acceptance criteria: tidak tampak seperti JSON mentah, disclaimer tetap jelas
- Tidak boleh diubah: backend safety guard buy/sell

### Phase 7. Portfolio UX

- Tujuan: summary hierarchy, chart plan, safer stock form UX
- File kemungkinan disentuh:
  - `lib/features/portofolio/*`
  - `lib/data/services/market_data_api_service.dart`
  - backend market jika symbol search kelak ditambah
- Dependency: mungkin `fl_chart` nanti
- Risiko: cost basis confusion
- Test: repository tests wajib tetap hijau
- Acceptance criteria: current value vs cost basis jelas, form lebih ringan
- Tidak boleh diubah: schema Isar, keharusan menyimpan price transaksi

### Phase 8. Settings and security

- Tujuan: pengelompokan ulang, kurangi teks teknis, perbaiki biometric entry communication
- File kemungkinan disentuh:
  - `lib/features/settings/settings_screen.dart`
  - `lib/features/startup/biometric_lock_screen.dart`
  - `lib/features/onboarding/onboarding_screen.dart`
- Dependency: none
- Risiko: kebingungan user soal sync vs backend
- Test: manual flow startup/settings
- Acceptance criteria: settings lebih mudah dipakai user umum
- Tidak boleh diubah: session redirect logic

### Phase 9. Polish/accessibility/testing

- Tujuan: tap targets, text scale, semantic labels, retry consistency, golden/widget tests
- File kemungkinan disentuh: lintas feature
- Dependency: optional only if later justified
- Risiko: scope creep
- Test: widget/golden/manual accessibility checks
- Acceptance criteria: state matrix coverage meningkat
- Tidak boleh diubah: persistence/business rules

## 16. Open Questions

- Apakah tab `Analisis` akan tetap menjadi tab bawah permanen, atau dipindahkan menjadi bagian dari berita/portfolio?
- Apakah nanti thumbnail berita diambil dari RSS media, Open Graph, atau provider lain?
- Apakah stock form masa depan hanya akan mem-prefill current quote, atau juga mencari historical price untuk cost basis?
- Apakah dark theme memang akan didukung, atau fokus tetap light-only?

## 17. Exact Files Recommended for Phase 1

- [lib/core/theme/app_theme.dart](../lib/core/theme/app_theme.dart)
- [lib/core/theme/app_colors.dart](../lib/core/theme/app_colors.dart)
- [lib/core/theme/app_spacing.dart](../lib/core/theme/app_spacing.dart)
- [lib/core/theme/app_text_styles.dart](../lib/core/theme/app_text_styles.dart)
- [lib/shared/layouts/app_page.dart](../lib/shared/layouts/app_page.dart)
- [lib/shared/widgets/info_card.dart](../lib/shared/widgets/info_card.dart)
- [lib/shared/widgets/primary_button.dart](../lib/shared/widgets/primary_button.dart)
- [lib/shared/widgets/secondary_button.dart](../lib/shared/widgets/secondary_button.dart)
- [lib/shared/widgets/sync_status_indicator.dart](../lib/shared/widgets/sync_status_indicator.dart)
- File shared baru yang masuk akal dibuat pada fase implementasi nanti:
  - `lib/shared/widgets/app_card.dart`
  - `lib/shared/widgets/app_section_header.dart`
  - `lib/shared/widgets/app_empty_state.dart`
  - `lib/shared/widgets/app_error_state.dart`
  - `lib/shared/widgets/app_loading_state.dart`

