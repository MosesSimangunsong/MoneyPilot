# UI/UX Audit MoneyPilot — Versi 2

## 1. Tujuan Dokumen

Dokumen ini menjadi dasar peningkatan UI/UX MoneyPilot tanpa mengubah prinsip utama aplikasi:

- mobile-first untuk Android;
- local-first dengan Isar;
- data transaksi pribadi tetap disimpan lokal;
- Google Spreadsheet hanya untuk backup/sinkronisasi opsional;
- backend Flask hanya untuk market, berita, cache, dan analisis;
- analisis AI bersifat edukatif dan tidak memberikan instruksi beli atau jual.

Audit ini memisahkan tiga jenis pekerjaan agar implementasinya tidak tercampur:

1. **Perbaikan visual**: warna, tipografi, jarak, kartu, ikon, hierarki informasi, dan animasi.
2. **Perbaikan UX**: alur interaksi, penempatan aksi, feedback, loading, empty state, dan error state.
3. **Perubahan produk/teknis**: thumbnail berita dari backend, auto-stop input suara, validasi kode saham, harga market, grafik portofolio, dan kalkulasi dividen.

---

# 2. Arah Desain Utama

## 2.1 Nama Tema

**MoneyPilot Calm Navigator**

Karakter yang ingin dibangun:

- tenang dan terpercaya;
- modern tetapi tidak berlebihan;
- terasa seperti aplikasi finansial yang matang;
- ramah bagi mahasiswa dan pengguna pemula;
- tidak terlihat seperti template AI;
- tidak menyerupai aplikasi trading agresif;
- informasi penting mudah dipahami dalam beberapa detik.

## 2.2 Palet Warna

### Warna brand

- **Primary Navy**: `#102A43`
- **Primary Blue**: `#2F6FED`
- **Secondary Teal**: `#0F8B8D`
- **Accent Gold**: `#F2B84B`

### Warna semantik

- **Success/Income**: `#168A5B`
- **Danger/Expense**: `#D95555`
- **Warning**: `#D99222`
- **Information**: `#3977D6`

### Warna netral

- **App Background**: `#F6F8FB`
- **Surface**: `#FFFFFF`
- **Surface Alternative**: `#EEF3F8`
- **Text Primary**: `#182230`
- **Text Secondary**: `#667085`
- **Border**: `#E2E8F0`

Aturan penggunaan:

- navy menjadi warna utama untuk header, navigasi, dan elemen yang membutuhkan rasa percaya;
- biru dipakai untuk aksi utama;
- teal dipakai sebagai aksen insight, perkembangan, dan navigasi;
- emas hanya dipakai sedikit untuk highlight premium atau pencapaian;
- hijau dan merah tidak boleh menjadi dekorasi umum karena keduanya memiliki makna finansial;
- gradient hanya boleh dipakai pada satu atau dua hero card, bukan pada seluruh kartu.

## 2.3 Tipografi

Gunakan **Plus Jakarta Sans** sebagai font utama MoneyPilot.

Hierarki yang disarankan:

- Display/hero amount: 30–34 px, weight 700;
- Page title: 24–28 px, weight 700;
- Section title: 18–20 px, weight 700;
- Card title: 15–17 px, weight 600;
- Body: 14–16 px, weight 400–500;
- Caption/metadata: 12–13 px, weight 400–500.

Nominal uang harus memakai angka tabular jika memungkinkan agar digit tidak bergerak saat nilainya berubah.

## 2.4 Bentuk dan Spacing

Skala spacing:

- 4, 8, 12, 16, 20, 24, 32, 40.

Radius:

- input dan button: 12–14;
- kartu standar: 16;
- hero card: 20–24;
- chip: pill radius.

Bayangan:

- sangat tipis;
- lebih mengutamakan border halus daripada shadow tebal;
- jangan memakai shadow pada semua elemen.

## 2.5 Prinsip Visual

