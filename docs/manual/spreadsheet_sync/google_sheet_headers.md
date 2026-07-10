# Google Sheet Headers - MoneyPilot

## Categories

```text
uuid,name,type,icon,colorHex,isDefault,syncStatus,syncErrorMessage,isDeleted,createdAt,updatedAt,deletedAt
```

## Transactions

```text
uuid,type,title,amount,categoryUuid,categoryNameSnapshot,paymentMethod,note,source,syncStatus,syncErrorMessage,isDeleted,transactionDate,createdAt,updatedAt,deletedAt
```

## Stock_Transactions

```text
uuid,symbol,companyName,actionType,lot,shares,price,fee,syncStatus,syncErrorMessage,isDeleted,transactionDate,note,createdAt,updatedAt,deletedAt
```

## Dividends

```text
uuid,symbol,companyName,grossAmount,tax,netAmount,receivedDate,linkedTransactionUuid,note,syncStatus,syncErrorMessage,isDeleted,createdAt,updatedAt,deletedAt
```

## Watchlist

```text
uuid,symbol,companyName,market,targetPrice,note,syncStatus,syncErrorMessage,isDeleted,createdAt,updatedAt,deletedAt
```

## Catatan

- Header wajib berada di row pertama.
- Kolom `uuid` wajib ada di setiap sheet entity.
- Semua timestamp wajib memakai UTC ISO 8601.
- Operasi `push` harus melakukan upsert berdasarkan `uuid`, bukan append buta.
- Flutter saat ini aktif sync dua arah untuk `Categories`, `Transactions`, `Stock_Transactions`, `Dividends`, dan `Watchlist`.
- Header setiap sheet harus konsisten dengan mapper Flutter agar UUID upsert, soft delete, dan conflict handling `updatedAt` berjalan aman.
