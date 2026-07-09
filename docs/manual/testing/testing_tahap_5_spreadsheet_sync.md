# Manual Testing Tahap 5 — Google Spreadsheet Sync

## Persiapan

- [ ] Spreadsheet sudah dibuat.
- [ ] Semua sheet sudah dibuat.
- [ ] Header setiap sheet sudah benar.
- [ ] Google Apps Script sudah deploy sebagai Web App.
- [ ] Web App URL sudah dicatat.
- [ ] Secret token sudah dicatat.
- [ ] URL dan token sudah dimasukkan ke aplikasi.

## Push Transaksi Baru

- [ ] Tambah transaksi manual di aplikasi.
- [ ] Pastikan syncStatus transaksi = pending.
- [ ] Jalankan sync.
- [ ] Row muncul di sheet Transactions.
- [ ] syncStatus lokal berubah menjadi synced.
- [ ] Tidak ada row duplikat.

## Update Row yang Sudah Ada

- [ ] Edit transaksi yang sudah pernah sync.
- [ ] Pastikan syncStatus berubah menjadi pending.
- [ ] Jalankan sync.
- [ ] Row lama di spreadsheet berubah.
- [ ] Tidak muncul row baru dengan UUID yang sama.

## Pull dari Spreadsheet

- [ ] Edit row di spreadsheet.
- [ ] Ubah updatedAt menjadi lebih baru dari data lokal.
- [ ] Jalankan sync pull.
- [ ] Data lokal ikut berubah.
- [ ] Beranda dan Keuangan ikut menampilkan data terbaru.

## Conflict Resolution

- [ ] Edit transaksi di aplikasi.
- [ ] Edit row yang sama di spreadsheet.
- [ ] Buat salah satu updatedAt lebih baru.
- [ ] Jalankan sync.
- [ ] Data dengan updatedAt terbaru menang.
- [ ] Data yang lebih lama tidak menimpa data terbaru.

## Soft Delete

- [ ] Hapus transaksi di aplikasi.
- [ ] Jalankan sync.
- [ ] Row spreadsheet tetap ada.
- [ ] isDeleted berubah menjadi true.
- [ ] deletedAt terisi.
- [ ] Data tidak muncul lagi di daftar transaksi aktif.

## Offline / Failed Sync

- [ ] Matikan internet.
- [ ] Tambah transaksi.
- [ ] Pastikan transaksi tetap tersimpan lokal.
- [ ] Pastikan syncStatus = pending atau failed sesuai kondisi.
- [ ] Nyalakan internet.
- [ ] Jalankan sync ulang.
- [ ] Data terkirim ke spreadsheet.

## Token Salah

- [ ] Masukkan token salah.
- [ ] Jalankan sync.
- [ ] Aplikasi menampilkan pesan gagal yang jelas.
- [ ] Data lokal tidak hilang.
- [ ] syncErrorMessage terisi.

## Apps Script Error

- [ ] Simulasikan Web App URL salah.
- [ ] Jalankan sync.
- [ ] Aplikasi menampilkan pesan gagal.
- [ ] Data lokal tetap aman.
- [ ] syncStatus menjadi failed.