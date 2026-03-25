import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyai/features/expenses/data/datasources/expense_local_datasource.dart';
import 'package:moneyai/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:moneyai/features/expenses/data/services/local_nlu_service.dart';
import 'package:moneyai/features/expenses/data/services/sqlite_service.dart';
import 'package:moneyai/features/expenses/domain/entities/expense.dart';
import 'package:moneyai/features/expenses/domain/repositories/expense_repository.dart';
import 'package:moneyai/features/expenses/domain/usecases/fetch_expenses.dart';
import 'package:moneyai/features/expenses/domain/usecases/record_text_expense.dart';

final sqliteServiceProvider = Provider<SQLiteService>((ref) {
  return SQLiteService();
});

final localDataSourceProvider = Provider<ExpenseLocalDataSource>((ref) {
  return ExpenseLocalDataSource(ref.watch(sqliteServiceProvider));
});

final localNluServiceProvider = Provider<LocalNluService>((ref) {
  return const LocalNluService();
});

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepositoryImpl(
    localDataSource: ref.watch(localDataSourceProvider),
    nluService: ref.watch(localNluServiceProvider),
  );
});

final fetchExpensesProvider = Provider<FetchExpenses>((ref) {
  return FetchExpenses(ref.watch(expenseRepositoryProvider));
});

final recordTextExpenseProvider = Provider<RecordTextExpense>((ref) {
  return RecordTextExpense(ref.watch(expenseRepositoryProvider));
});

final expenseListProvider = AsyncNotifierProvider<ExpenseListNotifier, List<Expense>>(
  ExpenseListNotifier.new,
);

class ExpenseListNotifier extends AsyncNotifier<List<Expense>> {
  @override
  Future<List<Expense>> build() async {
    return ref.read(fetchExpensesProvider).call();
  }

  Future<void> refreshList() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(fetchExpensesProvider).call());
  }
}
