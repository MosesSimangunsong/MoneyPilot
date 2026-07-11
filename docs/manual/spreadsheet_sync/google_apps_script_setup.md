# Google Apps Script Setup - MoneyPilot

## Tujuan

Dokumen ini menjelaskan cara menyiapkan Google Apps Script untuk sync MoneyPilot sesuai sistem Flutter saat ini.

## Langkah Setup

1. Buka Google Spreadsheet yang akan dipakai.
2. Buka `Extensions` -> `Apps Script`.
3. Hapus kode lama jika masih berupa `doGet` health check sederhana saja.
4. Paste seluruh kode final dari [google_apps_script_code.md](/D:/Semester%207/PersonalApp/app/docs/manual/spreadsheet_sync/google_apps_script_code.md).
5. Buka `Project Settings`.
6. Tambahkan Script Property:

```text
MONEYPILOT_SYNC_TOKEN=ISI_TOKEN_RAHASIA_ANDA
```

7. Simpan perubahan.
8. Klik `Deploy` -> `Manage deployments`.
9. Pilih deployment Web App yang dipakai.
10. Klik `Edit` -> `New version` -> `Deploy`.
11. Copy URL Web App yang berakhiran `/exec`.

## Sheet yang Wajib Ada

1. `Categories`
2. `Transactions`
3. `Stock_Transactions`
4. `Dividends`
5. `Watchlist`

Header row pertama harus mengikuti [google_sheet_headers.md](/D:/Semester%207/PersonalApp/app/docs/manual/spreadsheet_sync/google_sheet_headers.md).

## Cara Memasang ke Flutter

1. Buka halaman `Settings` di MoneyPilot.
2. Isi `Google Apps Script Web App URL`.
3. Isi `Secret token`.
4. Klik `Simpan konfigurasi`.
5. Klik `Jalankan sync manual`.

## Catatan Redirect Google

Redirect `script.google.com` -> `script.googleusercontent.com` adalah perilaku normal dari Web App Google Apps Script.

Flutter MoneyPilot sekarang sudah menangani:

- redirect sync dengan preserve `POST` dan body JSON
- redirect health check dengan preserve `GET`

Jadi Anda tidak perlu mengubah Apps Script untuk urusan redirect tersebut.

## Health Check

Buka URL `/exec` di browser. Jika setup benar, Anda akan melihat JSON seperti:

```json
{
  "status": "success",
  "message": "MoneyPilot Sync API aktif"
}
```
