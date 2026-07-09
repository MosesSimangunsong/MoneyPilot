# PRD MoneyPilot

## 1. Identitas Produk

**Nama aplikasi:** MoneyPilot  
**Platform utama:** Mobile App berbasis Flutter  
**Bahasa aplikasi:** Bahasa Indonesia penuh  
**Target penggunaan:** Aplikasi personal untuk satu pengguna  
**Orientasi produk:** Personal finance intelligence, yaitu aplikasi yang membantu pengguna mencatat keuangan, memantau portofolio saham, membaca berita keuangan, dan memahami dampak berita terhadap kondisi pasar secara edukatif.

---

## 2. Visi Produk

MoneyPilot adalah aplikasi mobile personal yang membantu pengguna mengelola keuangan pribadi, mencatat transaksi harian dengan cepat melalui input manual atau suara, menyinkronkan data dengan Google Spreadsheet, memantau portofolio saham, serta memahami berita ekonomi dan dampaknya terhadap pasar keuangan dengan bahasa yang sederhana seperti mentor pemula.

Aplikasi ini tidak dirancang sebagai aplikasi trading, aplikasi rekomendasi beli/jual saham, atau pengganti penasihat keuangan. MoneyPilot berfungsi sebagai alat bantu pencatatan, pembelajaran, pemantauan, dan analisis berbasis data.

---

## 3. Tujuan Produk

Tujuan utama MoneyPilot:

1. Membantu pengguna mencatat pemasukan dan pengeluaran secara cepat setelah transaksi terjadi.
2. Membantu pengguna melihat kondisi keuangan pribadi melalui ringkasan, kategori, dan laporan sederhana.
3. Memungkinkan pencatatan transaksi dengan suara berbahasa Indonesia, tetapi tetap melalui halaman konfirmasi sebelum disimpan.
4. Menyimpan data secara offline-first di perangkat menggunakan Isar.
5. Menyinkronkan data ke Google Spreadsheet secara dua arah agar pengguna dapat melakukan backup dan edit ringan dari spreadsheet.
6. Membantu pengguna mencatat transaksi saham beli/jual secara manual.
7. Menghitung portofolio saham, termasuk modal, average price, realized profit/loss, unrealized profit/loss, alokasi, dan dividen.
8. Mengambil harga pasar saham melalui backend agar portofolio dapat diperbarui dari data pasar.
9. Menampilkan berita ekonomi dan keuangan yang relevan untuk Indonesia dan global.
10. Memberikan analisis dampak berita berbasis AI backend, data pasar, confidence score, dan disclaimer edukatif.
11. Menyiapkan fondasi fitur analisis saham dan forex di masa depan tanpa membangun fitur tersebut secara penuh pada MVP.

---

## 4. Target Pengguna

### 4.1 Pengguna Utama

Pengguna utama adalah pemilik aplikasi sendiri, yaitu pengguna personal yang:

- ingin mencatat keuangan harian secara disiplin,
- ingin memantau pemasukan dan pengeluaran,
- ingin mencatat portofolio saham secara manual,
- ingin memahami berita ekonomi dan dampaknya terhadap aset keuangan,
- masih ingin penjelasan dengan bahasa yang sederhana dan tidak terlalu teknis.

### 4.2 Karakteristik Pengguna

- Mahasiswa atau individu muda yang mulai belajar keuangan dan investasi.
- Menggunakan Bahasa Indonesia sebagai bahasa utama.
- Membutuhkan aplikasi yang sederhana, cepat, dan tidak terasa seperti aplikasi trading profesional.
- Ingin fitur analisis yang membantu belajar, bukan memberi sinyal beli/jual.
- Menginginkan tampilan minimalis putih, hitam, dan biru seperti aplikasi bank modern.

---

## 5. Prinsip Produk

1. **Personal-first**  
   Aplikasi dibuat untuk kebutuhan pribadi, bukan untuk publik atau multi-user.

2. **Offline-first**  
   Data utama disimpan di local database Isar agar aplikasi tetap bisa digunakan tanpa internet.

3. **Konfirmasi sebelum simpan**  
   Transaksi dari voice input tidak boleh langsung disimpan. Pengguna harus melihat hasil parsing dan menekan tombol simpan.

4. **Data dapat disinkronkan dua arah**  
   Data lokal dan Google Spreadsheet harus dapat saling memperbarui berdasarkan UUID dan `updatedAt`.

5. **Aman untuk data personal**  
   Aplikasi wajib mendukung fingerprint/biometric lock sejak MVP.

6. **Evidence-based analysis**  
   Analisis berita tidak boleh hanya berdasarkan asumsi. Analisis harus menyebutkan data pendukung, skenario, confidence score, dan disclaimer.

7. **Tidak memberi rekomendasi trading**  
   Aplikasi tidak boleh memberi perintah beli, jual, hold, entry, take profit, atau stop loss.

