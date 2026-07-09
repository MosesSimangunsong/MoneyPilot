# DESIGN_SYSTEM.md

# MoneyPilot Design System

## 1. Tujuan Design System

Design system ini menjadi standar visual dan pengalaman pengguna untuk aplikasi **MoneyPilot**. Dokumen ini harus dipakai oleh Codex sebagai acuan saat membangun UI Flutter agar tampilan aplikasi konsisten, rapi, dan sesuai dengan karakter yang diinginkan.

MoneyPilot adalah aplikasi keuangan pribadi, portofolio saham, dan analisis berita ekonomi. Karena aplikasi ini menyimpan dan menampilkan data yang sensitif, desain harus terasa **tenang, bersih, modern, mudah dipahami, dan tidak menakutkan**.

Arah visual utama:

```text
Minimalis putih bersih seperti aplikasi bank modern.
Dominan putih, hitam, abu-abu, dan aksen biru.
Minim card.
Banyak whitespace.
Tidak menyerupai dashboard trading yang penuh angka merah-hijau.
Bahasa aplikasi sepenuhnya Bahasa Indonesia.
```

---

## 2. Prinsip Desain Utama

### 2.1 Minimalis dan Fokus

Setiap layar hanya boleh menampilkan informasi yang benar-benar dibutuhkan pengguna pada konteks tersebut. Hindari terlalu banyak card, warna, icon, badge, dan grafik dalam satu layar.

Prioritas UI:

1. informasi utama mudah ditemukan,
2. tindakan utama jelas,
3. teks mudah dibaca,
4. layar terasa lega,
5. pengguna tidak merasa sedang memakai aplikasi trading yang kompleks.

### 2.2 Seperti Aplikasi Bank Modern

Tampilan MoneyPilot harus lebih dekat ke aplikasi bank digital yang bersih daripada aplikasi saham profesional. Gunakan garis tipis, list rapi, dan layout sederhana.

Contoh karakter visual:

```text
Bersih
Tenang
Profesional
Tidak ramai
Tidak banyak efek
Tidak banyak warna mencolok
```

### 2.3 Mentor Pemula

MoneyPilot bukan hanya mencatat angka, tetapi juga membantu pengguna memahami kondisi keuangan dan berita ekonomi. Karena itu, gaya bahasa harus seperti mentor pemula.

Ciri tone of voice:

```text
Tenang
Sederhana
Tidak menggurui
Tidak menakut-nakuti
Tidak menjanjikan keuntungan
Menggunakan kata “berpotensi”, bukan “pasti”
Menjelaskan risiko dengan bahasa mudah
```

### 2.4 Minim Card

Gunakan card hanya untuk informasi yang perlu dikelompokkan secara visual. Untuk daftar transaksi, berita, dan portofolio, lebih baik memakai list dengan divider tipis daripada banyak card bertumpuk.

Gunakan card untuk:

```text
Ringkasan saldo bulanan
Ringkasan portofolio
Hasil analisis berita
Disclaimer penting
Empty state tertentu
```

Hindari card berlebihan untuk:

```text
Setiap transaksi
Setiap berita
Setiap item menu kecil
Setiap filter
```

### 2.5 Mobile First

Semua desain harus nyaman di layar HP. Tablet atau desktop bukan prioritas MVP.

---

## 3. Identitas Visual

## 3.1 Nama Produk

```text
MoneyPilot
```

Makna visual: aplikasi yang membantu pengguna “mengemudikan” uangnya dengan lebih sadar dan tenang.

## 3.2 Bahasa UI

Seluruh UI memakai Bahasa Indonesia.

Gunakan:

```text
Beranda
Berita
Keuangan
Portofolio
Analisis
Tambah Transaksi
Catat dengan Suara
Sinkronisasi
Analisis Dampak
```

Jangan gunakan:

```text
Home
News
Finance
Portfolio
Analysis
Add Transaction
Voice Input
Sync
Impact Analysis
```

Istilah teknis boleh digunakan hanya jika sangat perlu, dan harus dijelaskan.

---

## 4. Palet Warna

MoneyPilot menggunakan warna dasar putih, hitam, abu-abu, dan biru.