- Satu halaman hanya memiliki satu fokus utama.
- Hindari terlalu banyak kartu dengan ukuran dan gaya yang sama.
- Hindari paragraf penjelasan panjang di bagian header.
- Gunakan whitespace untuk membangun kesan elegan.
- Jangan membuat setiap bagian memakai ikon, badge, gradient, dan shadow sekaligus.
- Gunakan maksimal satu keluarga ikon utama, yaitu Lucide.
- Semua aksi utama harus mudah dijangkau dengan satu tangan.

---

# 3. Fondasi Global yang Perlu Dibangun

## 3.1 Design Token

Tambahkan atau rapikan:

```text
lib/core/theme/
├── app_colors.dart
├── app_spacing.dart
├── app_radius.dart
├── app_typography.dart
├── app_shadows.dart
├── app_durations.dart
└── app_theme.dart
```

## 3.2 Komponen Internal

Komponen yang perlu distandardisasi:

```text
lib/shared/widgets/
├── app_card.dart
├── app_section_header.dart
├── app_empty_state.dart
├── app_error_state.dart
├── app_loading_state.dart
├── app_skeleton.dart
├── app_bottom_sheet.dart
├── app_chip.dart
├── app_icon_button.dart
├── app_text_field.dart
├── primary_button.dart
├── secondary_button.dart
├── money_amount.dart
├── money_summary_card.dart
├── transaction_tile.dart
├── category_avatar.dart
├── news_card.dart
├── portfolio_summary_card.dart
└── metric_tile.dart
```

Tujuannya adalah agar Beranda, Keuangan, Portofolio, Berita, dan Pengaturan memakai bahasa desain yang sama.

## 3.3 State Wajib

Setiap halaman yang memuat data harus memiliki:

- initial loading;
- pull-to-refresh;
- empty state;
- partial data state;
- offline state;
- backend unavailable state;
- error state;
- retry state;
- success feedback.

Jangan hanya menampilkan `CircularProgressIndicator` di tengah halaman tanpa konteks.

---

# 4. Audit per Halaman

## 4.1 Splash dan Biometric Lock

### Masalah saat ini

- identitas MoneyPilot belum kuat ketika aplikasi pertama kali dibuka;
- logo belum selalu tampil pada layar keamanan;
- pengguna masih perlu menekan tombol untuk mulai verifikasi fingerprint;
- tampilan awal belum terasa sebagai pengalaman produk yang matang;
- belum jelas state ketika biometric dibatalkan, gagal, terkunci, atau tidak tersedia.

### Rancangan baru

Urutan tampilan:

1. logo MoneyPilot tampil di tengah;
2. animasi fade/scale ringan selama 200–300 ms;
3. teks singkat: **“Keuanganmu, tetap dalam kendalimu.”**;
4. aplikasi langsung meminta biometric setelah layar siap;
5. tidak ada tombol “Gunakan fingerprint” sebagai langkah awal;
6. tombol **“Coba lagi”** hanya muncul jika prompt gagal atau dibatalkan;
7. jika biometric terkunci, tampilkan penjelasan yang jelas;
8. jangan membuat prompt biometric muncul berulang-ulang tanpa kendali.

### Acceptance criteria

- logo tidak pecah dan tidak terlalu kecil;
- prompt biometric hanya dipanggil sekali pada satu siklus pembukaan layar;
- tidak terjadi infinite prompt;
- ada fallback yang aman;
- tampilan tetap baik ketika biometric tidak didukung;
- proses berhasil mengarahkan pengguna ke Beranda tanpa jeda yang membingungkan.

---

## 4.2 Onboarding

### Sasaran

Onboarding harus memperkenalkan manfaat, bukan menjelaskan arsitektur teknis terlalu panjang.

### Rancangan baru

Tahap onboarding tetap singkat:

1. **Kenali MoneyPilot** — manfaat utama dan nama panggilan;
2. **Lindungi data** — pilihan biometric;
3. **Catat lebih cepat** — pengenalan transaksi suara;
4. **Data tetap milikmu** — penjelasan singkat local-first dan backup opsional.

### Perbaikan visual

- logo hanya tampil dominan pada langkah pertama;
- gunakan ilustrasi ikon sederhana untuk langkah berikutnya;
- progress indicator diberi label posisi, misalnya `1 dari 4`;
- tombol utama menempel konsisten pada bagian bawah;
- teks maksimal dua paragraf pendek per langkah;
- keyboard tidak boleh menyebabkan tombol utama tertutup.

