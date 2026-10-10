import 'package:flutter_test/flutter_test.dart';
import 'package:moneyai/features/expenses/domain/entities/expense.dart';
import 'package:moneyai/features/wallet_capture/data/parsers/google_wallet_parser.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/raw_transaction_signal.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/wallet_source.dart';

void main() {
  const parser = GoogleWalletParser();

  RawTransactionSignal makeSignal({
    String packageName = 'com.google.android.apps.walletnfcrel',
    String title = '',
    String text = '',
  }) {
    return RawTransactionSignal(
      nativeId: 1,
      origin: SignalOrigin.androidNotification,
      packageName: packageName,
      title: title,
      text: text,
      postedAt: DateTime.parse('2026-03-24T12:00:00Z'),
      dedupeKey: 'key-1',
    );
  }

  group('GoogleWalletParser', () {
    test('handles Google Wallet and Google Pay package names', () {
      expect(
        parser.canHandle(makeSignal(packageName: 'com.google.android.apps.walletnfcrel')),
        isTrue,
      );
      expect(
        parser.canHandle(makeSignal(packageName: 'com.google.android.apps.nbu.paisa.user')),
        isTrue,
      );
      expect(
        parser.canHandle(makeSignal(packageName: 'com.whatsapp')),
        isFalse,
      );
    });

    test('parses standard purchase where title is merchant', () {
      final signal = makeSignal(
        title: 'Tambo',
        text: 'S/ 12.50 con Visa •••• 1234',
      );

      final result = parser.parse(signal);
      expect(result, isNotNull);
      expect(result!.source, WalletSource.googleWallet);
      expect(result.amount, 12.50);
      expect(result.currency, 'PEN');
      expect(result.type, TransactionType.expense);
      expect(result.merchant, 'Tambo');
    });

    test('parses purchase with generic title and merchant in text', () {
      final signal = makeSignal(
        title: 'Google Wallet',
        text: 'Pagaste S/ 25.00 en Starbucks con Mastercard',
      );

      final result = parser.parse(signal);
      expect(result, isNotNull);
      expect(result!.amount, 25.00);
      expect(result.currency, 'PEN');
      expect(result.type, TransactionType.expense);
      expect(result.merchant, 'Starbucks');
    });

    test('detects refunds / income transactions', () {
      final signal = makeSignal(
        title: 'Reembolso recibido',
        text: 'Recibiste S/ 40.00 de Cineplanet',
      );

      final result = parser.parse(signal);
      expect(result, isNotNull);
      expect(result!.amount, 40.00);
      expect(result.type, TransactionType.income);
    });

    test('ignores non-transaction notifications (card added, promos)', () {
      final signal1 = makeSignal(
        title: 'Tarjeta agregada',
        text: 'Tu tarjeta Visa ya está lista para pagar sin contacto.',
      );
      expect(parser.parse(signal1), isNull);

      final signal2 = makeSignal(
        title: 'Bienvenido a Google Wallet',
        text: 'Guarda tus tarjetas y pases en un solo lugar.',
      );
      expect(parser.parse(signal2), isNull);
    });
  });
}