### 4.1 Light Mode

Light mode adalah mode utama/default.

| Token | Warna | Hex | Penggunaan |
|---|---:|---|---|
| `background` | Putih bersih | `#FFFFFF` | Latar utama aplikasi |
| `surface` | Putih lembut | `#F8FAFC` | Area ringan / section background |
| `surfaceAlt` | Abu sangat muda | `#F1F5F9` | Divider area / disabled background |
| `primary` | Biru utama | `#2563EB` | Tombol utama, link, icon aktif |
| `primaryDark` | Biru gelap | `#1D4ED8` | Pressed state tombol utama |
| `primarySoft` | Biru sangat muda | `#EFF6FF` | Background badge/info ringan |
| `textPrimary` | Hitam lembut | `#0F172A` | Teks utama |
| `textSecondary` | Abu gelap | `#475569` | Teks sekunder |
| `textMuted` | Abu sedang | `#94A3B8` | Hint, caption, metadata |
| `border` | Abu garis | `#E2E8F0` | Divider, border input |
| `success` | Biru kehijauan | `#0F766E` | Profit/income positif |
| `successSoft` | Teal lembut | `#CCFBF1` | Background status positif |
| `danger` | Merah lembut | `#DC2626` | Error, loss, gagal |
| `dangerSoft` | Merah sangat muda | `#FEF2F2` | Background error ringan |
| `warning` | Kuning gelap | `#B45309` | Peringatan |
| `warningSoft` | Kuning muda | `#FFFBEB` | Background warning |
| `info` | Biru info | `#0284C7` | Informasi dan edukasi |

### 4.2 Dark Mode

Dark mode boleh disiapkan secara struktur, tetapi bukan prioritas visual MVP. Jika dibuat, gunakan gaya tetap tenang.

| Token | Warna | Hex | Penggunaan |
|---|---:|---|---|
| `backgroundDark` | Hitam lembut | `#0B1120` | Latar utama dark mode |
| `surfaceDark` | Navy gelap | `#111827` | Section/card |
| `surfaceAltDark` | Slate gelap | `#1E293B` | Divider/area |
| `primaryDarkMode` | Biru terang | `#60A5FA` | Aksen utama |
| `textPrimaryDark` | Putih lembut | `#F8FAFC` | Teks utama |
| `textSecondaryDark` | Abu muda | `#CBD5E1` | Teks sekunder |
| `textMutedDark` | Abu | `#94A3B8` | Caption |
| `borderDark` | Slate | `#334155` | Border |

### 4.3 Aturan Warna Profit/Loss

Jangan membuat profit terlalu mencolok atau loss terlalu menakutkan.

Gunakan:

```text
Profit/income: teal/biru kehijauan
Loss/expense: merah lembut, bukan merah menyala
Warning: kuning lembut
Info: biru
```

Jangan gunakan:

```text
Hijau neon
Merah neon
Gradient mencolok
Terlalu banyak warna dalam satu layar
```

---

## 5. Typography

### 5.1 Font

Rekomendasi font:

```text
Inter
Plus Jakarta Sans
```

Prioritas implementasi Flutter:

```yaml
google_fonts
```

Gunakan salah satu saja secara konsisten. Rekomendasi final: **Inter** karena bersih, modern, dan mudah dibaca untuk angka maupun teks panjang.

### 5.2 Skala Font

| Token | Ukuran | Berat | Penggunaan |
|---|---:|---:|---|
| `displaySmall` | 28sp | 700 | Angka ringkasan utama, misalnya total saldo |
| `headlineLarge` | 24sp | 700 | Judul layar utama |
| `headlineMedium` | 20sp | 600 | Judul section besar |
| `titleLarge` | 18sp | 600 | Judul item/detail |
| `titleMedium` | 16sp | 600 | Label penting |
| `bodyLarge` | 16sp | 400 | Teks paragraf utama |
| `bodyMedium` | 14sp | 400 | Teks normal/list |
| `bodySmall` | 13sp | 400 | Deskripsi kecil |
| `caption` | 12sp | 400 | Metadata, tanggal, status kecil |
| `button` | 14sp | 600 | Teks tombol |

