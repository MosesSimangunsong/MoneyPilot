# MoneyPilot Backend

Backend ini menyediakan data market, feed berita ekonomi, analisis dampak
berita berbasis AI, dan cache lokal. Backend tidak menyimpan transaksi,
dividen, atau data keuangan pribadi user.

## Fitur Tahap 9

- Flask app factory
- SQLite cache untuk quote market
- SQLite cache untuk feed berita dan hasil analisis berita
- Mock provider untuk saham Indonesia
- Google News RSS service dengan fallback development
- AI analysis service provider-agnostic
- Endpoint health check
- Endpoint quote tunggal dan batch quote
- Endpoint daftar berita, detail berita sederhana, dan analisis berita
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
- `NEWS_PROVIDER`: default `google_news_rss`
- `NEWS_CACHE_TTL_SECONDS`: TTL cache daftar berita, default `900`
- `ANALYSIS_CACHE_TTL_SECONDS`: TTL cache analisis, default `86400`
- `AI_PROVIDER`: default `openai`
- `OPENAI_API_KEY`: API key OpenAI, boleh kosong saat development
- `AI_MODEL`: model OpenAI, default internal backend `gpt-4.1-mini`
- `ENABLE_DEV_ANALYSIS_FALLBACK`: `1` untuk mengaktifkan fallback mock analysis
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

### `GET /api/news`

Query params opsional:

- `category`
- `q`
- `limit`

Contoh response:

```json
{
  "status": "success",
  "data": [
    {
      "id": "4df7f43f3d6b7df0",
      "title": "Investor menanti arah suku bunga dan dampaknya ke rupiah",
      "summary": "Pelaku pasar menilai perubahan arah suku bunga global dapat memengaruhi arus modal.",
      "source": "Google News",
      "url": "https://news.google.com/...",
      "category": "Suku Bunga",
      "publishedAt": "2026-07-09T10:00:00Z"
    }
  ],
  "serverTime": "2026-07-09T10:00:05Z"
}
```

### `GET /api/news/<id>`

Endpoint detail sederhana ini membaca berita yang sudah pernah masuk cache list.

### `POST /api/news/analyze`

Contoh request:

```json
{
  "newsId": "4df7f43f3d6b7df0",
  "title": "Ketidakpastian global membuat investor memantau emas",
  "summary": "Ketidakpastian global membuat pelaku pasar lebih berhati-hati.",
  "url": "https://example.com/news/emas",
  "category": "Geopolitik"
}
```

Contoh response:

```json
{
  "status": "success",
  "data": {
    "newsId": "4df7f43f3d6b7df0",
    "judul": "Ketidakpastian global membuat investor memantau emas",
    "ringkasan": "Ketidakpastian global membuat pelaku pasar lebih berhati-hati.",
    "kategori": "Geopolitik",
    "asetTerdampak": ["Emas", "USD/IDR", "IHSG"],
    "impactScore": 68,
    "confidenceScore": 58,
    "dampakPotensial": "Berita ini berpotensi memengaruhi sentimen pasar.",
    "rantaiSebabAkibat": ["..."],
    "dataPendukung": ["..."],
    "skenarioPositif": "...",
    "skenarioNegatif": "...",
    "halYangPerluDipantau": ["..."],
    "kesimpulanPemula": "...",
    "disclaimer": "Informasi ini bukan nasihat keuangan."
  },
  "serverTime": "2026-07-09T10:00:05Z"
}
```

Jika `OPENAI_API_KEY` kosong, backend tidak crash. Pada development atau test,
backend dapat mengembalikan fallback analysis yang tetap aman dan berbahasa
Indonesia.

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
- Analisis berita bersifat edukatif dan bukan rekomendasi beli atau jual.