---

## 4.3 Beranda

### Masalah saat ini

- deskripsi “Ringkasan uang bulan ini dirangkum dari data lokal MoneyPilot” tidak memberi nilai penting;
- kartu status sinkronisasi terlalu menonjol;
- hierarki informasi masih datar;
- ringkasan keuangan belum menjadi focal point;
- transaksi terbaru masih terlihat seperti `ListTile` standar;
- belum ada quick action yang kuat;
- belum ada insight visual.

### Konten yang dihapus dari Beranda

- deskripsi teknis tentang data lokal;
- kartu besar status Google Spreadsheet;
- informasi teknis sinkronisasi yang tidak dibutuhkan saat pengguna membuka aplikasi.

Status sinkronisasi tetap tersedia di Pengaturan dan dapat ditampilkan sebagai indikator kecil hanya ketika ada masalah.

### Struktur baru

1. header sapaan dan tombol pengaturan;
2. hero card cashflow bulan ini;
3. quick actions;
4. mini chart pemasukan vs pengeluaran;
5. insight sederhana;
6. transaksi terbaru;
7. tombol “Lihat semua”.

### Hero card

Menampilkan:

- sisa cashflow;
- pemasukan;
- pengeluaran;
- perubahan dibanding bulan sebelumnya jika datanya tersedia;
- filter bulan.

Contoh:

```text
Cashflow bulan ini
Rp 750.000

Pemasukan        Pengeluaran
Rp 1.000.000     Rp 250.000
```

### Quick actions

- Tambah pengeluaran;
- Tambah pemasukan;
- Catat dengan suara.

Gunakan ikon, label singkat, dan satu gaya visual yang konsisten.

### Transaksi terbaru

Setiap item menampilkan:

- ikon kategori dalam avatar berwarna lembut;
- judul;
- kategori dan tanggal;
- nominal dengan tanda `+` atau `−`;
- semantic warna yang konsisten;
- divider halus;
- aksi tap untuk membuka detail.

Daftar dapat dikelompokkan berdasarkan “Hari ini”, “Kemarin”, atau tanggal.

### Acceptance criteria

- pengguna dapat memahami kondisi cashflow dalam waktu kurang dari lima detik;
- aksi tambah transaksi dapat dijangkau tanpa scroll panjang;
- tidak ada status spreadsheet besar;
- tidak ada teks teknis yang tidak penting;
- daftar transaksi tidak terlihat seperti komponen bawaan yang belum didesain.

---

## 4.4 Keuangan

### Masalah saat ini

- komponen masih terlalu dasar;
- tombol manual dan suara belum memiliki hierarki yang baik;
- kartu status sinkronisasi mengganggu fokus;
- pengelolaan kategori belum ditempatkan dengan efisien;
- daftar transaksi belum kaya secara visual;
- voice input masih meminta pengguna menghentikan rekaman secara manual.

### Struktur baru

1. title `Keuangan`;
2. tombol kategori di kanan atas;
3. ringkasan bulan aktif;
4. filter periode, tipe, dan kategori;
5. daftar transaksi berdasarkan tanggal;
6. floating action button atau primary action;
7. bottom sheet pilihan metode pencatatan.

### Tombol kategori

Gunakan icon button atau tombol teks kecil di bagian kanan atas:

```text
[ikon tag] Kategori
```

Jangan menjadikannya kartu besar.

### Aksi tambah

Saat tombol tambah ditekan, tampilkan bottom sheet:

- Catat pengeluaran;
- Catat pemasukan;
- Catat dengan suara.

Alternatifnya, tampilkan dua quick action utama:

- `Tambah manual`;
- `Pakai suara`.

### Voice transaction

Flow baru:

1. pengguna menekan tombol suara;
2. aplikasi langsung mendengarkan;
3. transcript tampil secara bertahap;
4. tampil indikator suara;
5. jika pengguna diam sekitar 2–3 detik, listening berhenti otomatis;
6. hasil parsing diproses;
7. pengguna diarahkan ke halaman konfirmasi;
8. transaksi tidak boleh disimpan tanpa konfirmasi.

