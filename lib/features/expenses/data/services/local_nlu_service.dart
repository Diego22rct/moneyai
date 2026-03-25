import 'package:moneyai/core/constants/expense_categories.dart';

class LocalNluService {
  const LocalNluService();

  Map<String, Object> extractExpense(String text) {
    final String normalized = text.trim();
    if (normalized.isEmpty) {
      throw const FormatException('Debes ingresar un texto para procesar.');
    }

    final RegExp amountExp = RegExp(r'(\\d+[\\.,]?\\d*)');
    final RegExpMatch? amountMatch = amountExp.firstMatch(normalized);
    if (amountMatch == null) {
      throw const FormatException('No se pudo detectar el monto en el texto.');
    }

    final String rawAmount = amountMatch.group(1)!.replaceAll(',', '.');
    final double amount = double.parse(rawAmount);

    final String lower = normalized.toLowerCase();
    final String currency = _detectCurrency(lower);
    final String category = _detectCategory(lower);

    return <String, Object>{
      'amount': amount,
      'currency': currency,
      'description': normalized,
      'category': category,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  String _detectCurrency(String lowerText) {
    if (lowerText.contains('usd') ||
        lowerText.contains('dolar') ||
        lowerText.contains('dólar') ||
        lowerText.contains('\$')) {
      return 'USD';
    }

    if (lowerText.contains('eur') || lowerText.contains('euro')) {
      return 'EUR';
    }

    return 'PEN';
  }

  String _detectCategory(String lowerText) {
    final Map<String, String> byKeyword = <String, String>{
      'comida': 'Comida',
      'almuerzo': 'Comida',
      'cena': 'Comida',
      'taxi': 'Transporte',
      'bus': 'Transporte',
      'transporte': 'Transporte',
      'ropa': 'Ropa',
      'salud': 'Salud',
      'farmacia': 'Salud',
      'cine': 'Entretenimiento',
      'streaming': 'Entretenimiento',
      'hogar': 'Hogar',
      'luz': 'Hogar',
      'agua': 'Hogar',
    };

    for (final entry in byKeyword.entries) {
      if (lowerText.contains(entry.key)) {
        return entry.value;
      }
    }

    return kExpenseCategories.last;
  }
}
