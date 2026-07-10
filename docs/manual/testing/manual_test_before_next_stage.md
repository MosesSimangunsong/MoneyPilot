# Manual Test Before Next Stage

Checklist ini wajib diselesaikan sebelum memilih tahap roadmap berikutnya.

## Startup dan Akses Awal
- [ ] App startup berhasil tanpa crash
- [ ] Splash screen tampil normal lalu pindah ke flow berikutnya
- [ ] Onboarding muncul untuk user baru
- [ ] Onboarding selesai dan tidak muncul lagi setelah state tersimpan
- [ ] Biometric lock tampil sesuai pengaturan
- [ ] Biometric berhasil membuka aplikasi
- [ ] Jika biometric gagal, user mendapat pesan Bahasa Indonesia yang jelas

## Keuangan Manual
- [ ] Tambah transaksi pemasukan manual berhasil
- [ ] Tambah transaksi pengeluaran manual berhasil
- [ ] Edit transaksi manual berhasil
- [ ] Hapus lembut transaksi manual berhasil
- [ ] Ringkasan bulanan di tab Keuangan ikut berubah
- [ ] Tidak ada error state berbahasa Inggris pada flow keuangan

## Voice Input
- [ ] Voice input bisa mulai merekam
- [ ] Contoh "Saya beli kopi 15 ribu" masuk ke halaman konfirmasi
- [ ] User masih bisa koreksi hasil parser sebelum simpan
- [ ] Simpan hasil voice input membuat transaksi baru berhasil
- [ ] Jika speech service gagal, tampil pesan Bahasa Indonesia yang jelas

## Spreadsheet Sync
- [ ] Health check Google Apps Script berhasil untuk URL yang valid
- [ ] Secret token tidak di-hardcode di source Flutter
- [ ] Simpan konfigurasi spreadsheet berhasil
- [ ] Sync manual push dan pull berjalan untuk data yang ada
- [ ] Jika URL salah, tampil error Bahasa Indonesia yang jelas
- [ ] Jika token kosong, tampil validasi Bahasa Indonesia yang jelas
- [ ] Jika network timeout, user mendapat fallback error yang jelas

## Backend Market dan Portofolio
- [ ] Backend hidup: quote market bisa dipakai untuk menampilkan harga pasar
- [ ] Backend mati: tab Portofolio tetap bisa dibuka tanpa crash
- [ ] Backend mati: posisi lokal tetap tampil
- [ ] Backend mati: harga pasar menampilkan fallback yang aman
- [ ] Catat transaksi saham manual tetap berhasil saat backend mati
- [ ] Catat dividen tetap berhasil saat backend mati
- [ ] Tidak ada teks yang terlihat seperti rekomendasi investasi

## Berita dan Analisis
- [ ] Tab Berita bisa memuat daftar berita saat backend hidup
- [ ] Filter kategori berita tetap berfungsi
- [ ] Detail berita bisa dibuka
- [ ] Analisis dampak berita bisa dimuat saat backend hidup
- [ ] Jika backend mati, tab Berita menampilkan fallback yang jelas
- [ ] Jika backend mati, analisis berita menampilkan fallback yang jelas
- [ ] Disclaimer "bukan nasihat keuangan" terlihat pada analisis
- [ ] Tidak ada output analisis yang berisi ajakan beli/jual
- [ ] Tidak ada frase seperti "pasti naik" atau "pasti turun"

## Gate Sebelum Lanjut Tahap Berikutnya
- [ ] Semua flow utama di atas sudah dites minimal sekali
- [ ] Temuan manual test sudah dicatat
- [ ] Bug blocker sudah diperbaiki atau diputuskan untuk ditahan
- [ ] Tahap berikutnya belum dipilih sebelum checklist ini selesai
