import 'package:moneyai/features/ai_services/domain/services/nlu_service.dart';
import 'package:moneyai/features/expenses/data/datasources/expense_local_datasource.dart';
import 'package:moneyai/features/expenses/data/services/local_nlu_service.dart';
import 'package:moneyai/features/expenses/domain/entities/expense.dart';
import 'package:moneyai/features/expenses/domain/repositories/expense_repository.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  ExpenseRepositoryImpl({
    required ExpenseLocalDataSource localDataSource,
    required NluService nluService,
  }) : _localDataSource = localDataSource,
       _nluService = nluService;

  final ExpenseLocalDataSource _localDataSource;
  final NluService _nluService;

  @override
  Future<List<Expense>> listExpenses() {
    return _localDataSource.listExpenses();
  }

  @override
  Future<Expense> analyzeMovementFromText(String text) async {
    Map<String, Object> parsed;

    try {
      parsed = await _nluService.extractMovement(text);
    } on FormatException {
      parsed = await const LocalNluService().extractMovement(text);
    }

    final String typeValue =
        parsed['type'] as String? ?? TransactionType.expense.name;
    final String detectedCategory = parsed['category'] as String? ?? 'Otros';

    return Expense(
      amount: parsed['amount'] as double,
      currency: parsed['currency'] as String,
      type: TransactionType.values.firstWhere(
        (value) => value.name == typeValue,
        orElse: () => TransactionType.expense,
      ),
      description: parsed['description'] as String,
      category: detectedCategory,
      tags: <String>[detectedCategory],
      timestamp: DateTime.parse(parsed['timestamp'] as String),
    );
  }

  @override
  Future<Expense> saveMovement(Expense expense) {
    return _localDataSource.insertExpense(expense);
  }

  @override
  Future<Expense> recordExpenseFromText(String text) async {
    final Expense analyzed = await analyzeMovementFromText(text);
    return saveMovement(analyzed);
  }
}