8. **Bahasa mentor pemula**  
   Semua penjelasan, error message, dan analisis harus memakai Bahasa Indonesia yang sederhana, tenang, dan mudah dipahami.

9. **Minimalis dan tidak berlebihan**  
   Tampilan aplikasi harus bersih, minim card, minim distraksi, dan tidak terasa seperti dashboard trading yang menegangkan.

---

## 6. Ruang Lingkup MVP

MVP MoneyPilot langsung mencakup fitur utama sampai tahap awal yang lengkap:

1. Autentikasi lokal menggunakan fingerprint/biometric.
2. Beranda dengan ringkasan keuangan, portofolio, berita penting, dan status sinkronisasi.
3. Pencatatan keuangan manual.
4. Pencatatan keuangan dengan voice input Bahasa Indonesia.
5. Halaman konfirmasi voice transaction.
6. Kategori pemasukan dan pengeluaran.
7. Laporan keuangan dasar.
8. Sinkronisasi dua arah Isar dan Google Spreadsheet.
9. Pencatatan transaksi saham beli/jual secara manual.
10. Pencatatan dividen.
11. Perhitungan portofolio saham.
12. Pengambilan harga saham melalui backend.
13. Berita keuangan dari backend.
14. Detail berita.
15. Analisis dampak berita dengan AI backend.
16. Confidence score, impact score, evidence, skenario, dan disclaimer.
17. Bookmark berita.
18. Tab Analisis sebagai fondasi fitur analisis saham/forex masa depan.
19. Pengaturan dasar aplikasi.
20. Export/backup dasar melalui spreadsheet.

---

## 7. Fitur MVP

### 7.1 Keamanan Aplikasi

#### Deskripsi
Aplikasi harus meminta autentikasi fingerprint/biometric saat dibuka. Autentikasi menggunakan sistem biometric yang sudah terhubung di HP pengguna.

#### Functional Requirements

- Aplikasi mengecek apakah perangkat mendukung biometric.
- Jika biometric tersedia, aplikasi meminta autentikasi saat aplikasi dibuka.
- Jika autentikasi berhasil, pengguna masuk ke Beranda.
- Jika autentikasi gagal, aplikasi menampilkan pesan gagal dan opsi coba lagi.
- Jika perangkat tidak mendukung biometric, aplikasi menampilkan fallback berupa pesan bahwa keamanan biometric tidak tersedia.
- Untuk MVP, PIN internal aplikasi bersifat opsional. Fallback utama boleh mengikuti mekanisme perangkat melalui package `local_auth`.

#### Acceptance Criteria

- Given pengguna membuka aplikasi, when biometric tersedia, then aplikasi menampilkan prompt fingerprint.
- Given pengguna berhasil melakukan fingerprint, when autentikasi selesai, then pengguna masuk ke Beranda.
- Given fingerprint gagal, when pengguna membatalkan autentikasi, then aplikasi tetap terkunci.
- Given perangkat tidak mendukung biometric, when aplikasi dibuka, then aplikasi menampilkan pesan fallback yang jelas.

---

### 7.2 Beranda

#### Deskripsi
Beranda adalah halaman ringkasan utama. Halaman ini harus bersih, minimalis, dan tidak terlalu penuh dengan card. Beranda menampilkan informasi paling penting dari keuangan pribadi, portofolio, berita, dan sinkronisasi.

#### Informasi yang Ditampilkan

- Total pemasukan bulan ini.
- Total pengeluaran bulan ini.
- Selisih cashflow bulan ini.
- Pengeluaran terbesar bulan ini.
- Total nilai portofolio.
- Floating profit/loss portofolio.
- Tiga berita penting terbaru.
- Status sinkronisasi terakhir.
- Tombol cepat tambah transaksi.
- Tombol cepat voice input.

#### Acceptance Criteria

- Given pengguna membuka Beranda, when data transaksi tersedia, then ringkasan pemasukan, pengeluaran, dan cashflow tampil.
- Given belum ada transaksi, when Beranda dibuka, then tampil empty state yang ramah.
- Given ada transaksi belum tersinkron, when Beranda dibuka, then status sinkronisasi menunjukkan jumlah item pending.
- Given ada data portofolio, when Beranda dibuka, then total nilai portofolio dan P/L tampil.
- Given backend berita tersedia, when Beranda dibuka, then tiga berita penting terbaru tampil.

---

### 7.3 Pencatatan Transaksi Manual

#### Deskripsi
Pengguna dapat mencatat pemasukan dan pengeluaran secara manual.

#### Field Transaksi

- Tipe transaksi: pemasukan / pengeluaran.
- Tanggal transaksi.
- Nominal.
- Kategori.
- Judul transaksi.
- Catatan opsional.
- Sumber transaksi: manual.
- Status sinkronisasi.

#### Kategori Awal

