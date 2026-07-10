# Spreadsheet Sync Config - MoneyPilot

## Konfigurasi Lokal Saat Ini

- URL Google Apps Script disimpan lokal di `AppSetting.gasWebhookUrl`.
- Secret token disimpan lokal di `AppSetting.gasSecretToken`.
- Nilai URL dan token selalu di-`trim()` sebelum disimpan.
- Karakter `\r`, `\n`, dan `\t` dibersihkan saat simpan konfigurasi.
- Sync manual membaca ulang konfigurasi terbaru dari Isar sebelum request dikirim.

## URL Web App

- Gunakan URL Google Apps Script Web App yang berakhiran `/exec`.
- Contoh format:

```text
https://script.google.com/macros/s/AKFY.../exec
```

- Jangan memakai URL editor Apps Script.
- Jangan memakai URL `/dev`.

## Secret Token

- Token wajib sama dengan nilai Script Property `MONEYPILOT_SYNC_TOKEN`.
- Token tidak boleh disimpan di repo.
- Token tidak pernah ditampilkan di log debug Flutter.
- Flutter akan menolak sync jika token kosong sebelum request dikirim.

## Entity yang Aktif Disync Flutter Saat Ini

1. `Categories`
2. `Transactions`

## Entity yang Sudah Didukung Kode Apps Script

1. `Categories`
2. `Transactions`
3. `Stock_Transactions`
4. `Dividends`
5. `Watchlist`

Catatan:
- Flutter saat ini baru menjalankan sync dua arah untuk `Categories` dan `Transactions`.
- Dukungan entity lain sudah disiapkan di Apps Script dan header sheet, tetapi belum aktif di repository sync Flutter saat ini.

## Tahap Sync Manual Flutter Saat Ini

1. `push Categories`
2. `push Transactions`
3. `pull Categories`
4. `pull Transactions`

## Redirect Google Apps Script

MoneyPilot sekarang menangani redirect Google Apps Script seperti ini:

- Request pertama ke `/exec` tetap `POST`.
- Redirect `301`, `302`, `303` diikuti dengan `GET`.
- Redirect `307`, `308` menjaga method `POST` dan body JSON.
- Redirect dibatasi maksimal 3 hop.

## Catatan Penting

- Google Apps Script wajib mengembalikan JSON murni.
- Flutter akan menolak response non-JSON dan menampilkan `statusCode`, `content-type`, dan `bodyPreview` maksimal 300 karakter.
- Jika sync gagal, pesan error akan menyebut tahap yang gagal, misalnya `Gagal pada tahap push Categories`.
- Status sinkronisasi lokal yang dipakai UI:
  - `synced`
  - `pending`
  - `failed`
