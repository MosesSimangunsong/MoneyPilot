# Tahap 18 — Implementasi Voice-Based Transaction Recording

## 1. Tujuan Dokumen

Dokumen ini menjelaskan fitur **pencatatan transaksi keuangan melalui suara berbahasa Indonesia** yang harus diimplementasikan pada proyek **MoneyPilot Personal Finance Intelligence Application**.

Dokumen ini ditujukan untuk Codex agar:

- memahami konteks sistem MoneyPilot;
- tidak merusak flow transaksi manual yang sudah stabil;
- mengimplementasikan fitur suara secara bertahap dan dapat diuji;
- menghasilkan fitur yang benar-benar dapat didemonstrasikan;
- menutup gap klaim CV berikut:

> Built offline-first local data storage with Isar, supporting manual transaction input, Indonesian voice-based transaction recording, biometric protection, category management, soft delete, and monthly financial summaries.

Fitur ini harus benar-benar bekerja pada perangkat Android fisik, bukan hanya berupa tombol mikrofon, placeholder, atau mock UI.

---

# 2. Konteks Sistem MoneyPilot

MoneyPilot adalah aplikasi personal finance intelligence berbasis Flutter dengan prinsip **local-first**.

Arsitektur utama:

- **Flutter** sebagai aplikasi mobile.
- **Isar** sebagai database lokal utama.
- **Google Apps Script + Google Spreadsheet** sebagai backup dan two-way sync.
- **Flask backend** hanya untuk market data, berita, cache, dan AI news impact analysis.
- Backend Flask tidak boleh menyimpan data keuangan personal pengguna.

Data transaksi pribadi harus tetap disimpan melalui repository lokal dan Isar.

Fitur voice transaction tidak boleh bergantung pada backend Flask dan harus tetap dapat digunakan ketika backend mati.

---

# 3. Kondisi Saat Ini

Fitur transaksi manual sudah tersedia dan dianggap sebagai flow yang stabil.

Fitur yang sudah ada antara lain:

- tambah transaksi pemasukan;
- tambah transaksi pengeluaran;
- edit transaksi;
- soft delete transaksi;
- category management;
- monthly financial summary;
- sinkronisasi transaksi ke Google Spreadsheet;
- model `VoiceTranscript` di database lokal;
- biometric protection;
- local-first Isar repository.

Namun fitur input transaksi melalui mikrofon belum benar-benar selesai dan belum dapat digunakan secara end-to-end.

Gap yang harus ditutup:

1. Tombol mikrofon harus benar-benar aktif.
2. Permission mikrofon harus ditangani.
3. Speech-to-text Bahasa Indonesia harus bekerja.
4. Hasil suara harus diparsing menjadi data transaksi.
5. Pengguna harus melihat dan mengoreksi hasil sebelum menyimpan.
6. Transaksi suara harus masuk melalui flow repository yang sama dengan transaksi manual.
7. Fitur harus aman saat permission ditolak, suara tidak terbaca, atau hasil parsing tidak lengkap.
8. Fitur harus diuji pada HP Android fisik.

---

# 4. Prinsip Implementasi yang Tidak Boleh Dilanggar

## 4.1 Local-first

Voice transaction harus tetap dapat diproses tanpa Flask backend.

Backend Flask tidak boleh menerima:

- nominal transaksi;
- kategori transaksi;
- detail pengeluaran;
- saldo pengguna;
- isi transaksi personal;
- transkrip suara personal.

Speech-to-text dan parsing harus dilakukan di sisi Flutter/perangkat.

## 4.2 Jangan Merusak Flow Manual

Flow transaksi manual yang sudah ada harus menjadi source of truth.

Fitur voice tidak boleh membuat jalur penyimpanan transaksi baru yang terpisah.

Setelah hasil voice dikonfirmasi, data harus diproses melalui:

- model transaksi yang sama;
- validation yang sama;
- repository transaksi yang sama;
- Isar write flow yang sama;
- sync status yang sama;
- mekanisme UUID yang sama;
- mekanisme timestamp UTC yang sama.

