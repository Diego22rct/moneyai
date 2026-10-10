import 'package:moneyai/features/expenses/domain/entities/expense.dart';
import 'package:moneyai/features/wallet_capture/data/parsers/money_amount_extractor.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/raw_transaction_signal.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/wallet_source.dart';
import 'package:moneyai/features/wallet_capture/domain/parsers/wallet_notification_parser.dart';

/// Parser specialized for Google Wallet (com.google.android.apps.walletnfcrel)
/// and Google Pay (com.google.android.apps.nbu.paisa.user).
class GoogleWalletParser extends WalletNotificationParser {
  const GoogleWalletParser({this.extractor = const MoneyAmountExtractor()});

  final MoneyAmountExtractor extractor;

  @override
  bool canHandle(RawTransactionSignal signal) {
    return signal.packageName == 'com.google.android.apps.walletnfcrel' ||
        signal.packageName == 'com.google.android.apps.nbu.paisa.user';
  }

  @override
  ParsedWalletTransaction? parse(RawTransactionSignal signal) {
    final text = signal.fullText;
    if (text.isEmpty) return null;

    final lower = text.toLowerCase();

    // Ignore non-transaction events like adding a card, security alerts, promotional updates
    const nonTransactionKeywords = <String>[
      'tarjeta agregada',
      'card added',
      'nueva tarjeta',
      'configurar',
      'bienvenido',
      'welcome',
      'seguridad',
      'security alert',
    ];
    for (final kw in nonTransactionKeywords) {
      if (lower.contains(kw)) {
        return null;
      }
    }

    final extracted = extractor.extract(text);
    if (extracted == null) {
      // No monetary amount found -> likely not a payment notification
      return null;
    }

    // Determine type: expense vs income (refund / cash received)
    final type = _detectTransactionType(lower);

    // Extract merchant name
    final merchant = _detectMerchant(signal, extracted.rawMatch);

    final source = signal.packageName == 'com.google.android.apps.nbu.paisa.user'
        ? WalletSource.googlePay
        : WalletSource.googleWallet;

    return ParsedWalletTransaction(
      source: source,
      amount: extracted.amount,
      currency: extracted.currency,
      type: type,
      merchant: merchant,
    );
  }

  TransactionType _detectTransactionType(String lowerText) {
    const incomeKeywords = <String>[
      'reembolso',
      'reembolsado',
      'refund',
      'recibiste',
      'recibido',
      'received',
      'devuelto',
      'devolución',
      'devolucion',
    ];

    for (final kw in incomeKeywords) {
      if (lowerText.contains(kw)) {
        return TransactionType.income;
      }
    }

    return TransactionType.expense;
  }

  String? _detectMerchant(RawTransactionSignal signal, String rawMatch) {
    final title = signal.title.trim();
    final lowerTitle = title.toLowerCase();

    // Often in Google Wallet, title IS the merchant (e.g. "Tambo", "Starbucks", "Cineplanet")
    // unless title is just the app name "Google Wallet" or "Google Pay"
    final isGenericTitle = lowerTitle == 'google wallet' ||
        lowerTitle == 'google pay' ||
        lowerTitle == 'billetera de google' ||
        lowerTitle.isEmpty;

    if (!isGenericTitle) {
      return title;
    }

    // If title was generic, try to find merchant in the text (e.g. "en Tambo", "a Starbucks", "to Starbucks")
    final text = signal.text;
    final regexes = <RegExp>[
      RegExp(r'(?:en|a|to|at)\s+([A-Za-z0-9\s\.\-&]{2,30}?)(?:\s+(?:con|with|\.|,))', caseSensitive: false),
      RegExp(r'(?:en|a|to|at)\s+([A-Za-z0-9\s\.\-&]{2,30})$', caseSensitive: false),
    ];

    for (final reg in regexes) {
      final match = reg.firstMatch(text);
      if (match != null) {
        final found = match.group(1)?.trim();
        if (found != null && found.isNotEmpty && !found.toLowerCase().contains(rawMatch.toLowerCase())) {
          return found;
        }
      }
    }

    return null;
  }
}
