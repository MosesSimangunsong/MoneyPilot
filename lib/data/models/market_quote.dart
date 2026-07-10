class MarketQuote {
  const MarketQuote({
    required this.symbol,
    required this.displaySymbol,
    required this.price,
    required this.currency,
    required this.source,
    required this.provider,
    required this.isMock,
    required this.isFallback,
    required this.asOf,
    required this.cachedAt,
    required this.cacheTtlSeconds,
    required this.message,
    required this.isStale,
  });

  factory MarketQuote.fromJson(Map<String, dynamic> json) {
    return MarketQuote(
      symbol: json['symbol'] as String? ?? '',
      displaySymbol: json['displaySymbol'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'IDR',
      source: json['source'] as String? ?? 'unknown',
      provider: json['provider'] as String? ?? '',
      isMock: json['isMock'] as bool? ?? false,
      isFallback: json['isFallback'] as bool? ?? false,
      asOf: DateTime.tryParse(json['asOf'] as String? ?? '')?.toUtc(),
      cachedAt: DateTime.tryParse(json['cachedAt'] as String? ?? '')?.toUtc(),
      cacheTtlSeconds: json['cacheTtlSeconds'] as int? ?? 0,
      message:
          json['message'] as String? ??
          'Data pasar bersifat estimasi dan bukan rekomendasi investasi.',
      isStale: json['isStale'] as bool? ?? false,
    );
  }

  final String symbol;
  final String displaySymbol;
  final double price;
  final String currency;
  final String source;
  final String provider;
  final bool isMock;
  final bool isFallback;
  final DateTime? asOf;
  final DateTime? cachedAt;
  final int cacheTtlSeconds;
  final String message;
  final bool isStale;

  String get effectiveDisplaySymbol =>
      displaySymbol.isNotEmpty ? displaySymbol : symbol.replaceAll('.JK', '');

  String get sourceLabel {
    if (source.toLowerCase() == 'mock') {
      return 'Mock data';
    }
    if (provider.isNotEmpty) {
      return provider;
    }
    return source.toUpperCase();
  }
}
