import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class SQLiteService {
  static const String expensesTable = 'expenses';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final String dbPath = await getDatabasesPath();
    final String path = p.join(dbPath, 'moneyai.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE $expensesTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            currency TEXT NOT NULL,
            description TEXT NOT NULL,
            category TEXT NOT NULL,
            timestamp TEXT NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }
}