## 4.3 Selalu Ada Konfirmasi Pengguna

Hasil speech-to-text tidak boleh langsung disimpan sebagai transaksi.

Sebelum transaksi disimpan, pengguna harus melihat halaman atau form konfirmasi yang berisi:

- jenis transaksi;
- nominal;
- kategori;
- tanggal transaksi;
- deskripsi atau catatan;
- transkrip asli;
- indikator bahwa data berasal dari input suara.

Pengguna harus dapat mengedit semua field sebelum menekan tombol **Simpan**.

## 4.4 Tidak Menggunakan AI Berbayar

Parser transaksi tidak perlu menggunakan Gemini, OpenAI, atau backend AI.

Gunakan parser lokal berbasis aturan agar:

- lebih murah;
- lebih cepat;
- lebih aman;
- lebih mudah diuji;
- tetap dapat digunakan tanpa backend.

## 4.5 Bahasa Utama Indonesia

UI, pesan error, status microphone, dan hasil konfirmasi harus menggunakan Bahasa Indonesia yang mudah dipahami.

## 4.6 Jangan Menyimpan Secret

Jangan menambahkan API key ke Flutter.

Jangan menulis secret ke source code.

Jangan mengubah file `.env` backend untuk fitur ini.

---

# 5. Pengalaman Pengguna yang Diinginkan

## 5.1 Titik Masuk Fitur

Pengguna dapat memulai input suara dari tab **Keuangan**.

Titik masuk dapat berupa:

- tombol mikrofon pada Floating Action Button;
- tombol mikrofon di samping tombol tambah transaksi;
- action button yang sudah tersedia.

Gunakan pola UI yang paling konsisten dengan struktur aplikasi sekarang.

Jangan mengubah layout utama secara besar-besaran jika tidak diperlukan.

## 5.2 Alur Utama

Alur yang diinginkan:

1. Pengguna membuka tab Keuangan.
2. Pengguna menekan tombol mikrofon.
3. Aplikasi mengecek permission mikrofon.
4. Jika belum diberikan, aplikasi meminta permission.
5. Aplikasi mulai mendengarkan ucapan pengguna.
6. UI menampilkan status bahwa aplikasi sedang mendengarkan.
7. Speech-to-text menghasilkan transkrip Bahasa Indonesia.
8. Parser lokal mencoba mengenali:
   - pemasukan atau pengeluaran;
   - nominal;
   - kategori;
   - tanggal;
   - deskripsi.
9. Aplikasi membuka form konfirmasi.
10. Pengguna mengoreksi hasil jika diperlukan.
11. Pengguna menekan tombol Simpan.
12. Transaksi disimpan melalui repository transaksi yang sudah ada.
13. Ringkasan Keuangan dan Beranda diperbarui.
14. Transaksi ikut masuk ke flow sinkronisasi Spreadsheet yang sudah ada.

## 5.3 Status UI Saat Mendengarkan

Saat mikrofon aktif, tampilkan status yang jelas, misalnya:

- `Sedang mendengarkan...`
- animasi microphone sederhana;
- tombol berhenti;
- transkrip sementara jika package mendukung partial result.

Jangan membuat UI terlalu kompleks.

Pastikan pengguna tahu:

- kapan aplikasi mulai mendengarkan;
- kapan aplikasi berhenti;
- apakah ucapan berhasil dikenali;
- apa yang harus dilakukan jika gagal.

---

# 6. Contoh Ucapan yang Harus Didukung

Parser tidak harus memahami semua variasi bahasa manusia, tetapi harus mendukung kalimat umum dalam Bahasa Indonesia.

## 6.1 Pengeluaran

### Contoh 1

Ucapan:

> Beli nasi goreng dua puluh lima ribu hari ini

Hasil awal yang diharapkan:

- type: pengeluaran;
- amount: 25000;
- category: Makanan atau kategori aktif yang paling sesuai;
- date: hari ini;
- note: Beli nasi goreng;
- transcript: kalimat asli.

### Contoh 2

Ucapan:

