import 'package:moneyai/features/expenses/domain/entities/expense.dart';

abstract class ExpenseRepository {
  Future<List<Expense>> listExpenses();

  Future<Expense> analyzeMovementFromText(String text);

  Future<Expense> saveMovement(Expense expense);

  Future<Expense> recordExpenseFromText(String text);
}
