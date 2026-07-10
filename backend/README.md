# MoneyPilot Backend

Backend ini hanya menyediakan data market dan cache lokal. Backend tidak
menyimpan transaksi, dividen, atau data keuangan pribadi user.

## Fitur Tahap 8

- Flask app factory
- SQLite cache untuk quote market
- Mock provider untuk saham Indonesia
- Endpoint health check
- Endpoint quote tunggal dan batch quote
- Error response JSON konsisten

## Setup

```powershell
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
```

## Menjalankan Backend

```powershell
cd backend
.venv\Scripts\activate
python run.py
```

Server default berjalan di `http://127.0.0.1:5000`.

## Menjalankan Test

```powershell
cd backend
.venv\Scripts\activate
pytest
```

## Environment Variables

Salin `.env.example` bila ingin mengatur environment sendiri.

- `BACKEND_HOST`: host Flask, default `127.0.0.1`
- `BACKEND_PORT`: port Flask, default `5000`
- `MARKET_DATA_PROVIDER`: saat ini gunakan `MOCK`
- `MARKET_CACHE_TTL_SECONDS`: TTL cache quote, default `900`
- `MARKET_CACHE_DB_PATH`: lokasi file SQLite cache
- `CORS_ORIGINS`: origin dev Flutter, default `*`

## Endpoint

### `GET /health`

Contoh response:

```json
{
  "status": "success",
  "message": "MoneyPilot backend is healthy",
  "serverTime": "2026-07-09T00:00:00Z"
}
```

### `GET /api/market/quote/<symbol>`

Contoh request:

```text
GET /api/market/quote/BBCA.JK
```

Contoh response:

```json
{
  "status": "success",
  "data": {
    "symbol": "BBCA.JK",
    "price": 9050.0,
    "currency": "IDR",
    "source": "mock",
    "asOf": "2026-07-09T00:00:00Z",
    "isStale": false
  }
}
```

### `POST /api/market/quotes`

Contoh request:

```json
{
  "symbols": ["BBCA.JK", "BMRI.JK"]
}
```

Contoh response:

```json
{
  "status": "success",
  "data": [
    {
      "symbol": "BBCA.JK",
      "price": 9050.0,
      "currency": "IDR",
      "source": "mock",
      "asOf": "2026-07-09T00:00:00Z",
      "isStale": false
    },
    {
      "symbol": "BMRI.JK",
      "price": 6325.0,
      "currency": "IDR",
      "source": "mock",
      "asOf": "2026-07-09T00:00:00Z",
      "isStale": false
    }
  ]
}
```

## Mock Market Data

Tahap 8 masih memakai mock provider yang stabil untuk:

- `BBCA.JK`
- `BMRI.JK`
- `BBRI.JK`
- `TLKM.JK`
- `ASII.JK`

Struktur servicenya sudah disiapkan agar nanti mudah diganti ke provider asli
tanpa mengubah kontrak endpoint.

## Catatan Privasi

- Backend tidak menyimpan transaksi user.
- Backend tidak menyimpan dividen user.
- Backend tidak menerima upload data keuangan pribadi dari Flutter.
- Data market saat ini bersifat estimasi mock dan bukan rekomendasi investasi.
