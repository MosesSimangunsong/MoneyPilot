# MoneyPilot Design System

## Brand Direction

MoneyPilot memakai tema `MoneyPilot Calm Navigator`: modern, tenang, terpercaya, bersih, dan ramah untuk pengguna pemula. Gaya visual mengutamakan keterbacaan nominal, hierarchy yang jelas, dan card ringan berbasis border halus, bukan shadow berat.

## Color Palette

### Brand colors

- `primaryNavy`: `#102A43`
- `primaryBlue`: `#2F6FED`
- `primaryBlueDark`: `#1D4FA3`
- `secondaryTeal`: `#0F8B8D`
- `accentGold`: `#F2B84B`

### Semantic colors

- `success`: `#168A5B`
- `danger`: `#D95555`
- `warning`: `#D99222`
- `info`: `#3977D6`

### Neutral colors

- `background`: `#F6F8FB`
- `surface`: `#FFFFFF`
- `surfaceAlt`: `#EEF3F8`
- `textPrimary`: `#182230`
- `textSecondary`: `#667085`
- `textTertiary`: `#98A2B3`
- `border`: `#E2E8F0`
- `divider`: `#EAECF0`
- `disabled`: `#C5CBD3`

### Soft semantic surfaces

- `primarySoft`
- `tealSoft`
- `goldSoft`
- `successSoft`
- `dangerSoft`
- `warningSoft`
- `infoSoft`

Gunakan `primaryNavy` untuk identitas, `primaryBlue` untuk aksi utama, `secondaryTeal` untuk insight atau aksen ringan, dan `accentGold` hanya sebagai highlight kecil. Hijau dan merah tidak dipakai sebagai dekorasi umum.

## Semantic Colors

- Nilai pemasukan, keberhasilan, dan status positif memakai `success`.
- Nilai pengeluaran, error, dan aksi destruktif memakai `danger`.
- Status menunggu atau perhatian memakai `warning`.
- Status informatif dan insight memakai `info` atau `secondaryTeal`.
- State tidak boleh dibedakan hanya dengan warna; tetap sertakan label, ikon, atau tanda `+` dan `-`.

## Typography

Tema global memakai `Plus Jakarta Sans` melalui `google_fonts`.

- `displaySmall`: 32 / 700 untuk hero amount
- `headlineLarge`: 26 / 700 untuk judul halaman
- `headlineMedium`: 18 / 700 untuk judul section
- `titleLarge`: 18 / 700
- `titleMedium`: 16 / 600 untuk judul card
- `titleSmall`: 14 / 600
- `bodyLarge`: 16 / 400
- `bodyMedium`: 14 / 400
- `bodySmall`: 12 / 500 untuk metadata
- `labelLarge`: 13 / 600 untuk tombol

Style khusus di [lib/core/theme/app_text_styles.dart](/D:/Semester%207/PersonalApp/app/lib/core/theme/app_text_styles.dart) dipakai untuk amount, metadata, dan eyebrow. Amount styles memakai tabular figures agar nominal lebih stabil dibaca.

## Spacing

Skala spacing utama di [lib/core/theme/app_spacing.dart](/D:/Semester%207/PersonalApp/app/lib/core/theme/app_spacing.dart):

- `xxs`: 2
- `xs`: 4
- `sm`: 8
- `md`: 12
- `lg`: 16
- `xl`: 20
- `xxl`: 24
- `xxxl`: 32
- `huge`: 40
- `screenHorizontal`: 20
- `screenVertical`: 20

## Radius

Token radius di [lib/core/theme/app_radius.dart](/D:/Semester%207/PersonalApp/app/lib/core/theme/app_radius.dart):

- `xs`: 6
- `sm`: 10
- `md`: 12
- `lg`: 16
- `xl`: 20
- `xxl`: 24
- `pill`: 999

Helper yang dipakai umum:

- `input`
- `button`
- `card`
- `heroCard`
- `dialog`
- `pillShape`

## Shadows

Shadow di [lib/core/theme/app_shadows.dart](/D:/Semester%207/PersonalApp/app/lib/core/theme/app_shadows.dart) sengaja tipis:

- `subtle`
- `raised`
- `overlay`

Default card tetap tanpa shadow. Border halus adalah baseline utama.

## Motion Duration

Durasi animasi di [lib/core/theme/app_durations.dart](/D:/Semester%207/PersonalApp/app/lib/core/theme/app_durations.dart):

- `fast`: 150 ms
- `normal`: 220 ms
- `slow`: 300 ms

## Card Rules

- Gunakan `AppCard` sebagai container dasar untuk surface reusable.
- Default card: putih, border halus, radius standar, tanpa shadow.
- Shadow hanya dipakai untuk kasus raised atau overlay.
- Jangan memberi gradient ke seluruh card.
- Jangan membuat semua card tampak mengambang.

Contoh:

