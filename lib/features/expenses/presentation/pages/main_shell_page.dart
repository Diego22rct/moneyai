import 'package:flutter/material.dart';
import 'package:moneyai/core/theme/app_theme.dart';
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

  static const List<String> _titles = <String>['MONEYAI', 'MONEYAI', 'MONEYAI'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 18,
        title: Row(
          children: <Widget>[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppTheme.surfaceHigh,
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Icon(Icons.person, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              _titles[_index],
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    letterSpacing: 4,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SettingsPage(),
                ),
              );
            },
            icon: const Icon(Icons.notifications),
            tooltip: 'Modelos IA',
          ),
          const SizedBox(width: 6),
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
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.62),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              blurRadius: 28,
              spreadRadius: 1,
              color: AppTheme.primary.withValues(alpha: 0.09),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _NavItem(
              icon: Icons.account_balance_wallet_outlined,
              activeIcon: Icons.account_balance_wallet,
              selected: _index == 0,
              onTap: () => setState(() => _index = 0),
            ),
            _NavItem(
              icon: Icons.insights_outlined,
              activeIcon: Icons.insights,
              selected: _index == 2,
              onTap: () => setState(() => _index = 2),
            ),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: AppTheme.neonPrimaryGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    blurRadius: 30,
                    color: AppTheme.primary.withValues(alpha: 0.35),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => setState(() => _index = 1),
                icon: const Icon(Icons.add, color: Color(0xFF2C0051), size: 28),
              ),
            ),
            _NavItem(
              icon: Icons.mic_none,
              activeIcon: Icons.mic,
              selected: _index == 1,
              onTap: () => setState(() => _index = 1),
            ),
            _NavItem(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              selected: false,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SettingsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.06 : 1,
      duration: const Duration(milliseconds: 180),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          selected ? activeIcon : icon,
          color: selected ? AppTheme.primary : AppTheme.onSurfaceMuted,
        ),
      ),
    );
  }
}
