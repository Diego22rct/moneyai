import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:moneyai/core/theme/app_theme.dart';
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
      children: <Widget>[
        const Text(
          'TOTAL LIQUID BALANCE',
          style: TextStyle(
            color: AppTheme.onSurfaceMuted,
            fontSize: 12,
            letterSpacing: 2.2,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        monthlySummary.when(
          data: (summary) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  amountFormat.format(summary.net),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.onSurface,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: AppTheme.secondary.withValues(alpha: 0.12),
                  ),
                  child: Text(
                    '${summary.net >= 0 ? '+' : ''}${((summary.net == 0 ? 0 : (summary.net / (summary.income == 0 ? 1 : summary.income)) * 100)).toStringAsFixed(1)}% vs last month',
                    style: const TextStyle(
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 12),
            child: CircularProgressIndicator(),
          ),
          error: (error, stackTrace) => const _GlassCard(
            child: Text('No se pudo calcular el balance mensual.'),
          ),
        ),
        const SizedBox(height: 30),
        const _SectionHeader(title: 'Spending Flow', action: 'View Insights'),
        const SizedBox(height: 12),
        SizedBox(
          height: 178,
          child: ref.watch(tagRankingProvider).when(
                data: (tags) {
                  if (tags.isEmpty) {
                    return const _GlassCard(
                      child: Center(child: Text('Aun no hay movimientos para mostrar.')),
                    );
                  }

                  final List<TagTotal> top = tags.take(6).toList();
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: top.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = top[index];
                      final Color accent = index.isEven ? AppTheme.primary : AppTheme.secondary;
                      return _FlowCard(
                        title: item.tag,
                        amount: amountFormat.format(item.amount),
                        accent: accent,
                        progress: ((item.count * 15).clamp(10, 100)) / 100,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => const _GlassCard(
                  child: Text('No se pudo construir el flujo por etiquetas.'),
                ),
              ),
        ),
        const SizedBox(height: 30),
        const _SectionHeader(title: 'Ledger Activity', action: 'LAST 7 DAYS'),
        const SizedBox(height: 12),
        expensesState.when(
          data: (items) {
            if (items.isEmpty) {
              return const _GlassCard(
                child: Text('Todavia no tienes movimientos registrados.'),
              );
            }

            return Column(
              children: items.take(6).map((expense) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _LedgerTile(expense: expense),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const _GlassCard(
            child: Text('No se pudo cargar movimientos recientes.'),
          ),
        ),
        const SizedBox(height: 20),
        const _InsightCard(),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          action,
          style: TextStyle(
            color: action == 'View Insights' ? AppTheme.primary : AppTheme.onSurfaceMuted,
            fontSize: 12,
            letterSpacing: 0.7,
          ),
        ),
      ],
    );
  }
}

class _FlowCard extends StatelessWidget {
  const _FlowCard({
    required this.title,
    required this.amount,
    required this.accent,
    required this.progress,
  });

  final String title;
  final String amount;
  final Color accent;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: AppTheme.surfaceHigh.withValues(alpha: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.label, color: accent),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.onSurfaceMuted),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount,
                    style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    color: accent,
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

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final bool isIncome = expense.type == TransactionType.income;

    return _GlassCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isIncome ? Icons.payments : Icons.shopping_cart,
              color: isIncome ? AppTheme.secondary : AppTheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(expense.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd MMM, HH:mm').format(expense.timestamp.toLocal()),
                  style: const TextStyle(color: AppTheme.onSurfaceMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${isIncome ? '+' : '-'}${expense.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isIncome ? AppTheme.secondary : AppTheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            AppTheme.primary.withValues(alpha: 0.14),
            Colors.transparent,
          ],
        ),
        color: AppTheme.surfaceHigh.withValues(alpha: 0.7),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Ethereal Insight',
            style: TextStyle(color: AppTheme.primary, fontSize: 24, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 8),
          Text(
            'Tu gasto en algunas etiquetas subio esta semana. Si rediriges parte del flujo a ahorro, podrias mejorar tu balance neto mensual.',
            style: TextStyle(color: AppTheme.onSurfaceMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppTheme.surfaceHigh.withValues(alpha: 0.7),
      ),
      child: child,
    );
  }
}