### 5.3 Aturan Teks Angka

Angka uang harus mudah dibaca.

Format:

```text
Rp25.000
Rp1.250.000
- Rp35.000
+ Rp500.000
```

Untuk ringkasan besar:

```text
Rp1,25 jt
Rp950 rb
```

Namun detail transaksi tetap memakai angka penuh.

---

## 6. Spacing System

Gunakan sistem kelipatan 4 dan 8.

| Token | Nilai | Penggunaan |
|---|---:|---|
| `spaceXs` | 4px | Jarak sangat kecil |
| `spaceSm` | 8px | Jarak antar label kecil |
| `spaceMd` | 12px | Padding komponen kecil |
| `spaceLg` | 16px | Padding utama komponen |
| `spaceXl` | 24px | Jarak antar section |
| `space2xl` | 32px | Jarak besar antar blok |

Padding layar utama:

```text
Horizontal: 20px
Vertical top content: 16px
Bottom safe area: minimal 24px
```

---

## 7. Radius dan Border

MoneyPilot harus terlihat modern tetapi tidak terlalu “bulat lucu”.

| Token | Nilai | Penggunaan |
|---|---:|---|
| `radiusSm` | 8px | Badge, chip kecil |
| `radiusMd` | 12px | Input, tombol kecil |
| `radiusLg` | 16px | Card utama, bottom sheet |
| `radiusXl` | 20px | Modal / large panel |

Border:

```text
1px solid #E2E8F0
```

Shadow:

Gunakan sangat minimal. Sebisa mungkin gunakan border/divider, bukan shadow berat.

---

## 8. Layout Umum Aplikasi

### 8.1 App Shell

MoneyPilot memakai bottom navigation dengan 5 tab:

```text
Beranda
Berita
Keuangan
Portofolio
Analisis
```

Urutan final tidak boleh diubah tanpa instruksi baru.

### 8.2 Struktur Layar Standar

Setiap screen utama memakai struktur:

```text
SafeArea
└── Scaffold
    ├── AppBar sederhana / custom header
    ├── Body dengan padding horizontal 20px
    └── BottomNavigationBar
```

### 8.3 Header Layar

Header tidak perlu besar berlebihan.

Format:

```text
Judul layar
Deskripsi pendek opsional
Aksi kanan opsional: icon setting/sync/search
```

Contoh:

```text
Keuangan
Catat dan pantau pemasukan serta pengeluaranmu.
```

---

## 9. Bottom Navigation

### 9.1 Menu

| Menu | Label | Icon rekomendasi |
|---|---|---|
| Beranda | `Beranda` | home |
| Berita | `Berita` | newspaper |
| Keuangan | `Keuangan` | wallet |
| Portofolio | `Portofolio` | line-chart |
| Analisis | `Analisis` | search-check / brain |

### 9.2 Gaya Bottom Navigation

Gunakan bottom navigation putih dengan border atas tipis.

```text
Background: #FFFFFF
Active color: #2563EB
Inactive color: #94A3B8
Top border: #E2E8F0
No heavy shadow
```

### 9.3 Aturan

- Label selalu tampil.
- Jangan gunakan animasi berlebihan.
- Tab state harus tetap tersimpan ketika berpindah menu.
- Gunakan `IndexedStack` atau konfigurasi GoRouter yang menjaga state.

---

## 10. Komponen UI Utama

## 10.1 Tombol

### Primary Button

Untuk aksi utama.

Contoh:

```text
Simpan
Analisis Dampak
Sinkronkan Sekarang
Tambah Transaksi
```

Style:

```text
Background: #2563EB
Text: #FFFFFF
Radius: 12px
Height: 48px
Font: 14sp / 600
```

### Secondary Button

Untuk aksi tambahan.

Style:

```text
Background: #EFF6FF
Text: #2563EB
Border: none atau #BFDBFE
Radius: 12px
Height: 48px
```

### Text Button

Untuk aksi ringan.

Contoh:

```text
Ubah
Coba lagi
Lihat semua
Batalkan
```

Style:

```text
Text: #2563EB
No background
```

### Danger Button