> Bayar bensin lima puluh ribu tadi pagi

Hasil awal:

- type: pengeluaran;
- amount: 50000;
- category: Transportasi;
- date: hari ini;
- note: Bayar bensin.

### Contoh 3

Ucapan:

> Keluar seratus ribu untuk belanja bulanan

Hasil awal:

- type: pengeluaran;
- amount: 100000;
- category: Belanja atau kategori yang paling mendekati;
- note: Belanja bulanan.

## 6.2 Pemasukan

### Contoh 4

Ucapan:

> Gajian satu juta hari ini

Hasil awal:

- type: pemasukan;
- amount: 1000000;
- category: Gaji;
- date: hari ini;
- note: Gajian.

### Contoh 5

Ucapan:

> Dapat uang dua ratus ribu dari mama

Hasil awal:

- type: pemasukan;
- amount: 200000;
- category: Pemasukan Lainnya atau kategori aktif yang sesuai;
- note: Dari mama.

### Contoh 6

Ucapan:

> Dividen BBCA tiga ratus lima puluh ribu

Hasil awal:

- type: pemasukan;
- amount: 350000;
- category: Dividen;
- note: Dividen BBCA.

## 6.3 Format Angka yang Harus Didukung

Minimal parser harus mengenali:

- `25 ribu`;
- `dua puluh lima ribu`;
- `100 ribu`;
- `seratus ribu`;
- `1 juta`;
- `satu juta`;
- `1,5 juta`;
- `satu juta lima ratus ribu`;
- `25000`;
- `25.000`;
- `Rp25.000`;
- `lima puluh ribu rupiah`.

Jika nominal tidak dapat dipastikan, jangan mengarang angka.

Buka form konfirmasi dengan nominal kosong atau tampilkan pesan agar pengguna melengkapinya.

---

# 7. Aturan Parser Lokal

Buat parser lokal yang terpisah dari UI.

Jangan menaruh seluruh parsing logic di widget atau screen.

Contoh tanggung jawab parser:

```text
VoiceTransactionParser
- normalizeTranscript()
- detectTransactionType()
- extractAmount()
- detectCategory()
- extractDate()
- buildDescription()
- calculateConfidence()
```

Nama kelas boleh disesuaikan dengan struktur proyek.

## 7.1 Normalisasi Teks

Sebelum parsing:

- ubah menjadi lowercase;
- hapus spasi berlebih;
- normalisasi kata `rupiah`, `rp`, `ribu`, `rb`, `juta`, `jt`;
- pertahankan transkrip asli untuk audit dan tampilan pengguna;
- jangan menghapus kata penting sebelum proses klasifikasi.

## 7.2 Deteksi Jenis Transaksi

Contoh keyword pengeluaran:

- beli;
- bayar;
- belanja;
- keluar;
- habis;
- pengeluaran;
- makan;
- minum;
- bensin;
- ongkos;
- top up;
- transfer ke.

Contoh keyword pemasukan:

- gaji;
- gajian;
- dapat;
- menerima;
- masuk;
- pemasukan;
- bonus;
- dividen;
- transfer dari;
- dikirim;
- pendapatan.

Jika tipe tidak yakin:

- gunakan hasil yang paling kuat;
- tampilkan hasil di form konfirmasi;
- tandai confidence rendah;
- jangan menyimpan otomatis.

## 7.3 Deteksi Kategori

Kategori harus merujuk pada kategori aktif di Isar.

Jangan hard-code ID kategori.

Mapping keyword boleh dibuat, tetapi hasil akhirnya harus dicocokkan dengan kategori aktif yang tersedia.

Contoh mapping:

| Keyword | Kandidat Kategori |
|---|---|
| makan, nasi, kopi, minum, restoran | Makanan |
| bensin, ojek, grab, gojek, bus, ongkos | Transportasi |
| listrik, air, internet, pulsa | Tagihan |
| obat, dokter, rumah sakit | Kesehatan |
| buku, kuliah, kursus | Pendidikan |
| gaji, gajian | Gaji |
| bonus | Bonus |
| dividen | Dividen |
| hadiah, pemberian | Pemasukan Lainnya |

