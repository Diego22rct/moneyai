import 'package:flutter/material.dart';
import 'package:moneyai/core/theme/app_theme.dart';
import 'package:moneyai/features/expenses/presentation/pages/main_shell_page.dart';

class MoneyAiApp extends StatelessWidget {
  const MoneyAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoneyAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      themeMode: ThemeMode.dark,
      home: const MainShellPage(),
    );
  }
}