Untuk hapus/reset data.

Style:

```text
Background: #FEF2F2
Text: #DC2626
```

---

## 10.2 Input Field

Style:

```text
Height: 48–52px
Radius: 12px
Border: #E2E8F0
Focused border: #2563EB
Background: #FFFFFF
Text: #0F172A
Hint: #94A3B8
```

Gunakan label jelas:

```text
Nominal
Kategori
Tanggal
Catatan
Kode Saham
Harga Beli
Jumlah Lot
```

Jangan hanya mengandalkan placeholder.

---

## 10.3 List Item

Karena desain harus minim card, list item menjadi komponen penting.

### Transaction List Item

Struktur:

```text
[Icon kategori]  Judul transaksi                  -Rp25.000
                 Kategori • 10 Jul 2026           Status sync kecil
```

Style:

```text
Background: transparent / putih
Divider bawah tipis
Padding vertical: 14–16px
Icon container kecil radius 10px
```

### News List Item

Struktur:

```text
Judul berita maksimal 2 baris
Sumber • Waktu • Kategori
Ringkasan pendek opsional
```

Gunakan thumbnail hanya jika benar-benar tersedia dan rapi. Jika thumbnail membuat layout ramai, abaikan untuk MVP.

### Portfolio Holding List Item

Struktur:

```text
BBCA                         Rp9.500
Bank Central Asia            +Rp150.000 (+5,2%)
3 lot • Avg Rp9.000
```

Gunakan warna profit/loss lembut.

---

## 10.4 Card

Card digunakan secara terbatas.

### Summary Card

Digunakan di Beranda dan Portofolio.

Style:

```text
Background: #FFFFFF
Border: #E2E8F0
Radius: 16px
Padding: 16–20px
Shadow: sangat ringan atau tanpa shadow
```

### Analysis Card

Untuk hasil analisis berita.

Gunakan section bertahap:

```text
Ringkasan
Dampak Potensial
Aset Terdampak
Data Pendukung
Skenario Positif
Skenario Negatif
Kesimpulan Pemula
Disclaimer
```

Jangan menampilkan semua sebagai card terpisah. Lebih baik gunakan satu container besar dengan divider antar section.

---

## 10.5 Badge dan Chip

Gunakan badge kecil untuk status.

Contoh:

```text
Tersinkron
Belum Sinkron
Gagal Sync
Dampak Tinggi
Keyakinan Sedang
AI
```

Style:

```text
Height: 24–28px
Radius: 999px
Padding horizontal: 8–10px
Font: 12sp
```

Warna:

```text
Info/AI: blue soft
Success: teal soft
Warning: amber soft
Danger: red soft
Neutral: slate soft
```

---

## 11. Grafik dan Visualisasi

Gunakan grafik sederhana dan tidak ramai.

Package rekomendasi:

```yaml
fl_chart
```

### 11.1 Cashflow Line Chart

Untuk Beranda.

Aturan:

```text
Maksimal 2 garis: pemasukan dan pengeluaran
Axis minimal
Grid tipis atau tanpa grid
Tidak perlu legend besar
Gunakan label sederhana
```

### 11.2 Expense Category Chart

Gunakan donut chart atau horizontal bar.

Rekomendasi MVP: horizontal bar lebih mudah dibaca daripada donut chart.

### 11.3 Portfolio Allocation Chart

Gunakan donut chart sederhana jika jumlah saham tidak banyak.

Jika saham lebih dari 6, gabungkan sisanya sebagai “Lainnya”.

### 11.4 Profit/Loss Chart

Gunakan bar sederhana.

Warna loss tidak boleh merah mencolok.

### 11.5 Mini Market Movement

Untuk detail saham, cukup gunakan angka perubahan dan persentase. Chart mini boleh post-MVP.

---

## 12. State Guidelines

## 12.1 Empty State

Empty state harus ramah dan langsung memberi aksi.

Contoh:

### Belum ada transaksi

```text
Belum ada transaksi
Mulai catat pemasukan atau pengeluaran pertamamu.
[Tambah Transaksi]
```

### Belum ada portofolio

