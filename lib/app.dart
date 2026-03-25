import 'package:flutter/material.dart';
import 'package:moneyai/features/expenses/presentation/pages/home_page.dart';

class MoneyAiApp extends StatelessWidget {
  const MoneyAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoneyAI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00A86B)),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
