import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/market_quote.dart';

class MarketDataApiService {
  MarketDataApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? _defaultBaseUrl).trim();

  static const String _defaultBaseUrl = String.fromEnvironment(
    'MARKET_BACKEND_BASE_URL',
    defaultValue: 'http://127.0.0.1:5000',
  );

  final http.Client _client;
  final String _baseUrl;

  Future<Map<String, MarketQuote>> getQuotes(List<String> symbols) async {
    final List<String> normalizedSymbols = symbols
        .map((String symbol) => symbol.trim().toUpperCase())
        .where((String symbol) => symbol.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (normalizedSymbols.isEmpty || _baseUrl.isEmpty) {
      return const <String, MarketQuote>{};
    }

    final Uri uri = Uri.parse('$_baseUrl/api/market/quotes');
    try {
      final http.Response response = await _client.post(
        uri,
        headers: const <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{'symbols': normalizedSymbols}),
      );

      if (response.statusCode != 200) {
        return const <String, MarketQuote>{};
      }

      final Map<String, dynamic> payload =
          jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> rawData =
          payload['data'] as List<dynamic>? ?? <dynamic>[];
      final Iterable<MarketQuote> quotes = rawData
          .whereType<Map<String, dynamic>>()
          .map(MarketQuote.fromJson);

      return <String, MarketQuote>{
        for (final MarketQuote quote in quotes) quote.symbol: quote,
      };
    } catch (_) {
      return const <String, MarketQuote>{};
    }
  }
}
