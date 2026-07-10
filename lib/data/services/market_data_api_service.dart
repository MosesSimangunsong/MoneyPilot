import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_constants.dart';
import '../../core/utils/market_symbol_utils.dart';
import '../models/market_quote.dart';

class MarketDataApiService {
  MarketDataApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? _defaultBaseUrl).trim();

  static const String _defaultBaseUrl = String.fromEnvironment(
    'MARKET_BACKEND_BASE_URL',
    defaultValue: ApiConstants.defaultBackendBaseUrl,
  );

  final http.Client _client;
  final String _baseUrl;

  Future<MarketQuoteResponse> getQuoteResult(String symbol) async {
    final String normalizedSymbol = normalizeMarketSymbolForBackend(symbol);
    if (normalizedSymbol.isEmpty || _baseUrl.isEmpty) {
      return const MarketQuoteResponse(quote: null, backendReachable: false);
    }

    final Uri uri = Uri.parse('$_baseUrl/api/market/quote/$normalizedSymbol');
    try {
      final http.Response response = await _client.get(uri);
      final Map<String, dynamic> payload =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        return MarketQuoteResponse(
          quote: null,
          backendReachable: true,
          message: payload['message'] as String?,
          errorCode:
              (payload['error'] as Map<String, dynamic>?)?['code'] as String?,
        );
      }

      final Map<String, dynamic>? data =
          payload['data'] as Map<String, dynamic>?;
      if (data == null) {
        return const MarketQuoteResponse(quote: null, backendReachable: true);
      }

      return MarketQuoteResponse(
        quote: MarketQuote.fromJson(data),
        backendReachable: true,
      );
    } catch (_) {
      return const MarketQuoteResponse(quote: null, backendReachable: false);
    }
  }

  Future<MarketQuote?> getQuote(String symbol) async {
    final MarketQuoteResponse response = await getQuoteResult(symbol);
    return response.quote;
  }

  Future<MarketQuotesResponse> getQuotesResult(List<String> symbols) async {
    final List<String> normalizedSymbols = symbols
        .map(normalizeMarketSymbolForBackend)
        .where((String symbol) => symbol.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (normalizedSymbols.isEmpty || _baseUrl.isEmpty) {
      return const MarketQuotesResponse(
        quotes: <String, MarketQuote>{},
        backendReachable: false,
      );
    }

    final Uri uri = Uri.parse('$_baseUrl/api/market/quotes');
    try {
      final http.Response response = await _client.post(
        uri,
        headers: const <String, String>{'Content-Type': 'application/json'},
        body: jsonEncode(<String, dynamic>{'symbols': normalizedSymbols}),
      );

      final Map<String, dynamic> payload =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        return MarketQuotesResponse(
          quotes: const <String, MarketQuote>{},
          backendReachable: true,
          message: payload['message'] as String?,
          errors: _parseTopLevelError(payload),
        );
      }

      final Object? rawData = payload['data'];
      final List<dynamic> rawQuotes;
      final List<Map<String, dynamic>> parsedErrors;

      if (rawData is Map<String, dynamic>) {
        rawQuotes = rawData['quotes'] as List<dynamic>? ?? <dynamic>[];
        parsedErrors = (rawData['errors'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
      } else if (rawData is List<dynamic>) {
        rawQuotes = rawData;
        parsedErrors = const <Map<String, dynamic>>[];
      } else {
        rawQuotes = const <dynamic>[];
        parsedErrors = const <Map<String, dynamic>>[];
      }

      final Iterable<MarketQuote> quotes = rawQuotes
          .whereType<Map<String, dynamic>>()
          .map(MarketQuote.fromJson);

      return MarketQuotesResponse(
        quotes: <String, MarketQuote>{
          for (final MarketQuote quote in quotes) quote.symbol: quote,
        },
        backendReachable: true,
        errors: parsedErrors,
        message: payload['message'] as String?,
      );
    } catch (_) {
      return const MarketQuotesResponse(
        quotes: <String, MarketQuote>{},
        backendReachable: false,
      );
    }
  }

  Future<Map<String, MarketQuote>> getQuotes(List<String> symbols) async {
    final MarketQuotesResponse response = await getQuotesResult(symbols);
    return response.quotes;
  }

  List<Map<String, dynamic>> _parseTopLevelError(Map<String, dynamic> payload) {
    final Map<String, dynamic>? error =
        payload['error'] as Map<String, dynamic>?;
    if (error == null) {
      return const <Map<String, dynamic>>[];
    }
    return <Map<String, dynamic>>[error];
  }
}

class MarketQuoteResponse {
  const MarketQuoteResponse({
    required this.quote,
    required this.backendReachable,
    this.message,
    this.errorCode,
  });

  final MarketQuote? quote;
  final bool backendReachable;
  final String? message;
  final String? errorCode;
}

class MarketQuotesResponse {
  const MarketQuotesResponse({
    required this.quotes,
    required this.backendReachable,
    this.message,
    this.errors = const <Map<String, dynamic>>[],
  });

  final Map<String, MarketQuote> quotes;
  final bool backendReachable;
  final String? message;
  final List<Map<String, dynamic>> errors;

  bool get hasProviderErrors => errors.isNotEmpty;
}
