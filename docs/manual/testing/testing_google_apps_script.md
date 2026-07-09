# Manual Testing Google Apps Script — MoneyPilot

## Health Check

- [ ] Buka Web App URL di browser.
- [ ] Response JSON muncul.
- [ ] status = success.
- [ ] serverTime muncul.

## Token Validation

- [ ] Request tanpa token ditolak.
- [ ] Request dengan token salah ditolak.
- [ ] Request dengan token benar diterima.

## Push Operation

- [ ] Push ke entity Transactions berhasil.
- [ ] Jika uuid belum ada, row baru dibuat.
- [ ] Jika uuid sudah ada, row lama diupdate.
- [ ] Header tetap berada di row pertama.
- [ ] Tidak ada duplicate uuid.

## Pull Operation

- [ ] Pull entity Transactions berhasil.
- [ ] Parameter since bekerja.
- [ ] Hanya data dengan updatedAt lebih baru yang dikembalikan.
- [ ] Response selalu JSON valid.

## Error Handling

- [ ] Entity tidak dikenal mengembalikan error.
- [ ] Sheet tidak ditemukan mengembalikan error.
- [ ] Header uuid tidak ditemukan mengembalikan error.