```text
Portofoliomu masih kosong
Tambahkan transaksi beli saham untuk mulai memantau investasimu.
[Tambah Saham]
```

### Belum ada berita tersimpan

```text
Belum ada berita tersimpan
Simpan berita penting agar bisa kamu baca lagi nanti.
```

## 12.2 Loading State

Gunakan skeleton/shimmer ringan.

Package:

```yaml
shimmer
```

Aturan:

```text
Jangan pakai spinner besar terus-menerus.
Untuk list, gunakan skeleton row.
Untuk analisis AI, tampilkan teks penjelas.
```

Contoh analisis AI loading:

```text
Sedang menganalisis dampak berita...
Kami sedang mencocokkan berita dengan data pasar agar hasilnya lebih hati-hati.
```

## 12.3 Error State

Error harus memberi solusi.

Contoh:

```text
Gagal memuat data
Periksa koneksi internetmu, lalu coba lagi.
[Coba Lagi]
```

```text
Analisis belum tersedia
Data pasar pendukung belum berhasil diambil. Coba lagi beberapa saat lagi.
[Coba Lagi]
```

## 12.4 Offline State

Contoh:

```text
Kamu sedang offline
Transaksi tetap disimpan di perangkat dan akan disinkronkan saat internet tersedia.
```

## 12.5 Low Confidence State

Untuk analisis berita:

```text
Tingkat keyakinan rendah
Data pasar belum cukup mendukung kesimpulan ini. Gunakan analisis ini hanya sebagai bahan belajar, bukan dasar keputusan jual/beli.
```

---

## 13. Microcopy dan Tone of Voice

## 13.1 Aturan Umum

Gunakan bahasa:

```text
Sederhana
Tenang
Ramah
Tidak menyalahkan pengguna
Tidak terlalu teknis
Tidak memberi rekomendasi investasi langsung
```

Hindari:

```text
Saham ini pasti naik
Segera beli
Jangan sampai ketinggalan
Kerugian besar akan terjadi
Error fatal
Invalid input
```

Gunakan:

```text
Berpotensi memengaruhi
Perlu dipantau
Data belum cukup kuat
Coba periksa kembali
Kami belum bisa memastikan
```

## 13.2 Contoh Microcopy

### Konfirmasi Transaksi Suara

```text
Periksa dulu hasil catatanmu
Kami mendeteksi transaksi berikut dari suaramu. Kamu bisa mengubahnya sebelum disimpan.
```

### Sync Berhasil

```text
Data berhasil disinkronkan
Catatanmu sudah tersimpan di perangkat dan spreadsheet.
```

### Sync Gagal

```text
Sinkronisasi belum berhasil
Data tetap aman di perangkatmu. MoneyPilot akan mencoba lagi nanti.
```

### Analisis Belum Cukup Yakin

```text
Analisis ini belum cukup kuat
Beberapa data pasar belum searah dengan isi berita, jadi hasil ini perlu dibaca dengan hati-hati.
```

### Disclaimer Investasi

```text
Informasi ini hanya untuk edukasi dan bukan rekomendasi beli atau jual. Keputusan investasi tetap menjadi tanggung jawabmu.
```

### Fingerprint

```text
Verifikasi sidik jari
Gunakan fingerprint perangkatmu untuk membuka MoneyPilot.
```

### Jika Fingerprint Gagal

```text
Autentikasi gagal
Coba gunakan fingerprint lagi atau buka kunci perangkatmu sesuai pengaturan HP.
```

---

## 14. Screen Guidelines dan Wireframe Tekstual

## 14.1 Splash / App Lock Screen

Tujuan: mengamankan aplikasi dengan fingerprint.

Wireframe:

```text
[Logo MoneyPilot]
MoneyPilot
Kelola uang dan investasimu dengan lebih tenang.

[Icon fingerprint]
Gunakan fingerprint untuk membuka aplikasi

[Gunakan Fingerprint]
```

Catatan:

- Gunakan `local_auth`.
- Jika biometric tidak tersedia, tampilkan fallback sesuai kemampuan perangkat.
- Jangan membuat PIN custom dulu kecuali diperlukan.

---

## 14.2 Beranda

