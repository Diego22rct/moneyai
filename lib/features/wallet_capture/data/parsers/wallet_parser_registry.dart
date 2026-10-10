import 'package:moneyai/features/wallet_capture/data/parsers/generic_amount_parser.dart';
import 'package:moneyai/features/wallet_capture/data/parsers/google_wallet_parser.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/raw_transaction_signal.dart';
import 'package:moneyai/features/wallet_capture/domain/parsers/wallet_notification_parser.dart';

/// Registry holding prioritized wallet notification parsers.
///
/// Order of evaluation:
/// 1. App-specific parsers (e.g. Google Wallet, future: Yape, Plin, BCP)
/// 2. GenericAmountParser fallback
class WalletParserRegistry {
  WalletParserRegistry({
    List<WalletNotificationParser>? customParsers,
  }) : _parsers = <WalletNotificationParser>[
          ...?customParsers,
          const GoogleWalletParser(),
          const GenericAmountParser(),
        ];

  final List<WalletNotificationParser> _parsers;

  /// Tries each parser in order until one returns a parsed transaction.
  /// Returns null if none matches or if the signal is not a financial movement.
  ParsedWalletTransaction? parse(RawTransactionSignal signal) {
    for (final parser in _parsers) {
      if (parser.canHandle(signal)) {
        final parsed = parser.parse(signal);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }
}
