# Manual Testing Tahap 5 - Spreadsheet Sync Dua Arah

## Persiapan

- [ ] Spreadsheet sudah dibuat.
- [ ] Sheet `Categories` dan `Transactions` sudah ada.
- [ ] Header row pertama sudah benar.
- [ ] Apps Script final sudah dipaste.
- [ ] Script Property `MONEYPILOT_SYNC_TOKEN` sudah ada.
- [ ] Web App sudah di-deploy ulang.
- [ ] URL `/exec` dan token sudah dimasukkan ke halaman `Pengaturan`.

## Simpan Konfigurasi

- [ ] Isi URL `/exec` di Settings.
- [ ] Isi secret token.
- [ ] Klik `Simpan konfigurasi`.
- [ ] Tutup dan buka ulang Settings.
- [ ] Pastikan URL dan token yang tersimpan tetap benar.
- [ ] Pastikan status pending sync tampil jika ada perubahan lokal.

## Push Categories

- [ ] Pastikan ada kategori dengan `syncStatus = pending` atau `failed`.
- [ ] Klik `Jalankan sync manual`.
- [ ] Jika gagal, pesan menyebut tahap `push Categories`.
- [ ] Jika sukses, kategori berubah menjadi `synced`.

## Push Transactions

- [ ] Tambah transaksi manual baru.
- [ ] Pastikan transaksi memiliki `syncStatus = pending`.
- [ ] Klik `Jalankan sync manual`.
- [ ] Pastikan row masuk ke sheet `Transactions`.
- [ ] Pastikan tidak ada row duplikat dengan `uuid` yang sama.

## Pull Transactions

- [ ] Edit row transaksi di spreadsheet.
- [ ] Ubah `updatedAt` menjadi lebih baru dari lokal.
- [ ] Klik `Jalankan sync manual`.
- [ ] Pastikan data lokal ikut berubah.

## Soft Delete

- [ ] Hapus transaksi di aplikasi.
- [ ] Klik `Jalankan sync manual`.
- [ ] Pastikan row spreadsheet tetap ada.
- [ ] Pastikan `isDeleted = true`.
- [ ] Pastikan `deletedAt` terisi.

## Error Diagnostics

- [ ] Jika sync gagal, pesan memuat tahap gagal.
- [ ] Jika response bukan JSON, pesan memuat `statusCode`.
- [ ] Jika response bukan JSON, pesan memuat `content-type`.
- [ ] Jika response bukan JSON, pesan memuat `bodyPreview` maksimal 300 karakter.
- [ ] Token tidak pernah muncul di pesan error.

## Redirect Google Apps Script

- [ ] Jika Google mengembalikan redirect `302` atau `303`, sync tetap lanjut dengan `POST` yang sama.
- [ ] Jika response akhir valid, aplikasi tidak lagi berhenti di HTML `Moved Temporarily`.