Tujuan: ringkasan kondisi keuangan dan investasi.

Wireframe:

```text
Halo, Moses
Ringkasan keuanganmu hari ini

Total Bulan Ini
Rp1.250.000
Pemasukan Rp2.000.000 • Pengeluaran Rp750.000

[Grafik cashflow sederhana]

Transaksi Terbaru                    Lihat semua
- Makan siang              -Rp25.000
- Uang dari orang tua      +Rp500.000
- Transportasi             -Rp18.000

Portofolio
Nilai saat ini: Rp3.450.000
P/L: +Rp120.000 (+3,6%)

Status Sinkronisasi
Semua data sudah sinkron
```

Aturan:

- Maksimal 2 summary card besar.
- Transaksi terbaru tampil sebagai list, bukan card.
- Jangan terlalu banyak grafik.

---

## 14.3 Berita

Tujuan: menampilkan berita ekonomi dan pasar.

Wireframe:

```text
Berita
Pantau berita yang bisa memengaruhi keuangan dan pasar.

[Search bar]
[Semua] [Indonesia] [Global] [Saham] [Forex] [Komoditas] [Geopolitik]

Daftar Berita
Judul berita ekonomi...
Sumber • 2 jam lalu • Global
Ringkasan singkat maksimal 2 baris

Judul berita lain...
Sumber • Hari ini • Indonesia
Ringkasan singkat maksimal 2 baris
```

Aturan:

- Gunakan list clean dengan divider.
- Thumbnail opsional.
- Badge kategori kecil.
- Jangan tampilkan hasil analisis di list terlalu panjang.

---

## 14.4 Detail Berita + Analisis AI

Wireframe:

```text
[Back]
Judul Berita
Sumber • Tanggal • Kategori

Ringkasan berita...

[Analisis Dampak]

Jika belum dianalisis:
Tombol: Analisis Dampak Berita

Jika loading:
Sedang menganalisis dampak berita...

Jika sudah ada hasil:
Tingkat Dampak: Tinggi
Tingkat Keyakinan: 78/100

Ringkasan untuk Pemula
...

Aset yang Berpotensi Terdampak
- Emas
- USD/IDR
- IHSG

Data Pendukung
- XAU/USD: naik 1,2%
- USD/IDR: melemah 0,5%

Skenario Positif
...

Skenario Negatif
...

Disclaimer
Informasi ini hanya untuk edukasi...
```

Aturan:

- Hasil analisis jangan dibuat banyak card kecil.
- Gunakan heading dan divider.
- Confidence score wajib terlihat.
- Disclaimer wajib ada.

---

## 14.5 Keuangan

Tujuan: melihat, menambah, mengedit transaksi.

Wireframe:

```text
Keuangan
Catat pemasukan dan pengeluaranmu.

[Bulan ini v] [Filter kategori]

Ringkasan
Pemasukan Rp2.000.000
Pengeluaran Rp750.000
Sisa Rp1.250.000

Hari Ini
Makan siang              -Rp25.000
Transportasi             -Rp18.000

Kemarin
Uang dari orang tua      +Rp500.000

[FAB Mic]
[+ Tambah]
```

Aturan:

- FAB utama untuk voice input.
- Tambah manual tetap tersedia.
- List transaksi memakai divider.
- Sync status kecil di item atau detail.

---

## 14.6 Tambah Transaksi Manual

Wireframe:

```text
Tambah Transaksi

Jenis
[Pengeluaran] [Pemasukan]

Nominal
Rp _________

Kategori
[Makanan & Minuman v]

Tanggal
[10 Juli 2026]

Catatan
[Opsional]

[Simpan]
```

Aturan:

- Tidak terlalu banyak field.
- Default tanggal hari ini.
- Default jenis pengeluaran jika masuk dari tombol tambah biasa.

---

## 14.7 Konfirmasi Transaksi Suara

Wireframe:

```text
Periksa dulu hasil catatanmu
Dari suara: “Saya beli kopi 25 ribu”

Jenis
[Pengeluaran]

Nominal
Rp25.000

Kategori
Makanan & Minuman

Catatan
Beli kopi

Tingkat keyakinan: 86%

[Simpan Transaksi]
[Ubah Manual]
```

