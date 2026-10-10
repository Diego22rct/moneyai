import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class SQLiteService {
  static const String expensesTable = 'expenses';
  static const String modelConfigsTable = 'model_configs';
  static const String modelRuntimeConfigsTable = 'model_runtime_configs';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final String dbPath = await getDatabasesPath();
    final String path = p.join(dbPath, 'moneyai.db');

    _database = await openDatabase(
      path,
      version: 4,
      onCreate: (Database db, int version) async {
        await _createExpensesTable(db);
        await _createModelConfigsTable(db);
        await _createModelRuntimeConfigsTable(db);
        await _seedDefaultModels(db);
        await _seedDefaultRuntimeConfig(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE $expensesTable ADD COLUMN type TEXT NOT NULL DEFAULT 'expense'",
          );

          await _createModelConfigsTable(db);
          await _seedDefaultModels(db);
        }

        if (oldVersion < 3) {
          await _createModelRuntimeConfigsTable(db);
          await _seedDefaultRuntimeConfig(db);
        }

        if (oldVersion < 4) {
          await db.execute(
            "ALTER TABLE $expensesTable ADD COLUMN tags_json TEXT NOT NULL DEFAULT '[]'",
          );
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
        tags_json TEXT NOT NULL DEFAULT '[]',
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

  Future<void> _createModelRuntimeConfigsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $modelRuntimeConfigsTable (
        task TEXT PRIMARY KEY,
        model_path TEXT,
        native_lib_path TEXT,
        whisper_variant TEXT NOT NULL DEFAULT 'tiny',
        updated_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _seedDefaultModels(Database db) async {
    await _ensureDefaultModel(db, task: 'stt', modelId: 'speech_to_text');
    await _ensureDefaultModel(db, task: 'nlu', modelId: 'regex_local');
  }

  Future<void> _seedDefaultRuntimeConfig(Database db) async {
    await _ensureDefaultRuntimeConfig(db, task: 'stt');
    await _ensureDefaultRuntimeConfig(db, task: 'nlu');
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

  Future<void> _ensureDefaultRuntimeConfig(
    Database db, {
    required String task,
  }) async {
    final List<Map<String, Object?>> existing = await db.query(
      modelRuntimeConfigsTable,
      where: 'task = ?',
      whereArgs: <Object>[task],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return;
    }

    await db.insert(modelRuntimeConfigsTable, <String, Object?>{
      'task': task,
      'model_path': null,
      'native_lib_path': null,
      'whisper_variant': 'tiny',
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
