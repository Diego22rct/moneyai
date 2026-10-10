import 'package:moneyai/features/expenses/domain/entities/expense.dart';
import 'package:moneyai/features/wallet_capture/data/parsers/money_amount_extractor.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/raw_transaction_signal.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/wallet_source.dart';
import 'package:moneyai/features/wallet_capture/domain/parsers/wallet_notification_parser.dart';

/// Fallback parser that triggers when an allowlisted or test notification contains a monetary amount
/// but no specialized parser was able to extract specific semantics.
class GenericAmountParser extends WalletNotificationParser {
  const GenericAmountParser({this.extractor = const MoneyAmountExtractor()});

  final MoneyAmountExtractor extractor;

  @override
  bool canHandle(RawTransactionSignal signal) => true;

  @override
  ParsedWalletTransaction? parse(RawTransactionSignal signal) {
    final text = signal.fullText;
    final extracted = extractor.extract(text);
    if (extracted == null) return null;

    final lower = text.toLowerCase();
    final isIncome = lower.contains('reembolso') ||
        lower.contains('recibiste') ||
        lower.contains('ingreso') ||
        lower.contains('refund') ||
        lower.contains('received');

    final merchant = signal.title.trim().isNotEmpty ? signal.title.trim() : null;

    return ParsedWalletTransaction(
      source: WalletSource.fromPackage(signal.packageName),
      amount: extracted.amount,
      currency: extracted.currency,
      type: isIncome ? TransactionType.income : TransactionType.expense,
      merchant: merchant,
    );
  }
}
