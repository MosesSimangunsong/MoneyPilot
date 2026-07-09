# Manual Testing Tahap 6 - Spreadsheet Sync Lanjutan dan Redirect

## Tujuan

Checklist ini dipakai setelah dasar sync berjalan untuk memastikan mekanisme redirect dan debugging Flutter sudah sesuai sistem sekarang.

## Redirect 301/302/303

- [ ] Jalankan sync manual ke Web App URL `/exec`.
- [ ] Pastikan request awal tetap menuju `script.google.com`.
- [ ] Pastikan jika Google mengembalikan redirect, aplikasi tetap menerima response JSON akhir.
- [ ] Pastikan tidak muncul lagi error `Moved Temporarily`.

## Redirect 307/308

- [ ] Simulasikan redirect preserve-method di test/unit test.
- [ ] Pastikan `POST` dan body JSON tetap dipertahankan.

## Loop Redirect

- [ ] Simulasikan redirect berulang pada unit test.
- [ ] Pastikan aplikasi berhenti maksimal setelah 3 hop.
- [ ] Pastikan error yang muncul jelas dan tidak infinite loop.

## Non-JSON Response

- [ ] Simulasikan response HTML.
- [ ] Pastikan aplikasi menampilkan:
  - [ ] tahap sync yang gagal
  - [ ] `statusCode`
  - [ ] `content-type`
  - [ ] `bodyPreview`
- [ ] Pastikan token tidak pernah tampil.

## Tahap Sync

- [ ] `push Categories` bisa diidentifikasi di log/pesan error.
- [ ] `push Transactions` bisa diidentifikasi di log/pesan error.
- [ ] `pull Categories` bisa diidentifikasi di log/pesan error.
- [ ] `pull Transactions` bisa diidentifikasi di log/pesan error.

## Regression Check

- [ ] `flutter analyze` bersih.
- [ ] `flutter test` lulus.
- [ ] Test redirect `302` -> `GET` lulus.
- [ ] Test redirect `303` -> `GET` lulus.
- [ ] Test redirect `307` -> `POST` preserve body lulus.
- [ ] Test redirect `308` -> `POST` preserve body lulus.
