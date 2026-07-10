# Current Roadmap Status

Dokumen ini merangkum status roadmap aktual MoneyPilot setelah Tahap 9 dan
menjadi acuan sebelum memilih tahap berikutnya.

## Tahap Yang Sudah Selesai
- Tahap 1 App Foundation
- Tahap 2 Local Database Isar
- Tahap 3 Keuangan Manual
- Tahap 4 Voice Input dan Parser Bahasa Indonesia
- Tahap 5 Google Spreadsheet Sync Dua Arah
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

## Tahap Yang Perlu Manual Test
- Tahap 1 sampai Tahap 5 perlu regression test lintas fitur
- Tahap 8 perlu validasi backend hidup dan mati
- Tahap 9 perlu validasi daftar berita, detail berita, analisis dampak, dan
  fallback aman tanpa rekomendasi investasi

## Gate Sebelum Tahap Berikutnya
- Tahap berikutnya belum boleh dipilih sebelum manual test utama lintas fitur
  selesai.
- Fokus saat ini adalah stabilisasi, audit kecil, dan memastikan integrasi yang
  sudah ada tetap aman.

## Rekomendasi Urutan Kerja Berikutnya
1. Selesaikan manual test gabungan di
   `docs/manual/testing/manual_test_before_next_stage.md`.
2. Catat hasil manual test, bug, dan keputusan perbaikan kecil yang memang
   terverifikasi.
3. Jalankan stabilisasi tambahan hanya jika ada bug nyata dari hasil manual
   test.
4. Setelah checklist utama lulus, baru pilih tahap berikutnya yang paling
   rendah risiko dan paling dekat dengan roadmap aktif.

## Rekomendasi Tahap Berikutnya
- Belum memilih tahap baru.
- Keputusan tahap berikutnya harus menunggu hasil manual test utama selesai dan
  dinyatakan stabil.
