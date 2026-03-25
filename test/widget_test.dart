import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moneyai/app.dart';

void main() {
  testWidgets('Muestra pantalla principal de MoneyAI', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoneyAiApp()));

    expect(find.text('MoneyAI'), findsOneWidget);
    expect(find.text('Procesar movimiento'), findsOneWidget);
    expect(find.text('Describe tu gasto o ingreso'), findsOneWidget);
  });
}
