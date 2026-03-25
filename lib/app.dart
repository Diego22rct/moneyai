import 'package:flutter/material.dart';
import 'package:moneyai/features/expenses/presentation/pages/main_shell_page.dart';

class MoneyAiApp extends StatelessWidget {
  const MoneyAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoneyAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF16A34A),
          secondary: const Color(0xFF0EA5E9),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
        appBarTheme: const AppBarThemeData(
          centerTitle: false,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(),
        ),
        useMaterial3: true,
      ),
      home: const MainShellPage(),
    );
  }
}
