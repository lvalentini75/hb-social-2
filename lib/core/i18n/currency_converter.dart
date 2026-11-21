
class ExchangeRate {
  static final BigInt scale = BigInt.from(100000000);
  final String baseCode;
  final String quoteCode;
  final BigInt scaledRate;
  final DateTime validOn;

  const ExchangeRate({required this.baseCode, required this.quoteCode, required this.scaledRate, required this.validOn});

  factory ExchangeRate.fromJson(Map<String, dynamic> json) => ExchangeRate(
    baseCode: json['base_code'] as String,
    quoteCode: json['quote_code'] as String,
    scaledRate: _parseScaled(json['rate'].toString()),
    validOn: DateTime.parse(json['valid_on'] as String),
  );

  static BigInt _parseScaled(String value) {
    final parts = value.split('.');
    final whole = BigInt.parse(parts.first);
    final fraction = (parts.length > 1 ? parts[1] : '').padRight(8, '0').substring(0, 8);
    return whole * scale + BigInt.parse(fraction);
  }
}

/// Converts minor-unit amounts with fixed-point arithmetic and the newest rates.
class CurrencyConverter {
  final List<ExchangeRate> _rates;

  const CurrencyConverter(this._rates);

  int? convert({required int amountMinor, required String fromCode, required String toCode}) {
    if (fromCode == toCode) return amountMinor;
    final rates = {for (final rate in _rates) '${rate.baseCode}:${rate.quoteCode}': rate};
    final direct = _factor(rates, fromCode, toCode);
    if (direct != null) return _apply(amountMinor, direct);
    final toEur = _factor(rates, fromCode, 'EUR');
    final fromEur = _factor(rates, 'EUR', toCode);
    if (toEur == null || fromEur == null) return null;
    return _apply(_apply(amountMinor, toEur), fromEur);
  }

  BigInt? _factor(Map<String, ExchangeRate> rates, String from, String to) {
    final direct = rates['$from:$to'];
    if (direct != null) return direct.scaledRate;
    final inverse = rates['$to:$from'];
    if (inverse == null) return null;
    return ExchangeRate.scale * ExchangeRate.scale ~/ inverse.scaledRate;
  }

  int _apply(int amountMinor, BigInt factor) {
    final amount = BigInt.from(amountMinor);
    final half = ExchangeRate.scale ~/ BigInt.two;
    final rounded = amount.isNegative ? (amount * factor - half) ~/ ExchangeRate.scale : (amount * factor + half) ~/ ExchangeRate.scale;
    return rounded.toInt();
  }
}