Kategori pengeluaran:

- Makanan & Minuman
- Transportasi
- Kos/Asrama
- Kuliah
- Hiburan
- Investasi
- Tabungan
- Kesehatan
- Belanja
- Lainnya

Kategori pemasukan:

- Freelance
- Uang Orang Tua
- Beasiswa
- Gaji
- Dividen
- Hadiah
- Lainnya

#### Acceptance Criteria

- Given pengguna membuka form tambah transaksi, when pengguna mengisi semua field wajib, then transaksi dapat disimpan.
- Given nominal kosong, when pengguna menekan simpan, then sistem menampilkan validasi nominal wajib diisi.
- Given kategori kosong, when pengguna menekan simpan, then sistem menampilkan validasi kategori wajib diisi.
- Given transaksi berhasil disimpan, when kembali ke daftar transaksi, then transaksi baru tampil.
- Given transaksi disimpan, then `isSynced` bernilai false sampai proses sync berhasil.

---

### 7.4 Voice Input Transaksi

#### Deskripsi
Pengguna dapat mencatat transaksi menggunakan suara Bahasa Indonesia. Sistem mengubah suara menjadi teks, mem-parsing teks menjadi transaksi, lalu menampilkan halaman konfirmasi.

#### Contoh Input

- “Saya beli kopi 15 ribu.”
- “Saya beli nasi goreng dua puluh lima ribu.”
- “Saya bayar kos satu juta.”
- “Saya dapat uang dari orang tua lima ratus ribu.”
- “Saya mendapat uang freelance 300 ribu.”
- “Saya keluar uang 20 ribu untuk transportasi.”

#### Alur

1. Pengguna menekan tombol mic.
2. Aplikasi meminta izin microphone jika belum diberikan.
3. Aplikasi merekam suara pendek.
4. Speech-to-text menghasilkan transcript.
5. Parser lokal membaca transcript.
6. Parser mendeteksi tipe transaksi, nominal, kategori, judul, dan catatan.
7. Aplikasi menampilkan halaman konfirmasi.
8. Pengguna dapat menyimpan atau mengedit hasil.
9. Setelah disimpan, transaksi masuk ke Isar dan sync queue.

#### Acceptance Criteria

- Given microphone permission sudah diberikan, when pengguna menekan tombol mic, then aplikasi mulai mendengar suara.
- Given pengguna berkata “Saya beli kopi 15 ribu”, when parsing berhasil, then sistem mendeteksi pengeluaran, nominal 15000, kategori Makanan & Minuman, judul Kopi.
- Given parser gagal mendeteksi nominal, when transcript tersedia, then aplikasi membuka form manual dengan transcript masuk ke catatan.
- Given parser confidence rendah, when hasil parsing selesai, then aplikasi tetap menampilkan halaman konfirmasi dengan peringatan “Periksa kembali hasil deteksi”.
- Given pengguna menyetujui hasil konfirmasi, when tombol simpan ditekan, then transaksi tersimpan ke Isar.
- Given pengguna memilih edit, when halaman form terbuka, then field yang sudah terdeteksi terisi otomatis.

---

### 7.5 Halaman Konfirmasi Voice Transaction

#### Deskripsi
Halaman ini wajib muncul setelah voice input berhasil diproses. Tidak ada transaksi suara yang langsung disimpan tanpa konfirmasi.

#### Informasi yang Ditampilkan

- Transcript suara asli.
- Tipe transaksi.
- Nominal.
- Kategori.
- Judul transaksi.
- Catatan.
- Tanggal.
- Confidence score parser.
- Tombol Simpan.
- Tombol Edit.
- Tombol Ulangi Rekaman.

#### Acceptance Criteria

- Given voice parser berhasil, when halaman konfirmasi terbuka, then semua field hasil parsing tampil.
- Given nominal salah, when pengguna menekan Edit, then pengguna dapat mengubah nominal.
- Given pengguna menekan Ulangi Rekaman, then aplikasi kembali ke mode voice input.
- Given pengguna menekan Simpan, then transaksi tersimpan dan masuk sync queue.

---

### 7.6 Sinkronisasi Google Spreadsheet Dua Arah

#### Deskripsi
Aplikasi harus mendukung sinkronisasi dua arah antara local database Isar dan Google Spreadsheet sejak MVP.

#### Prinsip Sinkronisasi

- Local database Isar tetap menjadi sumber utama penggunaan aplikasi.
- Google Spreadsheet menjadi backup dan tempat edit ringan.
- Setiap data memiliki UUID.
- Sync menggunakan strategi two-way sync.
- Konflik diselesaikan dengan prinsip `latest updatedAt wins`.
- Delete menggunakan soft delete.
- Google Apps Script wajib melakukan upsert berdasarkan UUID.

#### Data yang Disinkronkan

