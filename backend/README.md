# MoneyPilot Backend

Backend ini menyediakan quote market, feed berita ekonomi, analisis dampak
berita, dan cache lokal. Backend tidak menyimpan transaksi, dividen, nominal
modal, holding portofolio, atau data keuangan pribadi user.

## Fokus Tahap 15

- Provider architecture untuk market data
- Provider `mock` yang stabil untuk demo
- Provider eksternal opsional `eodhd`
- Fallback aman ke mock jika provider eksternal gagal
- Cache quote berbasis symbol yang sudah dinormalisasi
- Timeout dan error JSON yang rapi
- Metadata quote yang jujur untuk Flutter

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

## Integrasi Dengan Flutter

Flutter membaca base URL backend melalui compile-time environment:

- `BACKEND_BASE_URL` untuk endpoint berita dan analisis berita
- `MARKET_BACKEND_BASE_URL` untuk endpoint market

Contoh:

```powershell
flutter run --dart-define=BACKEND_BASE_URL=http://127.0.0.1:5000 --dart-define=MARKET_BACKEND_BASE_URL=http://127.0.0.1:5000
```

Panduan base URL:

- Desktop lokal: `http://127.0.0.1:5000`
- Android emulator: `http://10.0.2.2:5000`
- HP fisik satu jaringan: `http://IP_LAN_KOMPUTER:5000`

Contoh HP fisik:

```powershell
python run.py
flutter run --dart-define=BACKEND_BASE_URL=http://192.168.1.10:5000 --dart-define=MARKET_BACKEND_BASE_URL=http://192.168.1.10:5000
```

Jika ingin diakses dari HP fisik, set `BACKEND_HOST=0.0.0.0` dan batasi
`CORS_ORIGINS` sesuai kebutuhan development.

## Environment Variables

Salin `backend/.env.example` ke `backend/.env` bila perlu.

- `MARKET_DATA_PROVIDER=mock`
  Backend selalu memakai mock provider.
- `MARKET_DATA_PROVIDER=eodhd`
  Backend mencoba provider eksternal EODHD.
- `MARKET_DATA_API_KEY`
  API key provider eksternal. Hanya boleh disimpan di backend.
- `MARKET_DATA_BASE_URL`
  Base URL provider eksternal. Default `https://eodhd.com/api/real-time`.
- `MARKET_CACHE_TTL_SECONDS`
  TTL cache quote dalam detik. Default `900`.
- `MARKET_REQUEST_TIMEOUT_SECONDS`
  Timeout request provider eksternal dalam detik. Default `8`.
- `ENABLE_MARKET_MOCK_FALLBACK=true`
  Jika provider eksternal gagal, backend fallback ke mock.

## Provider Yang Tersedia

- `mock`
  Provider lokal stabil untuk `BBCA.JK`, `BMRI.JK`, `BBRI.JK`, `TLKM.JK`,
  dan `ASII.JK`.
- `eodhd`
  Provider eksternal opsional yang hanya aktif jika
  `MARKET_DATA_PROVIDER=eodhd` dan `MARKET_DATA_API_KEY` tersedia.

## Aturan Privasi dan Keamanan

- Flutter hanya mengirim symbol saham seperti `BBCA` atau `BBCA.JK`.
- Flutter tidak mengirim transaksi user ke backend.
- Flutter tidak mengirim nominal modal, holding detail, atau data keuangan
  pribadi ke backend.
- API key provider market tidak pernah dikirim ke Flutter.
- Jangan commit file `.env` yang berisi secret.

## Normalisasi Symbol

- Input `BBCA` akan dinormalisasi menjadi `BBCA.JK`.
- Input `BBCA.JK` tetap dipakai sebagai `BBCA.JK`.
- Field `displaySymbol` tetap menampilkan `BBCA` untuk UI Flutter.

## Cache dan Fallback

- Cache key selalu memakai symbol yang sudah dinormalisasi.
- Cache valid akan langsung dipakai tanpa memanggil provider lagi.
- Jika cache expired dan provider utama gagal, backend akan mencoba:
  1. stale cache jika tersedia
  2. mock fallback jika diaktifkan
- Cache hanya menyimpan quote market dan metadata quote, tanpa data user.

## Error Handling

Jika provider market gagal dan fallback dimatikan:

```json
{
  "status": "error",
  "error": {
    "code": "MARKET_PROVIDER_UNAVAILABLE",
    "statusCode": 503
  },
  "message": "Data pasar belum tersedia. Coba lagi nanti."
}
```

## Endpoint

### `GET /health`

```json
{
  "status": "success",
  "message": "MoneyPilot backend is healthy",
  "serverTime": "2026-07-10T00:00:00Z"
}
```

### `GET /api/market/quote/<symbol>`

Contoh response:

```json
{
  "status": "success",
  "data": {
    "symbol": "BBCA.JK",
    "displaySymbol": "BBCA",
    "price": 9050.0,
    "currency": "IDR",
    "source": "mock",
    "provider": "MockMarketDataProvider",
    "isMock": true,
    "isFallback": false,
    "isStale": false,
    "asOf": "2026-07-10T00:00:00Z",
    "cachedAt": "2026-07-10T00:00:03Z",
    "cacheTtlSeconds": 900,
    "message": "Data pasar bersifat estimasi dan bukan rekomendasi investasi."
  }
}
```

### `POST /api/market/quotes`

Contoh request:

```json
{
  "symbols": ["BBCA", "BMRI.JK"]
}
```

Contoh response:

```json
{
  "status": "success",
  "data": {
    "quotes": [
      {
        "symbol": "BBCA.JK",
        "displaySymbol": "BBCA",
        "price": 9050.0,
        "currency": "IDR",
        "source": "mock",
        "provider": "MockMarketDataProvider",
        "isMock": true,
        "isFallback": false,
        "isStale": false,
        "asOf": "2026-07-10T00:00:00Z",
        "cachedAt": "2026-07-10T00:00:03Z",
        "cacheTtlSeconds": 900,
        "message": "Data pasar bersifat estimasi dan bukan rekomendasi investasi."
      }
    ],
    "errors": [],
    "count": 1
  }
}
```

## Catatan Demo

- Data market bersifat estimasi.
- Tidak ada rekomendasi beli atau jual.
- Aplikasi ini bukan aplikasi trading dan tidak memiliki broker integration.
