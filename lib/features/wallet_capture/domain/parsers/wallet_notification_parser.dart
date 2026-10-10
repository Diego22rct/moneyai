import 'package:moneyai/features/expenses/domain/entities/expense.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/raw_transaction_signal.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/wallet_source.dart';

/// Structured result extracted from a wallet notification.
class ParsedWalletTransaction {
  const ParsedWalletTransaction({
    required this.source,
    required this.amount,
    required this.currency,
    required this.type,
    this.merchant,
  });

  final WalletSource source;
  final double amount;
  final String currency;
  final TransactionType type;
  final String? merchant;
}

/// Parses notifications of a specific wallet/bank app.
abstract class WalletNotificationParser {
  const WalletNotificationParser();

  bool canHandle(RawTransactionSignal signal);

  /// Returns null when the notification is not a completed transaction
  /// (promos, declined payments, card added, etc.).
  ParsedWalletTransaction? parse(RawTransactionSignal signal);
}