- MoneyTransaction
- Category
- StockTransaction
- Dividend
- WatchlistItem
- SyncLog

#### Aturan Upsert

- Jika UUID belum ada di spreadsheet, tambahkan row baru.
- Jika UUID sudah ada di spreadsheet, update row tersebut.
- Jika row spreadsheet memiliki `updatedAt` lebih baru dari data lokal, update data lokal.
- Jika data lokal memiliki `updatedAt` lebih baru dari spreadsheet, update spreadsheet.
- Jika `isDeleted = true`, data tidak ditampilkan di aplikasi, tetapi status delete tetap disinkronkan.

#### Acceptance Criteria

- Given transaksi baru dibuat di aplikasi, when sync berjalan, then transaksi muncul di spreadsheet.
- Given transaksi diedit di aplikasi, when sync berjalan, then row spreadsheet dengan UUID sama diperbarui.
- Given transaksi diedit di spreadsheet dengan `updatedAt` lebih baru, when sync dua arah berjalan, then data lokal diperbarui.
- Given UUID sudah ada di spreadsheet, when sync berjalan, then sistem tidak membuat row duplikat.
- Given internet mati, when transaksi disimpan, then transaksi tetap tersimpan lokal dan masuk sync queue.
- Given internet kembali tersedia, when sync berjalan, then data pending terkirim.
- Given konflik data terjadi, when salah satu data memiliki `updatedAt` lebih baru, then data terbaru yang dipakai.

---

### 7.7 Laporan Keuangan Dasar

#### Deskripsi
Aplikasi menampilkan laporan keuangan sederhana untuk membantu pengguna memahami arus kas.

#### Fitur

- Total pemasukan per bulan.
- Total pengeluaran per bulan.
- Cashflow bersih.
- Pengeluaran per kategori.
- Transaksi terbaru.
- Pengeluaran terbesar.
- Filter tanggal dan kategori.

#### Acceptance Criteria

- Given pengguna membuka halaman Keuangan, when ada data transaksi, then daftar transaksi tampil berdasarkan tanggal terbaru.
- Given pengguna memilih bulan tertentu, when filter diterapkan, then ringkasan bulan tersebut tampil.
- Given transaksi dibagi beberapa kategori, when laporan kategori dibuka, then total per kategori tampil.
- Given tidak ada transaksi, then aplikasi menampilkan empty state yang ramah.

---

### 7.8 Portofolio Saham Manual

#### Deskripsi
Pengguna dapat mencatat transaksi saham beli dan jual secara manual. Aplikasi menghitung posisi portofolio berdasarkan riwayat transaksi.

#### Metode Akuntansi

MVP menggunakan metode **Weighted Average Cost / Moving Average Cost**.

#### Field Transaksi Saham

- Symbol saham, contoh `BBCA.JK`.
- Nama emiten opsional.
- Tipe transaksi: beli / jual.
- Tanggal transaksi.
- Jumlah lot.
- Harga per saham.
- Fee.
- Catatan.
- Sumber: manual.
- Status sinkronisasi.

#### Perhitungan

- Total lot aktif.
- Total saham aktif = lot x 100.
- Average price.
- Total modal.
- Market value.
- Realized profit/loss.
- Unrealized profit/loss.
- Return percentage.
- Total dividen.
- Total return including dividend.
- Alokasi per saham.

#### Acceptance Criteria

- Given pengguna mencatat pembelian saham, when data disimpan, then transaksi masuk ke riwayat saham.
- Given pengguna membeli saham yang sama beberapa kali, when portofolio dihitung, then average price dihitung menggunakan metode moving average.
- Given pengguna menjual sebagian saham, when transaksi jual disimpan, then realized P/L dihitung dan sisa average price tetap konsisten.
- Given posisi saham menjadi nol, when pengguna membeli lagi kemudian, then average price dimulai ulang dari posisi baru.
- Given harga pasar berhasil diambil dari backend, when halaman Portofolio dibuka, then market value dan unrealized P/L diperbarui.
- Given backend gagal mengambil harga, when halaman Portofolio dibuka, then aplikasi menampilkan harga terakhir atau meminta input manual sementara.

---

### 7.9 Dividen

#### Deskripsi
Pengguna dapat mencatat dividen saham sejak MVP. Dividen memengaruhi total return, tetapi tidak mengubah average price.

#### Field Dividen

- Symbol saham.
- Tanggal dividen.
- Jumlah dividen per saham.
- Total saham yang menerima dividen.
- Total dividen.
- Pajak opsional.
- Catatan.
- Status sinkronisasi.

#### Acceptance Criteria

- Given pengguna mencatat dividen BBCA, when data disimpan, then dividen tampil pada riwayat portofolio.
- Given dividen tercatat, when total return dihitung, then dividen ikut menambah total return.
- Given dividen tercatat, then average price saham tidak berubah.
- Given sync berjalan, then dividen tersinkron ke spreadsheet.

