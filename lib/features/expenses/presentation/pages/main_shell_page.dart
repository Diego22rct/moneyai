import 'package:flutter/material.dart';
import 'package:moneyai/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:moneyai/features/expenses/presentation/pages/capture_page.dart';
import 'package:moneyai/features/model_selection/presentation/pages/settings_page.dart';
import 'package:moneyai/features/tags/presentation/pages/tags_page.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _index = 0;

  static const List<String> _titles = <String>[
    'Dashboard',
    'Captura',
    'Etiquetas',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsPage(),
                ),
              );
            },
            icon: const Icon(Icons.tune),
            tooltip: 'Modelos IA',
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          DashboardPage(),
          CapturePage(),
          TagsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_none),
            selectedIcon: Icon(Icons.mic),
            label: 'Captura',
          ),
          NavigationDestination(
            icon: Icon(Icons.sell_outlined),
            selectedIcon: Icon(Icons.sell),
            label: 'Etiquetas',
          ),
        ],
      ),
    );
  }
}
