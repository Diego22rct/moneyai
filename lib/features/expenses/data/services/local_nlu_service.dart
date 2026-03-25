import 'package:moneyai/core/constants/expense_categories.dart';
import 'package:moneyai/features/ai_services/domain/services/nlu_service.dart';
import 'package:moneyai/features/expenses/domain/entities/expense.dart';

class LocalNluService implements NluService {
  const LocalNluService();

  @override
  Future<Map<String, Object>> extractMovement(String text) async {
    final String normalized = text.trim();
    if (normalized.isEmpty) {
      throw const FormatException('Debes ingresar un texto para procesar.');
    }

    final RegExp amountExp = RegExp(r'(\d+[\.,]?\d*)');
    final RegExpMatch? amountMatch = amountExp.firstMatch(normalized);
    if (amountMatch == null) {
      throw const FormatException('No se pudo detectar el monto en el texto.');
    }

    final String rawAmount = amountMatch.group(1)!.replaceAll(',', '.');
    final double amount = double.parse(rawAmount);

    final String lower = normalized.toLowerCase();
    final String currency = _detectCurrency(lower);
    final TransactionType type = _detectType(lower);
    final String category = _detectCategory(lower, type);

    return <String, Object>{
      'amount': amount,
      'currency': currency,
      'description': normalized,
      'type': type.name,
      'category': category,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  TransactionType _detectType(String lowerText) {
    const List<String> incomeWords = <String>[
      'ingreso',
      'ganancia',
      'sueldo',
      'salario',
      'me pagaron',
      'deposito',
      'depósito',
      'abono',
      'reembolso',
      'devolucion',
      'devolución',
      'comision',
      'comisión',
    ];

    for (final word in incomeWords) {
      if (lowerText.contains(word)) {
        return TransactionType.income;
      }
    }

    return TransactionType.expense;
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

  String _detectCategory(String lowerText, TransactionType type) {
    if (type == TransactionType.income) {
      final Map<String, String> incomeKeywords = <String, String>{
        'sueldo': 'Salario',
        'salario': 'Salario',
        'nomina': 'Salario',
        'nómina': 'Salario',
        'freelance': 'Freelance',
        'honorario': 'Freelance',
        'dividendo': 'Inversiones',
        'interes': 'Inversiones',
        'interés': 'Inversiones',
        'regalo': 'Regalos',
        'premio': 'Regalos',
        'reembolso': 'Reembolsos',
        'devolucion': 'Reembolsos',
        'devolución': 'Reembolsos',
      };

      for (final entry in incomeKeywords.entries) {
        if (lowerText.contains(entry.key)) {
          return entry.value;
        }
      }

      return kIncomeCategories.last;
    }

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
