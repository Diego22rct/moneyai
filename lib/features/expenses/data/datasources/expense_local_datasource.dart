import 'package:moneyai/features/expenses/data/services/sqlite_service.dart';
import 'package:moneyai/features/expenses/domain/entities/expense.dart';

class ExpenseLocalDataSource {
  ExpenseLocalDataSource(this._sqliteService);

  final SQLiteService _sqliteService;

  Future<Expense> insertExpense(Expense expense) async {
    final db = await _sqliteService.database;

    final int id = await db.insert(
      SQLiteService.expensesTable,
      expense.toMap()..remove('id'),
    );

    return expense.copyWith(id: id);
  }

  Future<List<Expense>> listExpenses() async {
    final db = await _sqliteService.database;

    final rows = await db.query(
      SQLiteService.expensesTable,
      orderBy: 'timestamp DESC',
    );

    return rows.map((Map<String, Object?> row) => Expense.fromMap(row)).toList();
  }
}
