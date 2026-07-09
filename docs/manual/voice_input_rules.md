# Voice Input Rules — MoneyPilot

## Prinsip Utama

Voice input tidak boleh langsung menyimpan transaksi.

Alur wajib:
1. User menekan tombol mic.
2. Aplikasi merekam suara.
3. Speech-to-text menghasilkan transcript.
4. Parser mencoba membaca tipe, nominal, kategori, dan catatan.
5. Hasil parsing ditampilkan di halaman konfirmasi.
6. User boleh edit hasil parsing.
7. Transaksi baru disimpan hanya setelah user menekan Simpan.

## Jika Parsing Gagal

Jika nominal tidak terdeteksi:
- Jangan simpan transaksi.
- Buka form manual.
- Isi field catatan dengan raw transcript.
- User mengisi nominal dan kategori secara manual.

Jika kategori tidak terdeteksi:
- Tetap buka halaman konfirmasi.
- Biarkan kategori kosong atau pilih Lainnya.
- User wajib memilih kategori sebelum simpan.

Jika tipe transaksi tidak terdeteksi:
- Default jangan ditebak terlalu agresif.
- User harus memilih Pemasukan atau Pengeluaran di halaman konfirmasi.

## Data yang Wajib Disimpan ke VoiceTranscript

- rawText
- parsedType
- parsedAmount
- parsedCategoryUuid
- confidenceScore
- convertedToTransaction
- transactionUuid jika berhasil disimpan
- createdAt