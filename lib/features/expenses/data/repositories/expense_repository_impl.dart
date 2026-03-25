import 'package:moneyai/features/expenses/data/datasources/expense_local_datasource.dart';
import 'package:moneyai/features/expenses/data/services/local_nlu_service.dart';
import 'package:moneyai/features/expenses/domain/entities/expense.dart';
import 'package:moneyai/features/expenses/domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl({
    required ExpenseLocalDataSource localDataSource,
    required LocalNluService nluService,
  })  : _localDataSource = localDataSource,
        _nluService = nluService;

  final ExpenseLocalDataSource _localDataSource;
  final LocalNluService _nluService;

  @override
  Future<List<Expense>> listExpenses() {
    return _localDataSource.listExpenses();
  }

  @override
  Future<Expense> recordExpenseFromText(String text) async {
    final Map<String, Object> parsed = _nluService.extractExpense(text);

    final Expense expense = Expense(
      amount: parsed['amount'] as double,
      currency: parsed['currency'] as String,
      description: parsed['description'] as String,
      category: parsed['category'] as String,
      timestamp: DateTime.parse(parsed['timestamp'] as String),
    );

    return _localDataSource.insertExpense(expense);
  }
}