---

### 7.10 Harga Pasar Saham via Backend

#### Deskripsi
Aplikasi mencoba mengambil harga pasar saham dari backend sejak MVP. Flutter tidak boleh menyimpan API key market data secara langsung.

#### Endpoint Minimum

- `GET /market/stock/:symbol`
- `POST /portfolio/price-update`

#### Acceptance Criteria

- Given pengguna membuka Portofolio, when internet tersedia, then aplikasi meminta update harga ke backend.
- Given backend mengembalikan harga saham, then current price portofolio diperbarui.
- Given backend gagal, then aplikasi menampilkan pesan “Harga pasar belum tersedia. Menggunakan harga terakhir.”
- Given API key dibutuhkan, then API key hanya berada di backend, bukan di Flutter.

---

### 7.11 Berita Keuangan

#### Deskripsi
Aplikasi menampilkan berita ekonomi dan keuangan yang relevan untuk pasar Indonesia dan global.

#### Kategori Berita

- Ekonomi Indonesia
- Ekonomi Global
- Suku Bunga
- Inflasi
- Geopolitik
- Komoditas
- Forex
- Saham Indonesia
- Saham Global
- IPO

#### Acceptance Criteria

- Given pengguna membuka tab Berita, when backend tersedia, then daftar berita terbaru tampil.
- Given pengguna memilih kategori, when filter diterapkan, then berita sesuai kategori tampil.
- Given pengguna membuka detail berita, then judul, sumber, tanggal, ringkasan, dan link sumber tampil.
- Given pengguna menekan bookmark, then berita tersimpan lokal.
- Given backend gagal, then aplikasi menampilkan error state yang jelas.

---

### 7.12 Analisis Dampak Berita dengan AI Backend

#### Deskripsi
Aplikasi harus menyediakan analisis dampak berita menggunakan AI backend sejak MVP. Analisis harus berbasis data, tidak spekulatif, dan tidak memberi rekomendasi beli/jual.

#### Alur

1. Pengguna membuka detail berita.
2. Pengguna menekan tombol “Analisis Dampak”.
3. Flutter mengirim request ke backend Flask.
4. Backend mengambil berita, data pasar, dan evidence terkait.
5. Backend memanggil AI dengan prompt ketat.
6. AI mengembalikan JSON valid.
7. Flutter menampilkan hasil analisis dalam Bahasa Indonesia.

#### Komponen Hasil Analisis

- Judul berita.
- Ringkasan.
- Kategori.
- Aset yang terdampak.
- Dampak potensial.
- Rantai sebab-akibat.
- Data pendukung.
- Skenario positif.
- Skenario negatif.
- Impact score.
- Confidence score.
- Hal yang perlu dipantau.
- Kesimpulan untuk pemula.
- Disclaimer.

#### Aturan Analisis

- Tidak boleh menggunakan kata “pasti”.
- Tidak boleh memberi rekomendasi beli, jual, hold, entry, take profit, atau stop loss.
- Harus menyebutkan jika data belum cukup.
- Harus menurunkan confidence score jika data pasar bertentangan dengan narasi berita.
- Harus menggunakan bahasa yang tenang dan mudah dipahami.

#### Acceptance Criteria

- Given pengguna menekan Analisis Dampak, when backend berhasil memproses, then hasil analisis tampil.
- Given data pasar tidak lengkap, then confidence score turun dan aplikasi menjelaskan bahwa data belum cukup.
- Given AI response tidak valid JSON, then backend mengembalikan error yang aman dan Flutter menampilkan pesan gagal.
- Given hasil analisis tampil, then disclaimer edukatif selalu terlihat.
- Given analisis sudah pernah dibuat, when pengguna membuka lagi, then backend boleh mengembalikan hasil cache.

---

### 7.13 Bookmark Berita

#### Deskripsi
Pengguna dapat menyimpan berita penting untuk dibaca ulang.

#### Acceptance Criteria

- Given pengguna membuka detail berita, when tombol bookmark ditekan, then berita tersimpan lokal.
- Given berita sudah dibookmark, when tombol bookmark ditekan lagi, then bookmark dihapus.
- Given pengguna membuka daftar bookmark, then semua berita tersimpan tampil.

---

### 7.14 Tab Analisis

#### Deskripsi
Tab Analisis adalah fondasi untuk fitur analisis saham dan forex di masa depan. Pada MVP, tab ini belum melakukan analisis saham/forex penuh.

#### Isi MVP

- Penjelasan bahwa fitur analisis mendalam sedang disiapkan.
- Watchlist sederhana.
- Catatan analisis manual opsional.
- Disclaimer bahwa fitur bukan rekomendasi trading.

#### Acceptance Criteria

