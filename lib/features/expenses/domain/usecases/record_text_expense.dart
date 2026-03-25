import 'package:moneyai/features/expenses/domain/entities/expense.dart';
import 'package:moneyai/features/expenses/domain/repositories/expense_repository.dart';

class RecordTextExpense {
  const RecordTextExpense(this._repository);

  final ExpenseRepository _repository;

  Future<Expense> call(String text) {
    return _repository.recordExpenseFromText(text);
  }
}
