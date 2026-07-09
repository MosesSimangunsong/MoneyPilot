# Manual Testing Tahap 4 — Voice Input

## Navigasi

- [ ] Aplikasi tetap bisa dibuka.
- [ ] Flow onboarding dan biometric lama tetap aman.
- [ ] Tab Keuangan tetap bisa dibuka.
- [ ] Fitur transaksi manual Tahap 3 tetap berjalan.

## Tombol Voice

- [ ] Tombol mic muncul di halaman Keuangan atau form transaksi.
- [ ] Saat tombol mic ditekan, aplikasi meminta permission microphone jika belum ada.
- [ ] Saat user bicara, transcript muncul.
- [ ] Jika speech gagal, tampil pesan Bahasa Indonesia.

## Parsing Berhasil

- [ ] “Saya beli kopi 15 ribu” menjadi expense 15000.
- [ ] “Beli nasi goreng dua puluh lima ribu” menjadi expense 25000.
- [ ] “Bayar kos satu juta” menjadi expense 1000000.
- [ ] “Dapat uang dari orang tua lima ratus ribu” menjadi income 500000.
- [ ] “Uang freelance masuk tiga ratus ribu” menjadi income 300000.

## Konfirmasi

- [ ] Hasil voice tidak langsung tersimpan.
- [ ] Halaman konfirmasi muncul.
- [ ] User bisa edit judul.
- [ ] User bisa edit nominal.
- [ ] User bisa edit kategori.
- [ ] User bisa edit tipe transaksi.
- [ ] User bisa batal.
- [ ] User bisa simpan.

## Fallback

- [ ] Jika nominal gagal dideteksi, aplikasi membuka form manual.
- [ ] Transcript masuk ke catatan.
- [ ] User bisa melengkapi transaksi manual.

## VoiceTranscript

- [ ] Raw transcript tersimpan.
- [ ] Jika transaksi berhasil dibuat, VoiceTranscript terhubung ke transactionUuid.
- [ ] convertedToTransaction berubah menjadi true setelah simpan.