import 'package:moneyai/features/expenses/domain/entities/expense.dart';

abstract class ExpenseRepository {
  Future<List<Expense>> listExpenses();

  Future<Expense> recordExpenseFromText(String text);
}