State yang harus didesain:

- permission belum diberikan;
- listening;
- speech detected;
- silence detected;
- processing;
- result ready;
- no speech detected;
- recognition error;
- microphone unavailable.

Tetap sediakan tombol berhenti kecil sebagai fallback, tetapi bukan aksi utama yang wajib.

### Acceptance criteria

- pengguna dapat menambah transaksi dengan maksimal tiga keputusan utama;
- status sinkronisasi tidak muncul sebagai kartu utama;
- filter tidak memenuhi layar;
- auto-stop tidak memotong ucapan normal;
- pengguna selalu melihat dan mengonfirmasi hasil parser sebelum data disimpan.

---

## 4.5 Pengaturan

### Masalah saat ini

- deskripsi “Kelola sinkronisasi, keamanan, ekspor data, dan informasi privasi MoneyPilot dari satu tempat” tidak diperlukan;
- isi halaman berpotensi terasa seperti kumpulan kartu teknis;
- fitur penting dan fitur lanjutan belum dikelompokkan dengan baik.

### Struktur baru

Gunakan kelompok pengaturan:

#### Akun dan keamanan

- nama panggilan;
- biometric;
- waktu penguncian ulang.

#### Data dan backup

- Google Spreadsheet;
- sinkronkan sekarang;
- ekspor CSV;
- impor/pemulihan jika memang didukung.

#### Tampilan

- mode terang/gelap/sistem;
- preferensi format atau tampilan jika tersedia.

#### Aplikasi

- status server market, berita, dan analisis;
- privasi;
- tentang MoneyPilot;
- versi aplikasi.

### Pola komponen

Gunakan `ListTile` khusus MoneyPilot:

- icon container;
- title;
- subtitle singkat hanya jika diperlukan;
- value atau status;
- chevron;
- divider halus.

### Acceptance criteria

- pengguna umum dapat memahami fungsi setiap menu tanpa istilah teknis;
- Spreadsheet tetap dijelaskan sebagai backup opsional;
- status backend tidak disalahartikan sebagai status data lokal;
- aksi berisiko seperti reset data diberi area khusus dan konfirmasi.

---

## 4.6 Berita

### Masalah saat ini

- tidak ada thumbnail;
- hierarki informasi lemah;
- card berita kurang mengundang untuk dibaca;
- metadata belum tersusun menarik;
- loading dan image fallback belum dirancang.

### Kebutuhan data

Audit backend harus memastikan apakah respons berita memiliki:

- `imageUrl` atau `thumbnailUrl`;
- source;
- publishedAt;
- title;
- summary/snippet;
- category;
- articleUrl;
- stable identifier.

Jika RSS tidak menyediakan thumbnail, backend perlu mencoba mengambil media RSS atau Open Graph secara aman, lalu menyediakan fallback.

### Struktur baru

#### Featured article

Artikel pertama atau berita prioritas:

- thumbnail besar rasio 16:9;
- kategori;
- headline maksimal tiga baris;
- source dan waktu;
- overlay gradient tipis jika teks berada di atas gambar.

#### Daftar berita

Setiap card:

- thumbnail rasio 4:3 di sisi kiri atau atas;
- headline maksimal tiga baris;
- source;
- waktu relatif;
- badge kategori;
- tap target seluruh card.

### Fallback image

Jika thumbnail tidak tersedia:

- gunakan ilustrasi brand MoneyPilot;
- jangan tampilkan kotak abu-abu kosong;
- fallback dapat dibedakan berdasarkan kategori berita.

### Acceptance criteria

- gambar memiliki loading placeholder;
- error gambar tidak merusak layout;
- headline tetap terbaca pada layar kecil;
- berita dapat dibuka dengan tap pada seluruh kartu;
- halaman memiliki pull-to-refresh dan skeleton loading.

---

## 4.7 Detail Berita dan Analisis AI

### Masalah saat ini

- komponen analisis belum memiliki hierarki kuat;
- informasi berpotensi terasa seperti output AI mentah;
- pengguna perlu membedakan fakta berita, interpretasi AI, skenario, dan disclaimer.

