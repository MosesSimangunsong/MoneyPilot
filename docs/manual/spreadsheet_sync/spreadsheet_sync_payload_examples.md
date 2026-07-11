# Spreadsheet Sync Payload Examples - MoneyPilot

## Push Categories Request

```json
{
  "token": "SECRET_TOKEN",
  "operation": "push",
  "entity": "Categories",
  "items": [
    {
      "uuid": "cat-food",
      "name": "Makanan & Minuman",
      "type": "expense",
      "icon": "utensils",
      "colorHex": "#2563EB",
      "isDefault": true,
      "syncStatus": "pending",
      "syncErrorMessage": "",
      "isDeleted": false,
      "createdAt": "2026-07-09T03:00:00.000Z",
      "updatedAt": "2026-07-09T03:00:00.000Z",
      "deletedAt": ""
    }
  ]
}
```

## Push Transactions Request

```json
{
  "token": "SECRET_TOKEN",
  "operation": "push",
  "entity": "Transactions",
  "items": [
    {
      "uuid": "tx-001",
      "type": "expense",
      "title": "Beli kopi",
      "amount": 15000,
      "categoryUuid": "cat-food",
      "categoryNameSnapshot": "Makanan & Minuman",
      "paymentMethod": "QRIS",
      "note": "",
      "source": "manual",
      "syncStatus": "pending",
      "syncErrorMessage": "",
      "isDeleted": false,
      "transactionDate": "2026-07-09T03:00:00.000Z",
      "createdAt": "2026-07-09T03:00:00.000Z",
      "updatedAt": "2026-07-09T03:00:00.000Z",
      "deletedAt": ""
    }
  ]
}
```

## Pull Transactions Request

```json
{
  "token": "SECRET_TOKEN",
  "operation": "pull",
  "entity": "Transactions",
  "since": "2026-07-09T00:00:00.000Z"
}
```

## Pull Transactions Request Tanpa Since

```json
{
  "token": "SECRET_TOKEN",
  "operation": "pull",
  "entity": "Transactions"
}
```

## Success Response

```json
{
  "status": "success",
  "message": "Pull berhasil diproses.",
  "inserted": 0,
  "updated": 0,
  "failed": 0,
  "serverTime": "2026-07-09T10:00:00.000Z",
  "items": []
}
```

## Success Response dengan Data

```json
{
  "status": "success",
  "message": "Pull berhasil diproses.",
  "inserted": 0,
  "updated": 0,
  "failed": 0,
  "serverTime": "2026-07-09T10:00:00.000Z",
  "items": [
    {
      "uuid": "tx-001",
      "type": "expense",
      "title": "Beli kopi",
      "amount": 15000,
      "categoryUuid": "cat-food",
      "categoryNameSnapshot": "Makanan & Minuman",
      "paymentMethod": "QRIS",
      "note": "",
      "source": "manual",
      "syncStatus": "synced",
      "syncErrorMessage": "",
      "isDeleted": false,
      "transactionDate": "2026-07-09T03:00:00.000Z",
      "createdAt": "2026-07-09T03:00:00.000Z",
      "updatedAt": "2026-07-09T03:00:00.000Z",
      "deletedAt": ""
    }
  ]
}
```

## Error Response

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

## Catatan Implementasi Flutter

- Request pertama ke `/exec` dikirim sebagai `POST`.
- Jika Google mengembalikan redirect saat sync, Flutter menjaga `POST` dan body JSON yang sama sampai menerima response akhir.
