# Google Apps Script Code - MoneyPilot

Salin seluruh kode berikut ke editor Google Apps Script, lalu deploy sebagai Web App. Kode ini sudah siap untuk health check `GET` dan sync manual `POST` dari MoneyPilot.

```javascript
const SHEET_NAMES = {
  Categories: 'Categories',
  Transactions: 'Transactions',
  Stock_Transactions: 'Stock_Transactions',
  Dividends: 'Dividends',
  Watchlist: 'Watchlist',
};

const REQUIRED_COLUMNS = {
  uuid: 'uuid',
  updatedAt: 'updatedAt',
};

const SCRIPT_PROPERTIES = PropertiesService.getScriptProperties();
const TOKEN_PROPERTY_KEY = 'MONEYPILOT_SYNC_TOKEN';

function doGet() {
  return jsonSuccess({
    message: 'MoneyPilot Sync API aktif',
  });
}

function doPost(e) {
  try {
    const body = parseRequestBody(e);
    validateToken(body.token);

    const operation = normalizeString(body.operation);
    if (operation === 'push') {
      return handlePush(body);
    }

    if (operation === 'pull') {
      return handlePull(body);
    }

    throw createError('Operation tidak dikenal.', 'INVALID_OPERATION');
  } catch (error) {
    return jsonError(
      error.message || 'Terjadi error pada Google Apps Script.',
      error.code || 'SCRIPT_ERROR',
    );
  }
}

function handlePush(body) {
  const entity = normalizeString(body.entity);
  const sheet = requireEntitySheet(entity);
  const headers = getHeaders(sheet);
  const uuidIndex = getRequiredHeaderIndex(headers, REQUIRED_COLUMNS.uuid);
  getRequiredHeaderIndex(headers, REQUIRED_COLUMNS.updatedAt);

  const items = ensureItemsArray(body.items);
  const uuidRowMap = buildUuidRowMap(sheet, uuidIndex);

  let inserted = 0;
  let updated = 0;

  items.forEach((item) => {
    const uuid = normalizeString(item.uuid);
    if (!uuid) {
      throw createError('Field uuid wajib diisi pada setiap item.', 'INVALID_UUID');
    }

    validateUpdatedAtField(item.updatedAt);

    const rowValues = buildRowValues(headers, item);
    const existingRow = uuidRowMap[uuid];

    if (existingRow) {
      sheet.getRange(existingRow, 1, 1, headers.length).setValues([rowValues]);
      updated += 1;
      return;
    }

    const targetRow = Math.max(sheet.getLastRow(), 1) + 1;
    sheet.getRange(targetRow, 1, 1, headers.length).setValues([rowValues]);
    uuidRowMap[uuid] = targetRow;
    inserted += 1;
  });

  return jsonSuccess({
    message: 'Push berhasil diproses.',
    inserted: inserted,
    updated: updated,
    failed: 0,
    items: [],
  });
}

function handlePull(body) {
  const entity = normalizeString(body.entity);
  const sheet = requireEntitySheet(entity);
  const headers = getHeaders(sheet);
  getRequiredHeaderIndex(headers, REQUIRED_COLUMNS.uuid);
  getRequiredHeaderIndex(headers, REQUIRED_COLUMNS.updatedAt);

  const since = parseSince(body.since);
  const lastRow = sheet.getLastRow();

  if (lastRow <= 1) {
    return jsonSuccess({
      message: 'Tidak ada data untuk ditarik.',
      inserted: 0,
      updated: 0,
      failed: 0,
      items: [],
    });
  }

  const rows = sheet.getRange(2, 1, lastRow - 1, headers.length).getValues();
  const items = rows
    .map((row) => mapRowToObject(headers, row))
    .filter((item) => {
      const updatedAt = parseIsoDate(item.updatedAt, false);
      if (!updatedAt) {
        return false;
      }

      if (!since) {
        return true;
      }

      return updatedAt.getTime() > since.getTime();
    });

  return jsonSuccess({
    message: 'Pull berhasil diproses.',
    inserted: 0,
    updated: 0,
    failed: 0,
    items: items,
  });
}

function requireEntitySheet(entity) {
  const sheetName = SHEET_NAMES[entity];
  if (!sheetName) {
    throw createError('Entity tidak dikenal.', 'UNKNOWN_ENTITY');
  }

  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName(sheetName);
  if (!sheet) {
    throw createError(`Sheet ${sheetName} tidak ditemukan.`, 'SHEET_NOT_FOUND');
  }

  return sheet;
}

function getHeaders(sheet) {
  const lastColumn = sheet.getLastColumn();
  if (sheet.getLastRow() < 1 || lastColumn < 1) {
    throw createError('Header row pertama belum tersedia.', 'MISSING_HEADERS');
  }

  const headers = sheet
    .getRange(1, 1, 1, lastColumn)
    .getValues()[0]
    .map((value) => normalizeString(value));

  if (headers.every((header) => !header)) {
    throw createError('Header sheet kosong.', 'MISSING_HEADERS');
  }

  return headers;
}

function getRequiredHeaderIndex(headers, headerName) {
  const index = headers.indexOf(headerName);
  if (index === -1) {
    throw createError(`Header ${headerName} tidak ditemukan.`, 'HEADER_NOT_FOUND');
  }

  return index;
}

function buildUuidRowMap(sheet, uuidIndex) {
  const lastRow = sheet.getLastRow();
  const lastColumn = sheet.getLastColumn();
  if (lastRow <= 1 || lastColumn <= 0) {
    return {};
  }

  const rows = sheet.getRange(2, 1, lastRow - 1, lastColumn).getValues();
  const map = {};

  rows.forEach((row, rowOffset) => {
    const uuid = normalizeString(row[uuidIndex]);
    if (!uuid) {
      return;
    }

    map[uuid] = rowOffset + 2;
  });

  return map;
}

function buildRowValues(headers, item) {
  return headers.map((header) => normalizeOutgoingCellValue(item[header]));
}

function mapRowToObject(headers, row) {
  return headers.reduce((result, header, index) => {
    result[header] = normalizeIncomingCellValue(row[index]);
    return result;
  }, {});
}

function ensureItemsArray(items) {
  if (!Array.isArray(items)) {
    throw createError('Field items wajib berupa array.', 'INVALID_ITEMS');
  }

  return items;
}

function parseRequestBody(e) {
  const rawBody = e && e.postData && e.postData.contents;
  if (!rawBody) {
    throw createError('Request body kosong.', 'EMPTY_BODY');
  }

  try {
    const parsed = JSON.parse(rawBody);
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
      throw new Error('JSON body harus berupa object.');
    }
    return parsed;
  } catch (error) {
    throw createError('Request body bukan JSON valid.', 'INVALID_JSON');
  }
}

function validateToken(token) {
  const expectedToken = normalizeString(
    SCRIPT_PROPERTIES.getProperty(TOKEN_PROPERTY_KEY),
  );

  if (!expectedToken) {
    throw createError(
      'Script property MONEYPILOT_SYNC_TOKEN belum diatur.',
      'TOKEN_NOT_CONFIGURED',
    );
  }

  if (normalizeString(token) !== expectedToken) {
    throw createError('Token tidak valid.', 'INVALID_TOKEN');
  }
}

function parseSince(value) {
  const normalized = normalizeString(value);
  if (!normalized) {
    return null;
  }

  return parseIsoDate(normalized, true);
}

function validateUpdatedAtField(value) {
  const normalized = normalizeString(value);
  if (!normalized) {
    throw createError('Field updatedAt wajib diisi.', 'MISSING_UPDATED_AT');
  }

  parseIsoDate(normalized, true);
}

function parseIsoDate(value, required) {
  const normalized = normalizeString(value);
  if (!normalized) {
    if (required) {
      throw createError('Timestamp ISO 8601 wajib diisi.', 'INVALID_TIMESTAMP');
    }
    return null;
  }

  const parsed = new Date(normalized);
  if (Number.isNaN(parsed.getTime())) {
    throw createError('Timestamp ISO 8601 tidak valid.', 'INVALID_TIMESTAMP');
  }

  return parsed;
}

function normalizeOutgoingCellValue(value) {
  if (value === null || value === undefined) {
    return '';
  }

  if (value instanceof Date) {
    return value.toISOString();
  }

  if (typeof value === 'boolean' || typeof value === 'number') {
    return value;
  }

  return String(value).trim();
}

function normalizeIncomingCellValue(value) {
  if (value === null || value === undefined) {
    return '';
  }

  if (value instanceof Date) {
    return value.toISOString();
  }

  if (typeof value === 'boolean' || typeof value === 'number') {
    return value;
  }

  return String(value).trim();
}

function normalizeString(value) {
  if (value === null || value === undefined) {
    return '';
  }

  return String(value).trim();
}

function createError(message, code) {
  const error = new Error(message);
  error.code = code;
  return error;
}

function jsonSuccess(data) {
  return jsonOutput({
    status: 'success',
    message: data.message || '',
    inserted: toIntOrZero(data.inserted),
    updated: toIntOrZero(data.updated),
    failed: toIntOrZero(data.failed),
    serverTime: new Date().toISOString(),
    items: Array.isArray(data.items) ? data.items : [],
  });
}

function jsonError(message, code) {
  return jsonOutput({
    status: 'error',
    message: message,
    code: code,
    inserted: 0,
    updated: 0,
    failed: 1,
    serverTime: new Date().toISOString(),
    items: [],
  });
}

function jsonOutput(payload) {
  return ContentService
    .createTextOutput(JSON.stringify(payload))
    .setMimeType(ContentService.MimeType.JSON);
}

function toIntOrZero(value) {
  return typeof value === 'number' && !Number.isNaN(value) ? value : 0;
}
```

## Deploy Ulang

1. Buka Google Apps Script editor.
2. Paste seluruh kode final di atas.
3. Pastikan Script Property `MONEYPILOT_SYNC_TOKEN` sudah ada.
4. Klik `Deploy` → `Manage deployments` → `Edit` → `New version` → `Deploy`.
5. Copy Web App URL yang berakhiran `/exec`.
6. Masukkan Web App URL dan Secret Token di Settings MoneyPilot.
7. Klik `Simpan Konfigurasi`.
8. Setelah itu baru klik `Jalankan Sync Manual`.