Jika kategori tidak ditemukan:

- pilih kategori fallback yang aman jika memang sudah ada;
- atau biarkan pengguna memilih kategori di form konfirmasi;
- jangan membuat kategori baru secara otomatis.

## 7.4 Tanggal Transaksi

Minimal dukung:

- hari ini;
- kemarin;
- tadi pagi;
- tadi siang;
- tadi malam.

Untuk MVP:

- `hari ini` dan kata `tadi` dapat dipetakan ke tanggal hari ini;
- `kemarin` dipetakan ke satu hari sebelumnya;
- jika tanggal tidak disebutkan, default ke waktu saat ini.

Pastikan timezone sesuai perangkat dan penyimpanan tetap mengikuti standar proyek.

## 7.5 Confidence

Boleh gunakan skor sederhana berbasis rule.

Contoh:

- nominal berhasil dikenali: +40;
- tipe berhasil dikenali: +25;
- kategori ditemukan: +20;
- tanggal ditemukan: +5;
- deskripsi tidak kosong: +10.

Skor confidence tidak perlu bersifat ilmiah.

Tujuannya hanya membantu UI menjelaskan apakah hasil parsing cukup lengkap.

Contoh level:

- 80–100: Tinggi;
- 50–79: Sedang;
- 0–49: Rendah.

Confidence tidak boleh menggantikan konfirmasi pengguna.

---

# 8. Model Hasil Parsing

Buat model/domain object khusus untuk hasil parsing sementara.

Contoh field:

```text
VoiceTransactionParseResult
- originalTranscript
- normalizedTranscript
- transactionType
- amount
- categoryId atau categoryCandidate
- transactionDate
- description
- confidenceScore
- missingFields
- warnings
```

Model ini bukan transaksi final.

Transaksi final hanya dibuat setelah pengguna menekan Simpan pada form konfirmasi.

---

# 9. Penggunaan Model VoiceTranscript

Periksa model `VoiceTranscript` yang sudah ada.

Jangan langsung membuat model baru sebelum memahami field dan fungsi model tersebut.

Jika model sesuai, gunakan untuk menyimpan data seperti:

- UUID;
- original transcript;
- parsed amount;
- parsed type;
- parsed category;
- confidence score;
- status parsing;
- createdAt;
- related transaction UUID setelah berhasil disimpan.

Jika model belum lengkap, lakukan perubahan sekecil mungkin dan pastikan:

- Isar schema generation tetap berhasil;
- migration atau compatibility diperhatikan;
- test diperbarui;
- tidak merusak data lokal yang sudah ada.

Jika menyimpan transkrip tidak diperlukan untuk flow existing, jelaskan alasan keputusan sebelum mengubah schema.

---

# 10. Permission Mikrofon