- Given pengguna membuka tab Analisis, then aplikasi menampilkan halaman placeholder yang rapi dan informatif.
- Given pengguna menambahkan item watchlist, then item tersimpan lokal dan ikut sync.
- Given fitur analisis penuh belum tersedia, then aplikasi tidak menampilkan sinyal beli/jual.

---

### 7.15 Pengaturan

#### Deskripsi
Pengaturan berisi konfigurasi dasar aplikasi.

#### Fitur Pengaturan MVP

- Nama pengguna/panggilan.
- URL Google Apps Script Web App.
- Secret token spreadsheet sync.
- Pengaturan biometric lock.
- Pengaturan kategori.
- Fee default transaksi saham.
- Status sync terakhir.
- Export data.
- Reset data lokal.
- Disclaimer.

#### Acceptance Criteria

- Given pengguna membuka Pengaturan, then semua konfigurasi utama tampil.
- Given pengguna mengubah URL GAS, when disimpan, then URL baru dipakai untuk sync berikutnya.
- Given pengguna mengubah fee default, then transaksi saham baru memakai fee default tersebut.
- Given pengguna memilih reset data, then aplikasi meminta konfirmasi sebelum menghapus data lokal.

---

## 8. Fitur Post-MVP

Fitur berikut disiapkan setelah MVP stabil:

1. Analisis saham fundamental penuh.
2. Analisis forex penuh.
3. Analisis teknikal lanjutan.
4. Sinkronisasi multi-device.
5. Login cloud berbasis akun.
6. Import CSV portofolio otomatis.
7. Integrasi broker resmi jika tersedia API legal.
8. Integrasi perbankan/open banking.
9. Budgeting lanjutan per kategori.
10. Reminder transaksi rutin.
11. OCR struk belanja.
12. AI parser voice generatif.
13. Corporate action otomatis: stock split, reverse split, rights issue, bonus shares.
14. Dashboard pajak investasi.
15. Multi-currency wallet.
16. Notifikasi berita high impact.
17. Alert harga saham.
18. Export laporan PDF.

---

## 9. Out-of-Scope MVP

Hal berikut tidak boleh dibuat pada MVP:

1. Rekomendasi beli/jual saham.
2. Eksekusi trading otomatis.
3. Koneksi langsung ke akun Ajaib atau sekuritas lain tanpa API resmi.
4. Scraping aplikasi broker.
5. Menyimpan password broker.
6. Social sharing portofolio.
7. Multi-user system.
8. Server-based authentication penuh.
9. Real-time market data tick-by-tick.
10. Crypto trading.
11. Forex trading execution.
12. Pinjaman, kredit, atau fitur finansial regulated lain.
13. Fitur publikasi analisis untuk orang lain.
14. Rekomendasi investasi yang bersifat personal advisory.

---

## 10. Non-Functional Requirements

### 10.1 Performa

- Aplikasi harus tetap responsif pada perangkat Android umum.
- Operasi local database harus terasa instan untuk penggunaan personal.
- List transaksi harus tetap lancar untuk ribuan transaksi.
- Chart harus ringan dan tidak menghambat navigasi.
- Backend response ideal di bawah 2 detik untuk data cache.
- Analisis AI boleh lebih lama, tetapi harus menampilkan loading state.

### 10.2 Offline Support

- Pengguna tetap bisa menambah transaksi manual saat offline.
- Pengguna tetap bisa menambah transaksi voice selama speech-to-text perangkat tersedia.
- Data tersimpan di Isar saat offline.
- Sync queue berjalan saat internet kembali.
- Fitur berita, harga pasar, dan analisis AI membutuhkan internet.

### 10.3 Keamanan

- Aplikasi mendukung fingerprint/biometric lock.
- API key eksternal tidak boleh disimpan di Flutter.
- API key market/news/AI hanya disimpan di backend Flask.
- Google Apps Script harus memakai secret token.
- Data lokal tidak boleh dikirim ke pihak ketiga kecuali endpoint yang dikonfigurasi pengguna.
- Aplikasi harus menyediakan disclaimer dan privacy note sederhana.

### 10.4 Keandalan Data

- Semua entity penting wajib memiliki UUID.
- Semua entity mutasional memiliki `createdAt`, `updatedAt`, `isDeleted`, dan status sync.
- Sync tidak boleh menghasilkan duplikasi row spreadsheet.
- Edit transaksi setelah sync harus memperbarui row yang sama berdasarkan UUID.
- Conflict resolution menggunakan `latest updatedAt wins`.

### 10.5 Bahasa dan UX

- Semua UI memakai Bahasa Indonesia.
- Microcopy harus sederhana, tenang, dan membantu.
- Hindari istilah teknis tanpa penjelasan.
- Hindari kata-kata yang membuat panik seperti “anjlok parah” kecuali dalam konteks berita yang dijelaskan netral.
- Analisis AI harus seperti mentor pemula.

---

## 11. Data Utama yang Dibutuhkan

