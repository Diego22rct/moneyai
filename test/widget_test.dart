import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:moneyai/app.dart';

void main() {
  testWidgets('Muestra pantalla principal de MoneyAI', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoneyAiApp()));

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Balance del mes actual'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Captura'), findsOneWidget);
    expect(find.text('Etiquetas'), findsOneWidget);
  });
}
