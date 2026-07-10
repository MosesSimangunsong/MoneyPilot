# Current Roadmap Status

Dokumen ini merangkum status roadmap aktual MoneyPilot setelah Tahap 13 dan
menjadi acuan penutupan gap klaim CV menuju demo final.

## Tahap Yang Sudah Selesai
- Tahap 1 App Foundation
- Tahap 2 Local Database Isar
- Tahap 3 Keuangan Manual
- Tahap 4 Voice Input dan Parser Bahasa Indonesia
- Tahap 5 Google Spreadsheet Sync Dua Arah
- Tahap 10 Tab Analisis dan Watchlist
- Tahap 11 Settings, Export, dan Privacy
- Tahap 12 Testing, Stabilization, dan Polish MVP
- Tahap 13 CV Claim Gap Closure Foundation
- Tahap 8 Backend Flask dan Market Data
- Tahap 9 Berita dan AI News Impact Analysis

## Tahap Yang Dikerjakan Lebih Awal
- Tahap 8 dikerjakan lebih awal agar kontrak backend, cache, market data mock,
  dan integrasi Flutter untuk portofolio serta berita bisa distabilkan sebelum
  masuk perluasan fitur berikutnya.

## Tahap Yang Belum Dikerjakan
- Tahap 6 lanjutan non-kritis yang belum dipilih ulang pada roadmap aktif
- Tahap 7 yang belum diaktifkan kembali pada urutan kerja terbaru
- Tahap lanjutan portofolio di luar pencatatan manual dasar
- Tahap deployment dan login server
- Tahap integrasi provider market real

## Status Audit Tahap 13
- `flutter analyze`: lulus
- `flutter test`: lulus
- `pytest` backend: tidak dijalankan karena backend tidak berubah
- Halaman kategori sekarang aktif dari UI, mendukung lihat/filter/tambah/edit/
  soft delete kategori dengan validasi nama kosong dan pencegahan duplikasi
- Routing kategori sudah aktif dari tab Keuangan dan halaman Pengaturan
- Copy onboarding sudah disesuaikan dengan fitur aktual seperti voice input,
  local-first storage, spreadsheet sync, portofolio, dividen, watchlist,
  berita, dan analisis edukatif
- Rapikan UX Bahasa Indonesia diterapkan pada area kategori, onboarding, dan
  beberapa label utama di Pengaturan
- Dokumen validasi klaim CV manual ditambahkan

## Manual Test Yang Masih Wajib
- Startup dan onboarding pada perangkat baru
- Category management dari tab Keuangan dan Pengaturan
- Biometric lock pada perangkat yang mendukung dan yang tidak mendukung
- Voice input dengan izin mikrofon aktif/nonaktif
- Spreadsheet sync dengan URL valid, URL salah, token kosong, dan timeout
- Portofolio saat backend hidup dan mati
- Berita, detail berita, dan analisis saat backend hidup dan mati

## Gate Rilis MVP
1. Selesaikan manual test gabungan di
   `docs/manual/testing/manual_test_before_next_stage.md`.
2. Catat hasil manual test dan bukti perangkat yang dipakai.
3. Jika ada blocker manual test, tahan rilis MVP sampai diperbaiki.
4. Jika checklist manual lulus, MVP dapat dinyatakan siap untuk freeze fitur
   besar dan lanjut ke deployment/post-MVP.

## Status Final MVP
- Status saat ini: `candidate-ready`
- Artinya: fondasi MVP sudah kuat dan gap UI/copy paling terlihat sudah
  ditutup, tetapi ekspansi sync portofolio, penguatan market provider, AI demo
  hardening, dan manual regression perangkat nyata masih harus diselesaikan.