```dart
AppCard(
  child: Text('Ringkasan tetap ringkas dan mudah dibaca'),
)
```

## Button Rules

- `PrimaryButton` full width secara default, tinggi 52, mendukung `icon`, `isLoading`, dan disabled state aman.
- `SecondaryButton` menyamakan tinggi, radius, dan tipografi dengan tombol utama.
- Gunakan label singkat dan jelas.
- Saat loading, tampilkan progress indicator dan jangan biarkan aksi ganda.

Contoh:

```dart
PrimaryButton(
  label: 'Simpan',
  icon: LucideIcons.save,
  onPressed: onSave,
)
```

```dart
SecondaryButton(
  label: 'Nanti saja',
  onPressed: onSkip,
)
```

## Input Rules

- Input memakai radius konsisten `AppRadius.input`.
- Fill color default adalah `surface`.
- Focus state memakai border `primaryBlue`.
- Error state memakai semantic `danger`.
- Disabled input tetap terbaca dengan border `disabled`.

## Icon Policy

- Lucide adalah ikon utama untuk komponen dan aksi aplikasi.
- Material icons masih boleh dipakai untuk kebutuhan sistem, widget bawaan, atau fallback yang belum punya padanan praktis.
- Migrasi ikon lama dilakukan bertahap, bukan massal di tahap fondasi.

## Empty, Loading, and Error State Rules

- `AppEmptyState` untuk data kosong dengan ikon, title, description, dan aksi opsional.
- `AppErrorState` untuk kegagalan yang bisa dipahami pengguna tanpa detail exception teknis.
- `AppLoadingState` untuk loading sederhana dengan pesan opsional dan semantic label.
- Setiap state harus memberi konteks, bukan hanya spinner polos.

Contoh:

```dart
AppEmptyState(
  icon: LucideIcons.wallet,
  title: 'Belum ada transaksi',
  description: 'Tambahkan transaksi pertamamu agar ringkasan mulai terisi.',
  primaryActionLabel: 'Tambah transaksi',
  onPrimaryAction: onAdd,
)
```

## Accessibility Baseline

- Tap target komponen interaktif minimal nyaman, mengikuti tinggi tombol 52 dan `IconButton` minimum 44.
- Kontras teks dan state fokus mengikuti semantic theme.
- Loading dan aksi penting diberi semantic label.
- Disabled state tetap terbaca, tidak hanya dibuat samar berlebihan.
- Text scaling dipertahankan melalui `TextTheme`, bukan ukuran absolut di banyak tempat.
- State tidak dibedakan hanya oleh warna.

## Component Usage Examples

## Shared Component Rules

### AppIconContainer

- Gunakan untuk latar ikon lembut yang konsisten pada list, quick action, metric, dan state.
- Cocok untuk ikon tunggal yang bersifat pendukung visual.
- Jangan dipakai untuk avatar user, thumbnail berita, atau badge status penuh.
- Jika ikon punya arti penting yang tidak diulang oleh teks sekitar, isi `semanticLabel`.
- Jika ikon hanya dekoratif, biarkan `semanticLabel` kosong agar screen reader tidak membaca ganda.

Contoh:

```dart
AppIconContainer(
  icon: LucideIcons.wallet,
  foregroundColor: AppColors.primaryBlue,
)
```

### AppStatusBadge

- Gunakan untuk status generik lintas domain: netral, informasi, sukses, peringatan, dan bahaya.
- Cocok untuk label kecil yang perlu tetap jelas walau tanpa konteks warna.
- Jangan masukkan logic domain ke dalam komponen ini.
- Jangan pakai badge ini untuk transaksi saham, sinkronisasi kompleks, atau metadata yang butuh struktur lebih kaya tanpa pemetaan eksplisit di layer pemakai.
- Sertakan `icon` bila label status akan lebih cepat dikenali dengan simbol tambahan.

Contoh:

```dart
AppStatusBadge(
  label: 'Menunggu sync',
  variant: AppStatusBadgeVariant.warning,
  icon: LucideIcons.clock3,
)
```

### AppMetricTile

- Gunakan untuk pasangan `label` dan `value` pada ringkasan beranda, keuangan, portofolio, dan analisis.
- `valueColor` ditentukan domain pemakai, bukan hard-coded di komponen.
- Nilai panjang harus tetap boleh wrap aman pada layar kecil.
- Jangan pakai komponen ini jika konten metric memerlukan interaksi, chart kecil, atau perbandingan multi-kolom yang kompleks.

Contoh:

```dart
AppMetricTile(
  label: 'Pengeluaran',
  value: 'Rp 250.000',
  valueColor: AppColors.danger,
)
```

### AppListTile

- Gunakan untuk menu sederhana, setting row, atau entry list yang berisi title, subtitle opsional, dan aksi tap penuh.
- `trailing` tidak harus berupa chevron.
- Cocok untuk menu pendukung seperti akses kategori, preferensi, atau aksi non-finansial langsung.
- Jangan pakai untuk tile transaksi, berita, atau posisi portofolio yang memiliki struktur informasi domain khusus.