Periksa konfigurasi Android:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```

Pastikan permission ditempatkan pada posisi XML yang benar.

Jangan merusak struktur `AndroidManifest.xml`.

Sebelumnya proyek pernah mengalami error karena manifest tidak valid, sehingga setiap perubahan harus diperiksa dengan teliti.

Skenario permission yang harus ditangani:

1. Permission belum pernah diminta.
2. Permission diberikan.
3. Permission ditolak.
4. Permission ditolak permanen.
5. Sistem speech recognition tidak tersedia.
6. Mikrofon sedang digunakan aplikasi lain.
7. Aplikasi masuk background saat listening.

Pesan Bahasa Indonesia yang disarankan:

- `Izin mikrofon diperlukan untuk mencatat transaksi melalui suara.`
- `Izin mikrofon ditolak. Anda tetap dapat mencatat transaksi secara manual.`
- `Izin mikrofon dinonaktifkan secara permanen. Aktifkan melalui Pengaturan perangkat.`

Jangan memaksa pengguna membuka settings tanpa penjelasan.

---

# 11. Speech-to-Text

Audit dependency yang sudah tersedia di `pubspec.yaml`.

Jika belum ada dependency speech recognition, gunakan package Flutter yang:

- stabil;
- mendukung Android;
- mendukung locale `id_ID`;
- tidak membutuhkan API key;
- dapat berjalan menggunakan speech recognition perangkat;
- memiliki error handling yang jelas.

Preferensi implementasi:

- buat service terpisah, misalnya `SpeechRecognitionService`;
- jangan memanggil package langsung dari banyak screen;
- expose state seperti:
  - unavailable;
  - idle;
  - listening;
  - processing;
  - completed;
  - error.

Selalu gunakan locale Bahasa Indonesia jika tersedia:

```text
id_ID
```

Jika locale tidak tersedia, tampilkan pesan yang jujur dan jangan crash.

---

# 12. Form Konfirmasi

Form konfirmasi voice harus menggunakan komponen dan flow transaksi manual yang sudah ada sejauh memungkinkan.

Field minimal:

- tipe transaksi;
- nominal;
- kategori;
- tanggal;
- catatan;
- transkrip suara.

Tombol:

- Simpan;
- Ubah;
- Batal;
- Coba rekam lagi, jika sesuai dengan UI existing.

Validasi:

- nominal wajib lebih dari 0;
- kategori wajib valid;
- tipe transaksi wajib valid;
- tanggal wajib valid;
- catatan opsional;
- transkrip boleh tetap ditampilkan meskipun pengguna mengubah field hasil parsing.

Transkrip tidak perlu dikirim ke Google Spreadsheet kecuali struktur sync sekarang memang sudah mendukung dan keputusan tersebut aman.

---

# 13. Data Flow yang Wajib Digunakan

Flow akhir harus seperti berikut:

```text
Microphone Button
    ↓
Speech Recognition Service
    ↓
Raw Transcript
    ↓
Voice Transaction Parser
    ↓
Temporary Parse Result
    ↓
Confirmation Form
    ↓
Existing Transaction Validation
    ↓
Existing Transaction Repository
    ↓
Isar Local Database
    ↓
Existing UI Refresh
    ↓
Existing Spreadsheet Sync Flow
```

Jangan membuat alur berikut:

```text
Microphone
    ↓
