# Spreadsheet Sync Payload Examples — MoneyPilot

## Push Transactions Request

```json
{
  "token": "DEV_SECRET",
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
Pull Transactions Request
{
  "token": "DEV_SECRET",
  "operation": "pull",
  "entity": "Transactions",
  "since": "2026-07-09T00:00:00.000Z"
}
Push Categories Request
{
  "token": "DEV_SECRET",
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
      "isDeleted": false,
      "createdAt": "2026-07-09T03:00:00.000Z",
      "updatedAt": "2026-07-09T03:00:00.000Z",
      "deletedAt": ""
    }
  ]
}
Success Response
{
  "status": "success",
  "inserted": 1,
  "updated": 0,
  "failed": 0,
  "serverTime": "2026-07-09T10:00:00.000Z",
  "items": []
}
Pull Success Response
{
  "status": "success",
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
Error Response
{
  "status": "error",
  "message": "Token tidak valid.",
  "code": "INVALID_TOKEN"
}