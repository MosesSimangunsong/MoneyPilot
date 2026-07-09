# Spreadsheet Sync Rules - MoneyPilot

## Prinsip Utama

- Isar tetap menjadi sumber data utama aplikasi.
- Google Spreadsheet dipakai untuk backup dan edit ringan.
- Semua entity sync wajib memakai `uuid`.
- Spreadsheet wajib upsert berdasarkan `uuid`, bukan append buta.
- Delete memakai soft delete, bukan hard delete row.
- Conflict resolution memakai `latest updatedAt wins`.
- Semua timestamp dikirim dalam UTC ISO 8601.

## Scope Sync Flutter Saat Ini

Flutter saat ini baru mengaktifkan sync dua arah untuk:

1. `Categories`
2. `Transactions`

Tahap sync manual yang berjalan:

1. `push Categories`
2. `push Transactions`
3. `pull Categories`
4. `pull Transactions`

## Scope Apps Script

Kode Apps Script final saat ini sudah menerima entity:

1. `Categories`
2. `Transactions`
3. `Stock_Transactions`
4. `Dividends`
5. `Watchlist`

## Push Flow

1. Flutter membaca konfigurasi terbaru dari `AppSetting`.
2. Flutter mengirim `POST` JSON ke Web App URL `/exec`.
3. Jika Google mengembalikan redirect:
   - `301`, `302`, `303` diikuti dengan `GET`.
   - `307`, `308` diikuti dengan `POST` yang sama.
4. Apps Script memvalidasi token dari Script Property.
5. Apps Script membaca header row pertama.
6. Apps Script mencari row berdasarkan `uuid`.
7. Jika `uuid` sudah ada, row di-update.
8. Jika `uuid` belum ada, row baru di-insert.
9. Jika push sukses, status lokal diubah menjadi `synced`.
10. Jika push gagal, status lokal diubah menjadi `failed` dan `syncErrorMessage` diisi.

## Pull Flow

1. Flutter mengirim request `pull` dengan `since` dari `lastSpreadsheetPullAt`.
2. Apps Script membaca sheet berdasarkan entity.
3. Apps Script hanya mengembalikan item dengan `updatedAt > since`.
4. Flutter membandingkan `updatedAt` remote dan lokal.
5. Data yang `updatedAt`-nya lebih baru menang.
6. Jika `isDeleted = true`, data lokal ikut soft delete.

## Redirect Rule di Flutter

- Request pertama ke `/exec` selalu `POST`.
- Redirect `301`, `302`, `303` diikuti dengan `GET` ke header `location`.
- Redirect `307`, `308` menjaga method `POST` dan body JSON.
- Relative redirect URL harus di-resolve.
- Redirect maksimum 3 hop.

## Error Handling Rule di Flutter

Jika response akhir bukan JSON valid, error minimal harus memuat:

- nama tahap sync yang gagal,
- `statusCode`,
- `content-type`,
- `bodyPreview` maksimal 300 karakter.

Token tidak boleh pernah muncul di log atau pesan error.

## Response JSON Sukses Minimal

```json
{
  "status": "success",
  "message": "Push berhasil diproses.",
  "inserted": 1,
  "updated": 0,
  "failed": 0,
  "serverTime": "2026-07-09T10:00:00.000Z",
  "items": []
}
```

## Response JSON Error Minimal

```json
{
  "status": "error",
  "message": "Token tidak valid.",
  "code": "INVALID_TOKEN",
  "inserted": 0,
  "updated": 0,
  "failed": 1,
  "serverTime": "2026-07-09T10:00:00.000Z",
  "items": []
}
```