Direct Isar Write
```

Jangan membuat alur penyimpanan kedua khusus voice.

---

# 14. Offline dan Backend Failure

Fitur voice transaction tidak boleh bergantung pada:

- Flask;
- Gemini;
- Google News;
- market provider;
- EODHD;
- koneksi backend.

Jika internet tidak tersedia:

- speech recognition mengikuti kemampuan perangkat;
- hasil transaksi tetap dapat disimpan lokal;
- status sync tetap mengikuti mekanisme yang sudah ada;
- aplikasi tidak crash;
- pengguna dapat menyinkronkan nanti.

Jika speech engine perangkat membutuhkan koneksi dan gagal, tampilkan pesan yang jujur:

> Pengenalan suara sedang tidak tersedia. Silakan coba lagi atau gunakan input manual.

---

# 15. Edge Cases yang Harus Ditangani

## 15.1 Tidak Ada Suara

Hasil:

- jangan membuka transaksi kosong secara diam-diam;
- tampilkan pesan;
- sediakan opsi coba lagi atau input manual.

## 15.2 Transkrip Kosong

Hasil:

- jangan menjalankan parser sebagai transaksi valid;
- tampilkan error ringan.

## 15.3 Nominal Tidak Ditemukan

Ucapan:

> Beli makan siang

Hasil:

- buka form konfirmasi;
- nominal kosong;
- tampilkan warning `Nominal belum dikenali`;
- pengguna wajib mengisi nominal.

## 15.4 Kategori Tidak Ditemukan

Ucapan:

> Bayar sesuatu lima puluh ribu

Hasil:

- tipe dan nominal dapat terisi;
- kategori harus dipilih pengguna;
- jangan membuat kategori baru otomatis.

## 15.5 Tipe Tidak Jelas

Ucapan:

> Lima puluh ribu dari teman

Hasil:

- parser boleh memilih tipe berdasarkan keyword `dari`;
- confidence diturunkan;
- pengguna dapat memperbaiki.

## 15.6 Nominal Ganda

Ucapan:

> Beli dua kopi masing-masing dua puluh ribu total empat puluh ribu

Parser harus menghindari mengambil angka secara acak.

Untuk MVP, pilih kandidat nominal yang paling masuk akal dan tampilkan warning pada form konfirmasi.

## 15.7 Pengguna Membatalkan

Jika pengguna membatalkan sebelum menyimpan:

- jangan membuat transaksi;
- jangan mengubah ringkasan;
- jangan menandai data sebagai synced.

## 15.8 Duplicate Tap

Cegah tombol Simpan ditekan dua kali dan menghasilkan transaksi ganda.

---

# 16. Audit Awal Wajib Sebelum Mengubah Kode

Mulai pekerjaan dengan **Langkah 0 — Audit Voice Input Flow**.

Pada langkah ini jangan mengubah kode.

Periksa minimal:

- `pubspec.yaml`;
- `lib/main.dart`;
- `lib/app.dart`;
- `lib/core/router/app_router.dart`;
- `android/app/src/main/AndroidManifest.xml`;
- model `VoiceTranscript`;
- model `MoneyTransaction`;
- model `Category`;
- transaction repository;
- category repository;
- screen tab Keuangan;
- form tambah/edit transaksi;
- provider/state management terkait transaksi;
- service voice atau speech yang mungkin sudah ada;
- parser yang mungkin sudah ada;
- tombol mikrofon yang mungkin sudah ada;
- route konfirmasi jika sudah ada;
- test transaksi;
- test parser atau voice jika sudah ada.

Output audit harus menjawab:

1. Apa yang benar-benar sudah terimplementasi?
2. Apa yang masih placeholder?
3. Apa yang belum terhubung?
4. Package apa yang sudah tersedia?
5. Apakah permission sudah benar?
6. Apakah model VoiceTranscript sudah digunakan?
7. Bagaimana flow penyimpanan transaksi manual sekarang?
8. Bagaimana state UI diperbarui setelah transaksi tersimpan?
9. Risiko regresi apa yang harus dihindari?
10. File mana yang kemungkinan perlu dibuat atau diubah?

Setelah audit, berhenti dan laporkan hasilnya.

Jangan langsung mengimplementasikan seluruh fitur sebelum hasil audit disetujui.

---

# 17. Rencana Implementasi Bertahap

Setelah audit disetujui, implementasi dilakukan dalam langkah kecil.

## Langkah 1 — Speech Recognition Foundation

Tujuan:

- dependency tersedia;
- permission benar;
- service speech-to-text dibuat;
- locale Indonesia digunakan;
- error state aman.

Belum perlu menyimpan transaksi.

## Langkah 2 — Local Voice Transaction Parser

Tujuan:

- parser terpisah dari UI;
- mendukung angka Indonesia;
- mendeteksi tipe;
- mendeteksi kategori;
- mendeteksi tanggal;
- menghasilkan confidence dan missing fields;
- unit test parser tersedia.

## Langkah 3 — Voice Capture UI

Tujuan:

- tombol mikrofon aktif;
- status listening terlihat;
- transkrip ditampilkan;
- cancel dan retry berfungsi;
- error permission aman.

## Langkah 4 — Confirmation Flow

Tujuan:

- hasil parser masuk ke form konfirmasi;
- pengguna dapat mengubah semua field;
- tidak ada autosave;
- validation sama dengan transaksi manual.

## Langkah 5 — Existing Repository Integration

Tujuan:

- transaksi voice disimpan melalui repository existing;
- UUID, soft delete, sync status, dan timestamp mengikuti aturan existing;
- UI Beranda dan Keuangan diperbarui;
- tidak ada transaksi ganda.

## Langkah 6 — VoiceTranscript Integration

Tujuan:

- model VoiceTranscript digunakan secara tepat jika relevan;
- relasi dengan transaksi final jelas;
- data personal tidak dikirim ke backend.

## Langkah 7 — Automated Test dan Manual Test

Tujuan:

- test parser;
- test validation;
- test repository integration;
- test cancellation;
- test missing amount;
- test category fallback;
- test duplicate submit;
- manual test HP fisik.

Setiap langkah harus berhenti setelah selesai dan menunggu instruksi berikutnya.

---

# 18. Automated Test Minimal

Tambahkan test yang relevan tanpa memanggil speech engine asli.

Speech service harus dapat di-mock atau di-fake.

## 18.1 Parser Test

Minimal uji:

```text
"beli kopi dua puluh lima ribu"
=> expense, 25000
```

```text
"gajian satu juta"
=> income, 1000000
```

```text
"bayar bensin 50 ribu"
=> expense, 50000, transportasi
```

```text
"dividen bbca tiga ratus ribu"
=> income, 300000, dividen
```

```text
"beli makan"
=> amount missing
```

```text
"kemarin bayar listrik seratus ribu"
=> date yesterday, expense, 100000
```

## 18.2 Validation Test

Uji:

- amount 0 ditolak;
- amount kosong ditolak;
- kategori kosong ditolak;
- tipe kosong ditolak;
- submit dua kali tidak menghasilkan duplikasi.

## 18.3 Repository Integration Test

Pastikan transaksi voice yang sudah dikonfirmasi:

- disimpan sebagai `MoneyTransaction`;
- memiliki UUID;
- memiliki sync status awal yang benar;
- muncul pada query transaksi;
- memengaruhi monthly summary;
- tidak memerlukan backend Flask.

## 18.4 Widget Test

Jika realistis, uji:

- tombol mikrofon;
- state listening;
- transkrip;
- form konfirmasi;
- pesan permission ditolak;
- tombol batal;
- tombol simpan.

---

# 19. Manual Test pada HP Android Fisik

Manual test harus didokumentasikan.

## Skenario 1 — Permission Pertama Kali

1. Install aplikasi baru.
2. Buka tab Keuangan.
3. Tekan tombol mikrofon.
4. Berikan permission.
5. Pastikan listening dimulai.
6. Ucapkan transaksi.
7. Pastikan form konfirmasi terbuka.

## Skenario 2 — Permission Ditolak

1. Tolak permission.
2. Pastikan aplikasi tidak crash.
3. Pastikan pesan Bahasa Indonesia muncul.
4. Pastikan transaksi manual tetap dapat digunakan.

## Skenario 3 — Pengeluaran

Ucapan:

> Beli nasi goreng dua puluh lima ribu

Validasi:

- type pengeluaran;
- nominal 25000;
- kategori masuk akal;
- form bisa diedit;
- transaksi tersimpan;
- ringkasan berubah.

## Skenario 4 — Pemasukan

Ucapan:

> Gajian satu juta

Validasi:

- type pemasukan;
- nominal 1000000;
- kategori Gaji;
- transaksi tersimpan.

## Skenario 5 — Nominal Tidak Dikenali

Ucapan:

> Beli makan siang

Validasi:

- nominal tidak diisi secara palsu;
- pengguna diminta mengisi;
- transaksi tidak tersimpan sebelum valid.

## Skenario 6 — Edit Sebelum Simpan

1. Rekam suara.
2. Ubah nominal.
3. Ubah kategori.
4. Simpan.
5. Pastikan nilai final yang tersimpan adalah hasil edit pengguna.

## Skenario 7 — Batal

1. Rekam suara.
2. Buka konfirmasi.
3. Tekan Batal.
4. Pastikan tidak ada transaksi baru.

## Skenario 8 — Backend Mati

1. Matikan Flask backend.
2. Jalankan voice transaction.
3. Pastikan transaksi tetap tersimpan lokal.
4. Pastikan tab Keuangan tidak crash.

## Skenario 9 — Offline

1. Matikan internet.
2. Coba voice transaction.
3. Jika speech engine masih tersedia, transaksi harus tersimpan lokal.
4. Jika recognition tidak tersedia, tampilkan fallback yang aman.
5. Input manual tetap harus bekerja.

## Skenario 10 — Sync Spreadsheet

1. Simpan transaksi suara.
2. Jalankan sync manual.
3. Pastikan transaksi ikut disinkronkan melalui flow existing.
4. Pastikan tidak ada duplikasi UUID.

---

# 20. Definition of Done

Tahap ini baru boleh dianggap selesai jika semua kondisi berikut terpenuhi:

- tombol mikrofon benar-benar bekerja;
- permission mikrofon ditangani dengan aman;
- locale Indonesia digunakan;
- speech-to-text menghasilkan transkrip;
- parser lokal mengenali nominal dasar Bahasa Indonesia;
- parser dapat membedakan pemasukan dan pengeluaran;
- parser dapat memberikan kandidat kategori;
- hasil selalu melalui form konfirmasi;
- pengguna dapat mengedit hasil;
- transaksi disimpan melalui repository existing;
- transaksi masuk ke Isar;
- transaksi memengaruhi monthly summary;
- transaksi ikut flow sync existing;
- backend mati tidak menyebabkan fitur lokal crash;
- tidak ada autosave dari hasil speech;
- tidak ada data pribadi dikirim ke Flask;
- unit test parser lulus;
- test transaksi existing tetap lulus;
- `flutter analyze` lulus;
- `flutter test` lulus;
- aplikasi dapat dijalankan di HP fisik;
- manual test terdokumentasi;
- klaim CV voice-based transaction dapat didemonstrasikan.

---

# 21. Hal yang Dilarang

Codex tidak boleh:

- langsung menyimpan hasil suara tanpa konfirmasi;
- mengirim transkrip ke Gemini;
- mengirim transaksi personal ke Flask;
- menyimpan API key di Flutter;
- membuat repository transaksi baru tanpa alasan kuat;
- menduplikasi logic transaksi manual;
- membuat kategori baru otomatis dari suara;
- menebak nominal ketika parser gagal;
- mengubah arsitektur besar-besaran;
- menghapus flow manual;
- mengubah spreadsheet sync tanpa kebutuhan;
- mengubah backend market/news/AI;
- mengubah file di luar scope tanpa menjelaskan alasan;
- menjalankan seluruh tahap sekaligus tanpa checkpoint;
- menyatakan selesai hanya karena build berhasil.

---

# 22. Format Laporan Codex pada Setiap Langkah

Setelah menyelesaikan setiap langkah, laporkan:

## Ringkasan

Jelaskan apa yang dikerjakan.

## File yang Diperiksa

Daftar file yang diperiksa.

## File yang Dibuat

Daftar file baru.

## File yang Diubah

Daftar file yang diubah.

## Perilaku Sebelum

Jelaskan kondisi sebelumnya.

## Perilaku Sesudah

Jelaskan kondisi setelah perubahan.

## Keputusan Teknis

Jelaskan alasan desain yang dipilih.

## Risiko Regresi

Jelaskan risiko yang masih ada.

## Test yang Dijalankan

Tuliskan command dan hasil:

```bash
flutter analyze
flutter test
```

Tambahkan test lain jika relevan.

## Manual Test yang Masih Dibutuhkan

Jelaskan pengujian HP fisik yang belum dapat dilakukan Codex.

## Status Langkah

Gunakan salah satu:

- `SELESAI`
- `SELESAI DENGAN CATATAN`
- `BELUM SELESAI`
- `BLOCKED`

Setelah itu berhenti dan tunggu instruksi berikutnya.

---

# 23. Instruksi Pertama untuk Codex

Mulai dari:

> **Langkah 0 — Audit Voice Input Flow**

Lakukan audit menyeluruh tanpa mengubah kode.

Jangan melakukan instalasi package, membuat file, mengubah manifest, atau mengimplementasikan parser pada langkah ini.

Laporkan kondisi nyata repository, gap teknis, risiko regresi, dan rencana Langkah 1.

Setelah laporan audit selesai, berhenti dan tunggu persetujuan sebelum melakukan perubahan apa pun.
