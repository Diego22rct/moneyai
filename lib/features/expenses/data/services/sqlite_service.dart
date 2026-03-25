import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class SQLiteService {
  static const String expensesTable = 'expenses';
  static const String modelConfigsTable = 'model_configs';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final String dbPath = await getDatabasesPath();
    final String path = p.join(dbPath, 'moneyai.db');

    _database = await openDatabase(
      path,
      version: 2,
      onCreate: (Database db, int version) async {
        await _createExpensesTable(db);
        await _createModelConfigsTable(db);
        await _seedDefaultModels(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE $expensesTable ADD COLUMN type TEXT NOT NULL DEFAULT 'expense'",
          );

          await _createModelConfigsTable(db);
          await _seedDefaultModels(db);
        }
      },
    );

    return _database!;
  }

  Future<void> _createExpensesTable(Database db) async {
    await db.execute('''
      CREATE TABLE $expensesTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        currency TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'expense',
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createModelConfigsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $modelConfigsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task TEXT NOT NULL,
        model_id TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _seedDefaultModels(Database db) async {
    await _ensureDefaultModel(db, task: 'stt', modelId: 'speech_to_text');
    await _ensureDefaultModel(db, task: 'nlu', modelId: 'regex_local');
  }

  Future<void> _ensureDefaultModel(
    Database db, {
    required String task,
    required String modelId,
  }) async {
    final List<Map<String, Object?>> existing = await db.query(
      modelConfigsTable,
      where: 'task = ? AND is_active = 1',
      whereArgs: <Object>[task],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return;
    }

    await db.insert(modelConfigsTable, <String, Object?>{
      'task': task,
      'model_id': modelId,
      'is_active': 1,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
