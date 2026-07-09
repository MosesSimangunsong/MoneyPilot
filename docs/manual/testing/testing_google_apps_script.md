# Manual Testing Google Apps Script - MoneyPilot

## Health Check

- [ ] Buka Web App URL `/exec` di browser.
- [ ] Pastikan response berupa JSON.
- [ ] Pastikan `status = success`.
- [ ] Pastikan `serverTime` muncul.

## Test POST Manual

- [ ] Jalankan `POST` manual ke URL `/exec`.
- [ ] Gunakan `operation = pull`.
- [ ] Gunakan token yang benar.
- [ ] Pastikan response JSON valid.
- [ ] Pastikan `items` kosong atau array data, bukan HTML.

Contoh payload:

```json
{
  "token": "SECRET_TOKEN",
  "operation": "pull",
  "entity": "Transactions",
  "since": ""
}
```

## Token Validation

- [ ] Request tanpa token ditolak.
- [ ] Request dengan token salah ditolak.
- [ ] Request dengan token benar diterima.

## Push Operation

- [ ] Push ke `Categories` berhasil.
- [ ] Push ke `Transactions` berhasil.
- [ ] Jika `uuid` belum ada, row baru dibuat.
- [ ] Jika `uuid` sudah ada, row lama di-update.
- [ ] Tidak ada duplicate `uuid`.

## Pull Operation

- [ ] Pull `Transactions` berhasil.
- [ ] Parameter `since` bekerja.
- [ ] Hanya item dengan `updatedAt` lebih baru yang dikembalikan.
- [ ] Response akhir selalu JSON valid.

## Error Handling

- [ ] Entity tidak dikenal mengembalikan JSON error.
- [ ] Sheet tidak ditemukan mengembalikan JSON error.
- [ ] Header `uuid` tidak ditemukan mengembalikan JSON error.
- [ ] Header `updatedAt` tidak ditemukan mengembalikan JSON error.

## Catatan

- Jika PowerShell `POST` manual berhasil, berarti Apps Script dan deployment biasanya sudah benar.
- Jika Flutter masih gagal setelah itu, fokus pengecekan berpindah ke redirect handling, konfigurasi URL/token, dan parsing response di Flutter.
