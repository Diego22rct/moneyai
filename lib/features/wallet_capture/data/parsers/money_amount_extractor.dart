/// Extracted amount and currency details from raw text.
class ExtractedMoney {
  const ExtractedMoney({
    required this.amount,
    required this.currency,
    required this.rawMatch,
  });

  final double amount;
  final String currency;
  final String rawMatch;
}

/// Helper that extracts currency and numerical amounts from multi-line text.
///
/// Handles Peruvian (S/, S/., PEN), USD ($ / US$), EUR (€ / EUR), and various formatting
/// like "S/ 12.50", "S/.1,250.00", "12,50 €", "USD 45.00", "$ 19.99".
class MoneyAmountExtractor {
  const MoneyAmountExtractor();

  /// Regex pattern matching common currency prefixes or suffixes with amounts.
  static final RegExp _currencyFirstRegex = RegExp(
    r'(?:(S\/\.?|PEN|US\$|\$|USD|EUR|€)\s*([\d\.,]+))',
    caseSensitive: false,
  );

  static final RegExp _amountFirstRegex = RegExp(
    r'([\d\.,]+)\s*(S\/\.?|PEN|US\$|\$|USD|EUR|€)',
    caseSensitive: false,
  );

  /// Attempts to extract the first valid monetary amount from [text].
  ExtractedMoney? extract(String text) {
    if (text.trim().isEmpty) return null;

    // 1. Try currency-first match (e.g. "S/ 45.50", "$100")
    final matchPrefix = _currencyFirstRegex.firstMatch(text);
    if (matchPrefix != null) {
      final rawCurrency = matchPrefix.group(1)!;
      final rawDigits = matchPrefix.group(2)!;
      final amount = _parseNumber(rawDigits);
      if (amount != null && amount > 0) {
        return ExtractedMoney(
          amount: amount,
          currency: _normalizeCurrency(rawCurrency),
          rawMatch: matchPrefix.group(0)!,
        );
      }
    }

    // 2. Try amount-first match (e.g. "45.50 S/", "100 €")
    final matchSuffix = _amountFirstRegex.firstMatch(text);
    if (matchSuffix != null) {
      final rawDigits = matchSuffix.group(1)!;
      final rawCurrency = matchSuffix.group(2)!;
      final amount = _parseNumber(rawDigits);
      if (amount != null && amount > 0) {
        return ExtractedMoney(
          amount: amount,
          currency: _normalizeCurrency(rawCurrency),
          rawMatch: matchSuffix.group(0)!,
        );
      }
    }

    return null;
  }

  String _normalizeCurrency(String raw) {
    final clean = raw.trim().toUpperCase();
    if (clean.startsWith('S/') || clean.startsWith('S/.') || clean == 'PEN') {
      return 'PEN';
    }
    if (clean == 'US\$' || clean == '\$' || clean == 'USD') {
      return 'USD';
    }
    if (clean == '€' || clean == 'EUR') {
      return 'EUR';
    }
    return 'PEN';
  }

  double? _parseNumber(String raw) {
    var cleaned = raw.trim();

    // Check if comma is used as decimal separator (e.g. 1.250,50 or 25,50)
    // vs comma used as thousands separator (e.g. 1,250.50)
    if (cleaned.contains(',') && cleaned.contains('.')) {
      final lastComma = cleaned.lastIndexOf(',');
      final lastDot = cleaned.lastIndexOf('.');
      if (lastComma > lastDot) {
        // e.g. 1.250,50 -> remove dots, replace comma with dot
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // e.g. 1,250.50 -> remove commas
        cleaned = cleaned.replaceAll(',', '');
      }
    } else if (cleaned.contains(',')) {
      // Check if comma is followed by exactly two or one digit at end (likely decimal)
      final parts = cleaned.split(',');
      if (parts.length == 2 && parts[1].length <= 2) {
        cleaned = cleaned.replaceAll(',', '.');
      } else {
        // thousands separator (e.g. 1,000)
        cleaned = cleaned.replaceAll(',', '');
      }
    }

    return double.tryParse(cleaned);
  }
}