### Struktur detail berita

1. thumbnail;
2. headline;
3. source dan waktu;
4. ringkasan berita;
5. tombol buka sumber asli;
6. panel analisis MoneyPilot.

### Struktur analisis

#### Ringkasan eksekutif

Tiga sampai lima kalimat sederhana.

#### Tingkat dampak

Badge atau gauge yang tidak berlebihan:

- rendah;
- sedang;
- tinggi.

#### Aset atau sektor terkait

Chip atau card kecil dengan alasan singkat.

#### Skenario

- skenario positif;
- skenario negatif;
- hal yang perlu diamati.

#### Tingkat keyakinan

Tampilkan sebagai label yang dijelaskan, bukan angka presisi palsu.

#### Batasan

- data yang tidak tersedia;
- hal yang masih tidak pasti;
- disclaimer edukatif.

### Aturan konten

- jangan memakai bahasa pasti;
- jangan memberi instruksi beli atau jual;
- jangan menampilkan analisis AI sebagai fakta;
- tandai dengan jelas ketika data berasal dari fallback;
- tampilkan status cache/provider hanya pada detail teknis jika benar-benar diperlukan.

### Catatan

Kalimat terakhir pada audit awal berhenti pada “tidak perlu ada”. Bagian ini harus dilengkapi sebelum spesifikasi final implementasi analisis dibuat.

---

## 4.8 Portofolio

### Masalah saat ini

- ringkasan belum memiliki visual hierarchy;
- data belum menarik;
- belum ada chart perkembangan;
- input harga saham masih terlalu manual;
- validasi ticker dan integrasi market perlu diperkuat;
- pencatatan dividen belum memanfaatkan data kepemilikan.

### Struktur visual baru

1. total nilai portofolio;
2. unrealized gain/loss;
3. perubahan harian jika data tersedia;
4. chart nilai portofolio;
5. alokasi aset;
6. daftar holding;
7. transaksi terakhir;
8. dividen.

### Chart

Gunakan line chart untuk:

- nilai portofolio berdasarkan waktu;
- rentang 1M, 3M, 6M, 1Y, dan All jika datanya tersedia.

Gunakan donut chart hanya untuk alokasi per saham/sektor dan jangan menampilkan terlalu banyak label.

### Flow tambah saham

1. pengguna memasukkan kode saham;
2. aplikasi melakukan debounce;
3. backend memvalidasi ticker;
4. aplikasi menampilkan nama emiten dan harga market;
5. pengguna memasukkan jumlah lot;
6. pengguna memasukkan tanggal transaksi;
7. sistem menghitung jumlah lembar dan estimasi nilai;
8. pengguna mengonfirmasi.

### Keputusan produk penting

Harga market saat ini tidak cukup untuk menghitung keuntungan portofolio secara akurat. Sistem tetap membutuhkan cost basis, yaitu harga pada saat transaksi.

Pilihan yang aman:

- backend mengambil harga sesuai waktu transaksi jika data historis tersedia;
- pengguna mengonfirmasi harga yang ditemukan;
- jika data historis tidak tersedia, pengguna dapat memasukkan harga beli manual sebagai fallback;
- harga saat ini digunakan untuk valuasi berjalan, bukan menggantikan harga beli.

Jangan menghapus data harga transaksi lama hanya karena harga realtime tersedia.

### Dividen

Fase lanjutan:

- sistem mengambil corporate action/dividend per share dari sumber market;
- sistem mencocokkan jumlah saham pada cum date atau tanggal acuan;
- sistem menghitung estimasi bruto, pajak, dan neto;
- pengguna tetap mengonfirmasi dividen aktual yang diterima.

Jangan mengotomatisasi dividen tanpa sumber data dan aturan tanggal kepemilikan yang jelas.

### Acceptance criteria

- ticker invalid tidak dapat disimpan;
- kegagalan backend tidak menghapus data lokal;
- harga market menampilkan timestamp;
- nilai portofolio membedakan cost basis dan current value;
- chart memiliki empty state jika riwayat belum cukup;
- perhitungan tidak memberikan kesan realtime jika datanya tertunda.

---

