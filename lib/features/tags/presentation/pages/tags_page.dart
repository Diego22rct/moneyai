import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:moneyai/core/theme/app_theme.dart';
import 'package:moneyai/features/expenses/domain/entities/expense.dart';
import 'package:moneyai/features/expenses/presentation/providers/expense_list_provider.dart';

class TagsPage extends ConsumerStatefulWidget {
  const TagsPage({super.key});

  @override
  ConsumerState<TagsPage> createState() => _TagsPageState();
}

class _TagsPageState extends ConsumerState<TagsPage> {
  String? _selectedTag;

  @override
  Widget build(BuildContext context) {
    final rankingState = ref.watch(tagRankingProvider);
    final expensesState = ref.watch(expenseListProvider);
    final NumberFormat amountFormat = NumberFormat.currency(
      locale: 'es_PE',
      symbol: 'PEN ',
      decimalDigits: 2,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Ranking de etiquetas', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Expanded(
              child: rankingState.when(
                data: (ranking) {
                  if (ranking.isEmpty) {
                    return const Center(
                      child: Text('Aun no hay etiquetas registradas.'),
                    );
                  }

                  final String activeTag = _selectedTag ?? ranking.first.tag;

                  return Column(
                    children: <Widget>[
                      Expanded(
                        child: ListView.separated(
                          itemCount: ranking.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final TagTotal item = ranking[index];
                            final bool selected = item.tag == activeTag;

                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedTag = item.tag;
                                });
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Ink(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: selected
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.12)
                                      : Theme.of(context).colorScheme.surfaceContainer,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        item.tag,
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ),
                                    Text('${item.count} movs.'),
                                    const SizedBox(width: 10),
                                    Text(
                                      amountFormat.format(item.amount),
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Movimientos de $activeTag',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: expensesState.when(
                          data: (items) {
                            final List<Expense> filtered = items.where((expense) {
                              final List<String> tags =
                                  expense.tags.isEmpty ? <String>[expense.category] : expense.tags;
                              return tags.any((tag) => tag.toLowerCase() == activeTag.toLowerCase());
                            }).toList();

                            if (filtered.isEmpty) {
                              return const Center(
                                child: Text('No hay movimientos para esta etiqueta.'),
                              );
                            }

                            return ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final Expense expense = filtered[index];
                                final bool isIncome = expense.type == TransactionType.income;
                                return ListTile(
                                  tileColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  leading: Icon(
                                    isIncome ? Icons.add_circle : Icons.remove_circle,
                                    color: isIncome ? AppTheme.secondary : AppTheme.danger,
                                  ),
                                  title: Text(expense.description),
                                  subtitle: Text(expense.tags.join(' • ')),
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (error, stackTrace) => const Center(
                            child: Text('No se pudo cargar los movimientos.'),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => const Center(
                  child: Text('No se pudo cargar el ranking de etiquetas.'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
