import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyai/features/ai_services/data/implementations/llama_nlu_service.dart';
import 'package:moneyai/features/ai_services/data/implementations/whisper_stt_service.dart';
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
  final selected = ref.watch(activeNluModelProvider).maybeWhen(
        data: (value) => value,
        orElse: () => 'regex_local',
      );

  if (selected == 'llama_local') {
    return LlamaNluService();
  }

  return const LocalNluService();
});

final sttServiceProvider = Provider<SttService>((ref) {
  final selected = ref.watch(activeSttModelProvider).maybeWhen(
        data: (value) => value,
        orElse: () => 'speech_to_text',
      );

  if (selected == 'whisper_tiny_local') {
    return WhisperSttService();
  }

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
