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
3. `Stock_Transactions`
4. `Dividends`
5. `Watchlist`

## Entity yang Sudah Didukung Kode Apps Script

1. `Categories`
2. `Transactions`
3. `Stock_Transactions`
4. `Dividends`
5. `Watchlist`

Catatan:
- Flutter menjalankan sync dua arah untuk seluruh entity utama personal finance dan portofolio.
- Semua entity memakai UUID sebagai source of truth, soft delete, dan conflict handling `latest updatedAt wins`.

## Tahap Sync Manual Flutter Saat Ini

1. `push Categories`
2. `push Transactions`
3. `push Stock_Transactions`
4. `push Dividends`
5. `push Watchlist`
6. `pull Categories`
7. `pull Transactions`
8. `pull Stock_Transactions`
9. `pull Dividends`
10. `pull Watchlist`

## Redirect Google Apps Script

MoneyPilot sekarang menangani redirect Google Apps Script seperti ini:

- Request sync pertama ke `/exec` tetap `POST`.
- Jika request sync (`push`/`pull`) mendapat redirect `301`, `302`, `303`, `307`, atau `308`, Flutter tetap mengirim `POST` dengan body JSON yang sama ke URL redirect.
- Jika request `health check` (`GET`) mendapat redirect, method tetap `GET`.
- Redirect dibatasi maksimal 3 hop.

## Catatan Penting

- Google Apps Script wajib mengembalikan JSON murni.
- Flutter akan menolak response non-JSON dan menampilkan `statusCode`, `content-type`, dan `bodyPreview` maksimal 300 karakter.
- Jika sync gagal, pesan error akan menyebut tahap yang gagal, misalnya `Gagal pada tahap push Categories`.
- Status sinkronisasi lokal yang dipakai UI:
  - `synced`
  - `pending`
  - `failed`