### 11.1 Local Database Isar

Entity utama:

- AppSetting
- Category
- MoneyTransaction
- VoiceTranscript
- SyncLog
- StockTransaction
- Dividend
- WatchlistItem
- BookmarkedNews
- LocalNewsCache opsional

### 11.2 Google Spreadsheet

Sheet utama:

- Transactions
- Categories
- Stock_Transactions
- Dividends
- Watchlist
- Monthly_Summary
- Sync_Log

### 11.3 Backend Flask / SQLite Cache

Entity/cache utama:

- NewsArticle
- NewsImpactAnalysis
- MarketSnapshot
- ApiCallLog
- CacheStatus

---

## 12. Backend Requirements

Backend Flask dibutuhkan untuk:

1. Menyembunyikan API key dari aplikasi Flutter.
2. Mengambil berita dari sumber RSS/API.
3. Mengambil data pasar saham, forex, komoditas, dan indeks.
4. Menyediakan harga saham untuk portofolio.
5. Memproses analisis dampak berita dengan AI.
6. Menyimpan cache hasil berita, data pasar, dan analisis.
7. Mengembalikan JSON yang stabil untuk Flutter.

### Endpoint MVP

- `GET /health`
- `GET /news`
- `GET /news/:id`
- `POST /news/analyze`
- `GET /market/stock/:symbol`
- `GET /market/index/:symbol`
- `GET /market/forex/:pair`
- `GET /market/commodity/:symbol`
- `POST /portfolio/price-update`
- `GET /cache/status`

---

## 13. Google Apps Script Requirements

Google Apps Script digunakan sebagai jembatan antara Flutter dan Google Spreadsheet.

### Requirements

- Endpoint menerima POST JSON dari Flutter.
- Endpoint memvalidasi secret token.
- Endpoint mendukung pull data dari spreadsheet untuk sync dua arah.
- Endpoint mendukung upsert berdasarkan UUID.
- Endpoint tidak boleh hanya append tanpa cek UUID.
- Endpoint mengembalikan response JSON standar.
- Endpoint mencatat log sync.

### Response Minimum

```json
{
  "status": "success",
  "inserted": 2,
  "updated": 1,
  "skipped": 0,
  "failed": 0,
  "errors": []
}
```

---

## 14. Edge Cases

### 14.1 Voice Input

- Transcript kosong.
- Nominal tidak terdeteksi.
- Nominal terdeteksi tetapi kategori tidak jelas.
- Tipe transaksi tidak terdeteksi.
- Speech-to-text salah membaca angka.
- Pengguna menyebut dua angka dalam satu kalimat.
- Pengguna batal setelah halaman konfirmasi.

### 14.2 Sync

- Internet mati saat sync.
- Spreadsheet URL salah.
- Secret token salah.
- UUID sudah ada di spreadsheet.
- Data lokal dan spreadsheet sama-sama berubah.
- Row spreadsheet dihapus manual oleh pengguna.
- Header spreadsheet berubah.
- Google Apps Script error.

### 14.3 Portofolio

- Jual saham lebih banyak dari kepemilikan.
- Harga saham gagal diambil.
- Symbol saham salah.
- Fee kosong.
- Dividen dicatat untuk saham yang tidak dimiliki.
- Posisi saham menjadi nol lalu beli lagi.
- Stock split belum otomatis didukung.

### 14.4 Berita dan Analisis

- Backend mati.
- API berita gagal.
- API market data gagal.
- AI response tidak valid JSON.
- Data pasar bertentangan dengan narasi berita.
- Confidence score rendah.
- Berita duplikat.
- Link sumber berita tidak dapat dibuka.

### 14.5 Keamanan

- Fingerprint gagal.
- Fingerprint tidak tersedia.
- Pengguna mengganti pengaturan biometric di perangkat.
- Aplikasi dibuka kembali dari background.

---

## 15. Definition of Done Umum

Sebuah fitur dianggap selesai jika:

1. Fitur berjalan sesuai acceptance criteria.
2. Kode berhasil build tanpa error.
3. Tidak ada perubahan yang merusak fitur sebelumnya.
4. Struktur folder mengikuti arsitektur yang disepakati.
5. Business logic tidak ditulis langsung di widget UI.
6. Data tersimpan di Isar jika fitur membutuhkan penyimpanan lokal.
7. Fitur memiliki loading, empty, dan error state jika relevan.
8. Fitur memiliki validasi input.
9. Fitur memakai Bahasa Indonesia penuh.
10. Fitur tetap konsisten dengan design system minimalis MoneyPilot.
11. Unit test dibuat untuk logic penting seperti parser, formatter, sync resolver, dan portfolio calculation.
12. Manual testing checklist dijalankan minimal untuk happy path dan edge case utama.

---

## 16. Success Metrics MVP

MVP dianggap berhasil jika:

