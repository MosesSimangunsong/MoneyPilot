# Spreadsheet Sync Rules — MoneyPilot

## Prinsip Utama

- Isar tetap menjadi sumber utama aplikasi.
- Google Spreadsheet berfungsi sebagai backup dan tempat edit ringan.
- Semua entity yang disync wajib memakai UUID.
- Operasi spreadsheet wajib upsert berdasarkan UUID.
- Jangan append row tanpa mengecek UUID.
- Delete memakai soft delete, bukan menghapus row permanen.
- Conflict resolution memakai latest updatedAt wins.
- Semua timestamp memakai UTC ISO 8601.

## Entity MVP yang Disync

1. Categories
2. Transactions
3. Stock_Transactions
4. Dividends
5. Watchlist

## Entity Lokal Saja

1. VoiceTranscript
2. SyncLog lokal Isar

## Push Flow

1. Ambil data lokal dengan syncStatus pending atau failed.
2. Kirim data ke Google Apps Script.
3. Google Apps Script validasi token.
4. Google Apps Script membaca header sheet.
5. Google Apps Script mencari row berdasarkan uuid.
6. Jika uuid ditemukan, update row.
7. Jika uuid tidak ditemukan, insert row baru.
8. Jika push sukses, ubah syncStatus lokal menjadi synced.
9. Jika push gagal, ubah syncStatus lokal menjadi failed dan simpan syncErrorMessage.

## Pull Flow

1. Aplikasi meminta data spreadsheet yang berubah sejak lastPulledAt.
2. Google Apps Script mengembalikan rows yang updatedAt lebih baru dari since.
3. Untuk setiap item:
   - Jika uuid belum ada di lokal, insert.
   - Jika uuid sudah ada di lokal, bandingkan updatedAt.
   - Data dengan updatedAt terbaru menang.
4. Jika item isDeleted true, data lokal ikut soft delete.
5. Jika pull sukses, update lastPulledAt.

## Conflict Rule

Jika data lokal dan spreadsheet sama-sama berubah:

1. Bandingkan updatedAt UTC.
2. Data dengan updatedAt terbaru menang.
3. Jangan membuat duplikat row.
4. Jangan overwrite data yang lebih baru dengan data lama.

## Soft Delete Rule

- Delete dari aplikasi mengubah isDeleted menjadi true.
- deletedAt wajib terisi UTC ISO 8601.
- Row spreadsheet tetap ada.
- Pull data dengan isDeleted true akan membuat data lokal ikut soft delete.

## Google Apps Script Rule

Apps Script wajib:

1. Menerima request JSON.
2. Validasi token.
3. Membaca sheet berdasarkan entity.
4. Membaca header dari row pertama.
5. Mencari kolom uuid.
6. Melakukan upsert berdasarkan uuid.
7. Mengembalikan response JSON konsisten.

## Response Sukses Minimal

```json
{
  "status": "success",
  "inserted": 1,
  "updated": 0,
  "failed": 0,
  "serverTime": "2026-07-09T10:00:00.000Z",
  "items": []
}

## Response Error Minimal
{
  "status": "error",
  "message": "Token tidak valid.",
  "code": "INVALID_TOKEN"
}