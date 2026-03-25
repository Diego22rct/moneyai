import 'package:moneyai/features/expenses/domain/entities/expense.dart';
import 'package:moneyai/features/expenses/domain/repositories/expense_repository.dart';

class FetchExpenses {
  const FetchExpenses(this._repository);

  final ExpenseRepository _repository;

  Future<List<Expense>> call() {
    return _repository.listExpenses();
  }
}
