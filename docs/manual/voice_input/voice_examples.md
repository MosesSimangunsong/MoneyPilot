# Voice Examples — MoneyPilot

## Pengeluaran Valid

| Kalimat | Tipe | Nominal | Kategori |
|---|---|---:|---|
| Saya beli kopi 15 ribu | expense | 15000 | Makanan & Minuman |
| Beli nasi goreng dua puluh lima ribu | expense | 25000 | Makanan & Minuman |
| Bayar kos satu juta | expense | 1000000 | Kos/Asrama |
| Naik gojek dua belas ribu | expense | 12000 | Transportasi |
| Top up e-wallet lima puluh ribu | expense | 50000 | Lainnya |
| Beli buku kuliah seratus ribu | expense | 100000 | Kuliah/Pendidikan |

## Pemasukan Valid

| Kalimat | Tipe | Nominal | Kategori |
|---|---|---:|---|
| Dapat uang dari orang tua lima ratus ribu | income | 500000 | Uang dari Orang Tua |
| Uang freelance masuk tiga ratus ribu | income | 300000 | Freelance/Part-time |
| Terima beasiswa satu juta | income | 1000000 | Beasiswa |
| Gajian dua juta | income | 2000000 | Gaji |
| Dapat dividen lima puluh ribu | income | 50000 | Dividen |

## Contoh Gagal Nominal

| Kalimat | Expected |
|---|---|
| Saya beli kopi tadi pagi | Buka form manual, catatan berisi transcript |
| Bayar makanan | Buka form manual, catatan berisi transcript |
| Dapat uang dari teman | Buka form manual, catatan berisi transcript |

## Contoh Ambigu

| Kalimat | Expected |
|---|---|
| Transfer lima puluh ribu | Minta konfirmasi tipe transaksi |
| Uang masuk | Buka form manual |
| Bayar sesuatu 20 ribu | expense, kategori Lainnya atau wajib pilih kategori |