1. Pengguna dapat membuka aplikasi dengan fingerprint.
2. Pengguna dapat mencatat transaksi manual.
3. Pengguna dapat mencatat transaksi dengan voice input dan konfirmasi.
4. Transaksi tersimpan lokal dan tetap tersedia saat offline.
5. Data dapat sync dua arah dengan Google Spreadsheet tanpa duplikasi UUID.
6. Pengguna dapat mencatat beli/jual saham.
7. Portofolio dapat menghitung average price, P/L, dan dividen.
8. Aplikasi dapat mencoba mengambil harga saham dari backend.
9. Pengguna dapat membaca berita keuangan.
10. Pengguna dapat meminta analisis dampak berita dari AI backend.
11. Analisis berita menampilkan confidence score, evidence, skenario, dan disclaimer.
12. UI terasa bersih, minimalis, dan tidak membingungkan.
13. Semua teks utama menggunakan Bahasa Indonesia.

---

## 17. Prioritas Fitur MoSCoW

### Must Have

- Fingerprint/biometric lock.
- Beranda.
- Pencatatan transaksi manual.
- Voice input transaksi.
- Konfirmasi voice transaction.
- Local database Isar.
- Sync dua arah Google Spreadsheet.
- Kategori transaksi.
- Laporan keuangan dasar.
- Pencatatan beli/jual saham.
- Pencatatan dividen.
- Perhitungan portofolio.
- Backend harga saham.
- Berita keuangan.
- Analisis dampak berita AI backend.
- Disclaimer.

### Should Have

- Bookmark berita.
- Watchlist.
- Export data.
- Retry sync dengan exponential backoff.
- Cache berita lokal.
- Cache market price backend.
- Pengaturan fee saham.

### Could Have

- Budget per kategori.
- Notifikasi berita penting.
- Grafik portofolio historis.
- Import CSV.
- Tema gelap.
- Reminder transaksi rutin.

### Won't Have for MVP

- Trading otomatis.
- Rekomendasi beli/jual.
- Integrasi broker langsung.
- Login cloud multi-user.
- Open banking.
- Analisis teknikal lanjutan.
- Corporate action otomatis penuh.

---

## 18. Risiko Produk dan Mitigasi

### Risiko 1: Scope MVP terlalu besar

**Mitigasi:** Implementasi harus modular. Codex tidak boleh diminta membangun semua fitur sekaligus.

### Risiko 2: Sync dua arah kompleks

**Mitigasi:** Gunakan UUID, `updatedAt`, soft delete, dan latest updatedAt wins. Mulai dari entity transaksi dahulu sebelum portfolio.

### Risiko 3: Voice parser tidak akurat

**Mitigasi:** Selalu tampilkan halaman konfirmasi. Jika confidence rendah, arahkan ke edit manual.

### Risiko 4: API market data terbatas

**Mitigasi:** Gunakan backend caching, fallback harga terakhir, dan opsi input harga manual sementara.

### Risiko 5: AI memberi kesimpulan berlebihan

**Mitigasi:** Prompt backend harus melarang rekomendasi beli/jual, wajib menyebut confidence score, dan wajib menurunkan confidence jika data tidak mendukung.

### Risiko 6: Tampilan terlalu ramai

**Mitigasi:** Design system harus minimalis, minim card, banyak whitespace, dan hanya menampilkan data penting.

---

## 19. Disclaimer Produk

MoneyPilot wajib menampilkan disclaimer berikut pada halaman Analisis dan detail analisis berita:

> MoneyPilot menyajikan informasi dan analisis sebagai alat bantu edukasi. Analisis yang ditampilkan bukan merupakan nasihat keuangan, rekomendasi beli, rekomendasi jual, atau ajakan melakukan transaksi. Keputusan keuangan dan investasi sepenuhnya menjadi tanggung jawab pengguna.

Versi pendek untuk komponen kecil:

> Ini bukan nasihat keuangan. Gunakan sebagai bahan belajar dan pertimbangan awal.

---

## 20. Catatan untuk Codex

Saat mengimplementasikan MoneyPilot, Codex harus mengikuti aturan berikut:

1. Jangan mengubah scope fitur di luar PRD ini.
2. Jangan menambahkan fitur baru tanpa instruksi eksplisit.
3. Jangan membuat rekomendasi trading.
4. Jangan menyimpan API key di Flutter.
5. Jangan membuat sync spreadsheet dengan append langsung tanpa UUID upsert.
6. Jangan menyimpan transaksi voice tanpa halaman konfirmasi.
7. Jangan menghapus kode lama yang sudah berfungsi.
8. Selalu jaga bahasa UI dalam Bahasa Indonesia.
9. Selalu jaga UI minimalis putih, hitam, dan biru.
10. Setiap tahap implementasi harus bisa dijalankan dan dites sebelum lanjut tahap berikutnya.
