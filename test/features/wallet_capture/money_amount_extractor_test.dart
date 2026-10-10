import 'package:flutter_test/flutter_test.dart';
import 'package:moneyai/features/wallet_capture/data/parsers/money_amount_extractor.dart';

void main() {
  const extractor = MoneyAmountExtractor();

  group('MoneyAmountExtractor', () {
    test('extracts Peruvian soles prefix variants (S/ and S/.)', () {
      final res1 = extractor.extract('Pago realizado por S/ 12.50 con Visa');
      expect(res1, isNotNull);
      expect(res1!.amount, 12.50);
      expect(res1.currency, 'PEN');

      final res2 = extractor.extract('Total: S/. 1,250.00 en Tambo');
      expect(res2, isNotNull);
      expect(res2!.amount, 1250.00);
      expect(res2.currency, 'PEN');

      final res3 = extractor.extract('PEN 45.90');
      expect(res3, isNotNull);
      expect(res3!.amount, 45.90);
      expect(res3.currency, 'PEN');
    });

    test('extracts US Dollar variants (\$, US\$, USD)', () {
      final res1 = extractor.extract('Has pagado \$15.99');
      expect(res1, isNotNull);
      expect(res1!.amount, 15.99);
      expect(res1.currency, 'USD');

      final res2 = extractor.extract('Charge of US\$ 30.00 at Apple');
      expect(res2, isNotNull);
      expect(res2!.amount, 30.00);
      expect(res2.currency, 'USD');

      final res3 = extractor.extract('USD 99.50 paid');
      expect(res3, isNotNull);
      expect(res3!.amount, 99.50);
      expect(res3.currency, 'USD');
    });

    test('extracts Euro variants (€, EUR)', () {
      final res1 = extractor.extract('Pagado 25,50 € en Madrid');
      expect(res1, isNotNull);
      expect(res1!.amount, 25.50);
      expect(res1.currency, 'EUR');

      final res2 = extractor.extract('EUR 100.00 transfer');
      expect(res2, isNotNull);
      expect(res2!.amount, 100.00);
      expect(res2.currency, 'EUR');
    });

    test('handles European comma decimal format (1.250,50)', () {
      final res = extractor.extract('Total: 1.250,50 EUR');
      expect(res, isNotNull);
      expect(res!.amount, 1250.50);
      expect(res.currency, 'EUR');
    });

    test('returns null when no amount is present', () {
      expect(extractor.extract(''), isNull);
      expect(extractor.extract('Tarjeta agregada correctamente'), isNull);
      expect(extractor.extract('Bienvenido a Google Wallet'), isNull);
    });
  });
}