Contoh:

```dart
AppListTile(
  title: 'Kelola kategori',
  subtitle: 'Atur kategori transaksi.',
  leading: Icon(Icons.category_outlined),
  trailing: Icon(Icons.chevron_right),
  onTap: onOpenCategory,
)
```

### TransactionTile

- Gunakan khusus untuk transaksi keuangan pribadi di Beranda dan Keuangan.
- Komponen menerima data presentasi, bukan repository, service, atau model mutable.
- Selalu tampilkan tanda `+` atau `-`, bukan warna saja.
- Seluruh baris boleh dijadikan tap target untuk membuka edit atau detail.
- Jangan gunakan `TransactionTile` untuk transaksi saham jika struktur informasinya berbeda signifikan.
- Semantics transaksi harus menyebut title, jenis transaksi, nominal, kategori, dan tanggal.

Contoh:

```dart
TransactionTile(
  title: 'Makan siang',
  category: 'Makanan - Tunai',
  formattedAmount: 'Rp 35.000',
  isIncome: false,
  formattedDate: '11 Jul 2026',
  onTap: onEdit,
)
```

## Home And Finance Patterns

### Hero Cashflow Pattern

- Beranda memakai satu hero cashflow sebagai fokus utama, bukan kumpulan metric card yang setara.
- Hero ini menampilkan `cashflow`, `pemasukan`, dan `pengeluaran` dari summary bulan aktif.
- Gunakan surface `primaryNavy`, kontras tinggi, dekorasi minimal, dan tanpa shadow berat.
- Saat data kosong, nominal boleh `Rp0`, tetapi jangan tampilkan angka palsu selain hasil summary aktual.

### Quick Action Pattern

- Beranda memakai tiga quick action utama: `Tambah pengeluaran`, `Tambah pemasukan`, dan `Catat dengan suara`.
- Setiap action memakai `AppIconContainer`, label singkat, tap target nyaman, dan semantic label jelas.
- Quick action adalah akses cepat, bukan tempat menjelaskan flow teknis panjang.

### Finance Filters

- Filter tipe di halaman Keuangan memakai chip atau segmented control ringan dengan state aktif yang jelas.
- State aktif tidak boleh dibedakan hanya dengan warna; sertakan tanda cek, bentuk, atau penekanan label.
- Filter tidak menambah kemampuan baru di luar logic existing.

### Transaction Grouping

- Daftar transaksi Keuangan dikelompokkan secara presentational berdasarkan tanggal.
- Label prioritas: `Hari ini`, `Kemarin`, lalu tanggal terformat dari formatter aplikasi.
- Grouping tidak boleh mengubah urutan transaksi yang sudah diberikan repository.

### Add Transaction Bottom Sheet

- Halaman Keuangan memakai satu primary add action yang membuka bottom sheet.
- Isi sheet: `Catat pengeluaran`, `Catat pemasukan`, dan `Catat dengan suara`.
- Gunakan `AppListTile` dan `AppIconContainer`, sertakan safe area dan drag handle Material 3.
- Bottom sheet hanya memilih metode input; ia tidak mengubah business logic penyimpanan.

### Technical Status Placement

- Status teknis seperti sinkronisasi Spreadsheet tidak ditampilkan sebagai konten utama di Beranda atau Keuangan.
- Informasi teknis tetap tersedia di Settings atau lokasi pendukung lain yang relevan.
- Halaman utama hanya boleh menampilkan status teknis jika ada konteks masalah yang benar-benar menghalangi tugas utama pengguna.

### AppSectionHeader

```dart
AppSectionHeader(
  title: 'Portofolio',
  subtitle: 'Pantau posisi yang masih kamu pegang.',
  action: TextButton(onPressed: onSeeAll, child: const Text('Lihat semua')),
)
```

### InfoCard

```dart
InfoCard(
  title: 'Sinkronisasi opsional',
  description: 'Spreadsheet tetap bersifat backup, bukan fondasi utama.',
  variant: InfoCardVariant.information,
)
```

### AppPage

```dart
AppPage(
  title: 'Keuangan',
  description: 'Pantau arus kas bulananmu.',
  children: <Widget>[...],
)
```

`description` boleh kosong atau `null`. Jika perlu header yang lebih kaya, gunakan `header`.

## What To Avoid

- Shadow gelap dan tebal di semua card
- Gradient di seluruh surface
- Header halaman dengan paragraf panjang yang tidak membantu
- Memakai hijau dan merah sebagai dekorasi umum
- Menambah dependency UI baru untuk kebutuhan yang sudah cukup ditangani theme internal
- Menampilkan detail exception mentah ke pengguna
- Membedakan state penting hanya dari warna