# 5. Navigation dan Information Architecture

Navigasi bawah yang disarankan:

- Beranda;
- Keuangan;
- Portofolio;
- Berita;
- Pengaturan.

Fitur suara bukan tab terpisah. Voice input menjadi aksi dari Keuangan.

Fitur analisis menjadi bagian dari detail berita, bukan halaman yang berdiri tanpa konteks.

---

# 6. Library yang Dipilih

## Fondasi

- Material 3 bawaan Flutter;
- theme internal MoneyPilot;
- Lucide Icons tetap digunakan;
- Plus Jakarta Sans melalui `google_fonts` pada tahap awal, lalu dapat dibundel sebagai asset untuk release.

## Tambahan utama

- `fl_chart` untuk grafik cashflow dan portofolio;
- `cached_network_image` untuk thumbnail berita dan caching gambar;
- `skeletonizer` untuk loading state;
- `flutter_animate` hanya untuk microinteraction ringan jika animasi bawaan tidak cukup.

## Tidak direkomendasikan saat ini

- full UI kit yang menggantikan seluruh Material;
- beberapa library icon sekaligus;
- package terpisah untuk card, button, spacing, atau bottom navigation;
- library chart berbasis WebView;
- animasi berat pada setiap halaman.

Versi package tidak dikunci sebelum audit `pubspec.yaml` dan kompatibilitas Flutter SDK selesai.

---

# 7. Accessibility dan Responsiveness

Wajib diuji pada:

- HP kecil;
- HP besar;
- text scale besar;
- keyboard terbuka;
- mode offline;
- data kosong;
- data sangat panjang.

Aturan:

- tap target minimal nyaman;
- jangan membedakan pemasukan dan pengeluaran hanya dengan warna;
- gunakan tanda `+`/`−`, ikon, dan label;
- seluruh gambar memiliki semantic label yang sesuai;
- jangan memakai teks abu-abu terlalu tipis;
- nominal tidak boleh terpotong;
- tombol bawah harus aman dari navigation bar perangkat.

---

# 8. Motion dan Feedback

Durasi standar:

- microinteraction: 150–200 ms;
- page/content transition: 220–300 ms;
- success feedback: singkat dan tidak menghalangi.

Gunakan:

- fade/slide ringan;
- AnimatedSwitcher untuk nilai;
- skeleton untuk loading;
- haptic ringan saat menyimpan transaksi;
- haptic sukses setelah transaksi tersimpan;
- jangan memakai bounce berlebihan.

---

# 9. Prioritas Implementasi

## Fase 0 — Source Audit

- inventaris route;
- inventaris screen;
- inventaris shared widget;
- inventaris theme;
- inventaris dependency;
- audit respons API;
- audit state dan repository.

## Fase 1 — Design Foundation

- theme;
- token;
- typography;
- card;
- button;
- input;
- section header;
- loading/empty/error state.

## Fase 2 — Core Finance

- Beranda;
- Keuangan;
- tambah transaksi;
- voice transaction;
- confirmation.

## Fase 3 — News Experience

- thumbnail;
- news card;
- featured news;
- detail berita;
- skeleton dan fallback image.

## Fase 4 — Portfolio Experience

- summary;
- chart;
- holdings;
- ticker validation;
- market quote;
- cost basis.

## Fase 5 — Settings dan Security

- biometric entry;
- settings grouping;
- backup;
- server status;
- privacy.

## Fase 6 — Polish

- animation;
- haptic;
- accessibility;
- dark mode;
- testing pada beberapa perangkat.

---

# 10. Definition of Done

Satu tahap UI/UX dianggap selesai jika:

- tidak mengubah logic bisnis tanpa spesifikasi;
- tidak merusak data lokal;
- tidak merusak sinkronisasi;
- tidak menyimpan data pribadi di backend;
- memiliki loading, empty, error, dan retry state;
- lulus `dart format`;
- lulus `flutter analyze`;
- lulus test yang relevan;
- diuji pada HP Android nyata;
- screenshot sebelum dan sesudah tersedia;
- tidak ada overflow pada ukuran layar target;
- komponen baru reusable dan terdokumentasi.