Aturan:

- Tidak boleh langsung menyimpan tanpa konfirmasi.
- Jika confidence rendah, tombol simpan tetap boleh tetapi beri peringatan.

---

## 14.8 Portofolio

Tujuan: memantau saham manual dengan harga pasar dari backend.

Wireframe:

```text
Portofolio
Pantau posisi investasimu.

Nilai Portofolio
Rp3.450.000
P/L Total +Rp120.000 (+3,6%)

[Update Harga]

Daftar Saham
BBCA
3 lot • Avg Rp9.000
Harga kini Rp9.500 • +Rp150.000

TLKM
2 lot • Avg Rp3.800
Harga kini Rp3.720 • -Rp16.000

Dividen Terakhir
BBCA • Rp45.000

[+ Transaksi Saham]
```

Aturan:

- Harga saham diambil dari backend.
- Jika backend gagal, tampilkan fallback input harga manual.
- P/L tidak boleh terlalu mencolok.

---

## 14.9 Tambah Transaksi Saham

Wireframe:

```text
Tambah Transaksi Saham

Aksi
[Beli] [Jual]

Kode Saham
BBCA

Jumlah Lot
3

Harga per Saham
Rp9.000

Fee
0,15%

Tanggal
10 Juli 2026

Catatan
Opsional

[Simpan]
```

Aturan:

- Fee default boleh disimpan di AppSetting.
- Untuk jual, validasi jumlah lot tidak boleh melebihi holding.

---

## 14.10 Tambah Dividen

Wireframe:

```text
Catat Dividen

Kode Saham
BBCA

Nominal Dividen
Rp45.000

Tanggal Terima
10 Juli 2026

Catatan
Opsional

[Simpan]
```

Aturan:

- Dividen menambah total return.
- Dividen tidak mengubah average price.
- Dividen juga bisa masuk sebagai pemasukan investasi di Keuangan jika user mengaktifkan opsi tersebut.

---

## 14.11 Analisis

Tujuan: placeholder rapi untuk fitur analisis lanjutan.

Wireframe:

```text
Analisis
Ruang untuk riset keuangan yang lebih mendalam.

Fitur ini sedang disiapkan
Nantinya kamu bisa menyimpan catatan analisis saham, forex, dan ide investasi di sini.

Yang akan datang:
- Catatan analisis saham
- Watchlist lanjutan
- Analisis forex
- Rangkuman prospektus/IPO
```

Aturan:

- Jangan membuat fitur analisis kompleks dulu di tab ini.
- Tab ini boleh menampilkan watchlist ringkas jika sudah ada datanya.

---

## 14.12 Pengaturan

Wireframe:

```text
Pengaturan

Keamanan
Fingerprint aktif

Sinkronisasi Spreadsheet
URL Google Apps Script
Status terakhir: berhasil 10 Jul 2026 20.15

Portofolio
Fee beli default: 0,15%
Fee jual default: 0,25%

Tampilan
Mode: Terang

Data
Export CSV
Reset Data
```

Aturan:

- Reset Data harus memakai konfirmasi ganda.
- URL webhook tidak perlu sering ditampilkan penuh; bisa disensor sebagian.

---

## 15. Icon Guidelines

Rekomendasi package:

```yaml
lucide_icons
```

Gaya icon:

```text
Outline
Ukuran 20–24px
Stroke konsisten
Tidak menggunakan icon terlalu dekoratif
```

Contoh icon:

```text
Beranda: home
Berita: newspaper
Keuangan: wallet
Portofolio: line-chart
Analisis: search-check
Fingerprint: fingerprint
Sync: refresh-cw
Tambah: plus
Mic: mic
Bookmark: bookmark
```

---

## 16. Motion dan Animasi

Gunakan animasi secara halus.

Boleh:

```text
Fade in list
Animated number ringan
Loading shimmer
Bottom sheet slide
```

Hindari:

```text
Animasi berlebihan
Chart bergerak terlalu aktif
Transisi panjang
Efek trading-style
```

Durasi:

```text
150–250ms untuk micro interaction
250–350ms untuk page transition ringan
```

