import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyai/features/ai_services/data/implementations/llama_nlu_service.dart';
import 'package:moneyai/features/ai_services/domain/services/nlu_service.dart';
import 'package:moneyai/features/ai_services/domain/services/stt_service.dart';
import 'package:moneyai/features/expenses/data/datasources/expense_local_datasource.dart';
import 'package:moneyai/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:moneyai/features/expenses/data/services/local_nlu_service.dart';
import 'package:moneyai/features/expenses/data/services/local_stt_service.dart';
import 'package:moneyai/features/expenses/data/services/sqlite_service.dart';
import 'package:moneyai/features/expenses/domain/entities/expense.dart';
import 'package:moneyai/features/expenses/domain/repositories/expense_repository.dart';
import 'package:moneyai/features/expenses/domain/usecases/fetch_expenses.dart';
import 'package:moneyai/features/expenses/domain/usecases/record_text_expense.dart';
import 'package:moneyai/features/model_selection/presentation/providers/model_selector_provider.dart';

final sqliteServiceProvider = Provider<SQLiteService>((ref) {
  return SQLiteService();
});

final localDataSourceProvider = Provider<ExpenseLocalDataSource>((ref) {
  return ExpenseLocalDataSource(ref.watch(sqliteServiceProvider));
});

final nluServiceProvider = Provider<NluService>((ref) {
  final selected = ref
      .watch(activeNluModelProvider)
      .maybeWhen(data: (value) => value, orElse: () => 'regex_local');

  if (selected == 'llama_local') {
    return LlamaNluService(ref.watch(aiRuntimeConfigLocalDataSourceProvider));
  }

  return const LocalNluService();
});

final sttServiceProvider = Provider<SttService>((ref) {
  return LocalSttService();
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryImpl(
    localDataSource: ref.watch(localDataSourceProvider),
    nluService: ref.watch(nluServiceProvider),
  );
});

final fetchExpensesProvider = Provider<FetchExpenses>((ref) {
  return FetchExpenses(ref.watch(expenseRepositoryProvider));
});

final recordTextExpenseProvider = Provider<RecordTextExpense>((ref) {
  return RecordTextExpense(ref.watch(expenseRepositoryProvider));
});

final expenseListProvider =
    AsyncNotifierProvider<ExpenseListNotifier, List<Expense>>(
      ExpenseListNotifier.new,
    );

class MonthlyBalanceSummary {
  const MonthlyBalanceSummary({required this.income, required this.expense});

  final double income;
  final double expense;

  double get net => income - expense;
}

class TagTotal {
  const TagTotal({
    required this.tag,
    required this.amount,
    required this.count,
  });

  final String tag;
  final double amount;
  final int count;
}

final monthlyBalanceProvider = Provider<AsyncValue<MonthlyBalanceSummary>>((
  ref,
) {
  final AsyncValue<List<Expense>> value = ref.watch(expenseListProvider);

  return value.whenData((items) {
    final DateTime now = DateTime.now();
    final Iterable<Expense> monthlyItems = items.where(
      (expense) =>
          expense.timestamp.toLocal().year == now.year &&
          expense.timestamp.toLocal().month == now.month,
    );

    double totalIncome = 0;
    double totalExpense = 0;

    for (final Expense item in monthlyItems) {
      if (item.type == TransactionType.income) {
        totalIncome += item.amount;
      } else {
        totalExpense += item.amount;
      }
    }

    return MonthlyBalanceSummary(income: totalIncome, expense: totalExpense);
  });
});

final tagRankingProvider = Provider<AsyncValue<List<TagTotal>>>((ref) {
  final AsyncValue<List<Expense>> value = ref.watch(expenseListProvider);

  return value.whenData((items) {
    final Map<String, TagTotal> map = <String, TagTotal>{};

    for (final Expense expense in items) {
      final List<String> tags = expense.tags.isEmpty
          ? <String>[expense.category]
          : expense.tags;

      for (final String rawTag in tags) {
        final String tag = rawTag.trim();
        if (tag.isEmpty) {
          continue;
        }

        final TagTotal? current = map[tag];
        map[tag] = TagTotal(
          tag: tag,
          amount: (current?.amount ?? 0) + expense.amount,
          count: (current?.count ?? 0) + 1,
        );
      }
    }

    final List<TagTotal> ranking = map.values.toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return ranking;
  });
});

class ExpenseListNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() async {
    return ref.read(fetchExpensesProvider).call();
  }

  Future<void> refreshList() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(fetchExpensesProvider).call(),
    );
  }
}
