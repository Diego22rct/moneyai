import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:moneyai/features/expenses/domain/entities/expense.dart';
import 'package:moneyai/features/expenses/presentation/providers/expense_list_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlySummary = ref.watch(monthlyBalanceProvider);
    final expensesState = ref.watch(expenseListProvider);
    final NumberFormat amountFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'PEN ',
      decimalDigits: 2,
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(
            'Balance del mes actual',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          monthlySummary.when(
            data: (summary) {
              return Column(
                children: <Widget>[
                  _BalanceCard(
                    title: 'Balance neto',
                    value: amountFormat.format(summary.net),
                    color: summary.net >= 0 ? Colors.green : Colors.red,
                    icon: summary.net >= 0 ? Icons.trending_up : Icons.trending_down,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _MiniStatCard(
                          title: 'Ingresos',
                          value: amountFormat.format(summary.income),
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniStatCard(
                          title: 'Gastos',
                          value: amountFormat.format(summary.expense),
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            error: (error, stackTrace) => const _InfoCard(message: 'No se pudo calcular el balance mensual.'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: 16),
          Text(
            'Movimientos recientes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          expensesState.when(
            data: (items) {
              if (items.isEmpty) {
                return const _InfoCard(message: 'Todavia no tienes movimientos registrados.');
              }

              final List<Expense> recent = items.take(5).toList();
              return Column(
                children: recent
                    .map((expense) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _RecentMovementTile(expense: expense),
                        ))
                    .toList(),
              );
            },
            error: (error, stackTrace) => const _InfoCard(message: 'No se pudo cargar movimientos.'),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[color.withValues(alpha: 0.18), Theme.of(context).colorScheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _RecentMovementTile extends StatelessWidget {
  const _RecentMovementTile({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final bool isIncome = expense.type == TransactionType.income;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isIncome ? Colors.green : Colors.red).withValues(alpha: 0.15),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(expense.description),
        subtitle: Text(
          expense.tags.isEmpty ? expense.category : expense.tags.join(' • '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message),
    );
  }
}