---

## 17. Accessibility

Codex harus memperhatikan hal berikut:

```text
Kontras teks cukup
Tombol minimal tinggi 44px
Jangan hanya mengandalkan warna untuk status
Gunakan label teks untuk icon penting
Font tidak terlalu kecil
Support text scale sewajarnya
```

Contoh status tidak boleh hanya merah/hijau. Sertakan teks:

```text
Gagal sync
Profit
Loss
Belum sinkron
```

---

## 18. Rekomendasi Package Flutter UI

Package yang disarankan:

```yaml
google_fonts: untuk font Inter / Plus Jakarta Sans
lucide_icons: untuk icon outline minimalis
fl_chart: untuk chart sederhana
shimmer: untuk loading skeleton
local_auth: untuk fingerprint/biometric
intl: untuk format tanggal dan mata uang
```

Catatan:

- Jangan menambah package UI besar tanpa alasan jelas.
- Hindari package komponen visual yang terlalu opinionated.
- Lebih baik buat komponen custom ringan sesuai design system ini.

---

## 19. Komponen yang Perlu Dibuat Codex

Codex sebaiknya membuat komponen reusable berikut:

```text
AppScaffold
AppHeader
AppBottomNavigation
PrimaryButton
SecondaryButton
AppTextField
AppSearchField
StatusBadge
SectionHeader
EmptyState
ErrorState
OfflineBanner
SyncStatusIndicator
MoneyAmountText
TransactionListItem
NewsListItem
PortfolioHoldingListItem
AnalysisSection
DisclaimerBox
LoadingSkeletonList
```

Aturan:

- Semua komponen harus reusable.
- Jangan menulis styling berulang di banyak screen.
- Gunakan theme tokens dari design system.

---

## 20. Catatan Implementasi untuk Codex

Saat mengimplementasikan UI MoneyPilot, Codex wajib mengikuti aturan ini:

1. Seluruh teks UI menggunakan Bahasa Indonesia.
2. Nama tab final: Beranda, Berita, Keuangan, Portofolio, Analisis.
3. Default theme adalah light mode.
4. Visual dominan putih, hitam, abu-abu, dan biru.
5. Jangan membuat desain penuh card; gunakan list dan divider untuk konten berulang.
6. Gunakan card hanya untuk ringkasan dan informasi penting.
7. Jangan membuat tampilan seperti aplikasi trading profesional yang penuh warna dan grafik.
8. Setiap screen harus memiliki empty, loading, dan error state.
9. Setiap fitur yang berhubungan dengan investasi wajib memiliki disclaimer jika ada analisis/interpretasi.
10. Jangan menggunakan warna loss yang terlalu agresif.
11. Jangan menggunakan rekomendasi beli/jual dalam UI.
12. Jangan mengubah urutan navigasi tanpa instruksi baru.
13. Jangan menambahkan fitur visual baru di luar dokumen ini tanpa persetujuan.
14. Semua komponen harus mendukung responsive mobile layout.
15. Gunakan spacing, radius, typography, dan color token yang konsisten.

---

## 21. Definition of Done untuk UI

Satu screen UI dianggap selesai jika:

```text
1. Mengikuti style putih-hitam-biru minimalis.
2. Menggunakan Bahasa Indonesia penuh.
3. Memakai komponen reusable.
4. Memiliki loading state.
5. Memiliki empty state jika data kosong.
6. Memiliki error state jika data gagal dimuat.
7. Tidak terlalu banyak card.
8. Tidak ada teks terpotong di layar kecil.
9. Tombol utama jelas.
10. Build Flutter tetap berhasil tanpa error.
```

---

## 22. Ringkasan Final

Design system MoneyPilot mengarah pada aplikasi keuangan pribadi yang:

```text
minimalis,
bersih,
terasa seperti aplikasi bank modern,
berbahasa Indonesia penuh,
dominan putih-hitam-biru,
minim card,
ramah untuk pemula,
dan tidak memberikan tekanan psikologis seperti dashboard trading.
```

Dokumen ini harus menjadi acuan utama untuk semua implementasi UI pada tahap MVP.