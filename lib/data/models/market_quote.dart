class MarketQuote {
  const MarketQuote({
    required this.symbol,
    required this.price,
    required this.currency,
    required this.source,
    required this.asOf,
    required this.isStale,
  });

  factory MarketQuote.fromJson(Map<String, dynamic> json) {
    return MarketQuote(
      symbol: json['symbol'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'IDR',
      source: json['source'] as String? ?? 'unknown',
      asOf: DateTime.tryParse(json['asOf'] as String? ?? '')?.toUtc(),
      isStale: json['isStale'] as bool? ?? false,
    );
  }

  final String symbol;
  final double price;
  final String currency;
  final String source;
  final DateTime? asOf;
  final bool isStale;
}
