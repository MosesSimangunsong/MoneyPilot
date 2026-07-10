String normalizeMarketSymbolForBackend(String symbol, {String market = 'IDX'}) {
  final String normalizedSymbol = symbol.trim().toUpperCase();
  final String normalizedMarket = market.trim().toUpperCase();
  if (normalizedSymbol.isEmpty) {
    return normalizedSymbol;
  }
  if (normalizedSymbol.contains('.')) {
    return normalizedSymbol;
  }
  if (normalizedMarket == 'IDX') {
    return '$normalizedSymbol.JK';
  }
  return normalizedSymbol;
}

String displayMarketSymbol(String symbol) {
  final String normalizedSymbol = normalizeMarketSymbolForBackend(symbol);
  if (normalizedSymbol.endsWith('.JK')) {
    return normalizedSymbol.substring(0, normalizedSymbol.length - 3);
  }
  return normalizedSymbol;
}
