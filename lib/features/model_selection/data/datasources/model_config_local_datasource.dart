import 'package:moneyai/features/expenses/data/services/sqlite_service.dart';
import 'package:moneyai/features/model_selection/domain/entities/model_option.dart';

class ModelConfigLocalDataSource {
  ModelConfigLocalDataSource(this._sqliteService);

  final SQLiteService _sqliteService;

  Future<String> getActiveModelId(AiTask task) async {
    final db = await _sqliteService.database;

    final rows = await db.query(
      SQLiteService.modelConfigsTable,
      where: 'task = ? AND is_active = 1',
      whereArgs: <Object>[task.key],
      limit: 1,
    );

    if (rows.isEmpty) {
      final String fallback = task == AiTask.stt
          ? 'speech_to_text'
          : 'regex_local';
      await setActiveModel(task: task, modelId: fallback);
      return fallback;
    }

    return rows.first['model_id']! as String;
  }

  Future<void> setActiveModel({
    required AiTask task,
    required String modelId,
  }) async {
    final db = await _sqliteService.database;

    await db.transaction((txn) async {
      await txn.update(
        SQLiteService.modelConfigsTable,
        <String, Object?>{'is_active': 0},
        where: 'task = ?',
        whereArgs: <Object>[task.key],
      );

      final rows = await txn.query(
        SQLiteService.modelConfigsTable,
        where: 'task = ? AND model_id = ?',
        whereArgs: <Object>[task.key, modelId],
        limit: 1,
      );

      if (rows.isEmpty) {
        await txn.insert(SQLiteService.modelConfigsTable, <String, Object?>{
          'task': task.key,
          'model_id': modelId,
          'is_active': 1,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
      } else {
        await txn.update(
          SQLiteService.modelConfigsTable,
          <String, Object?>{'is_active': 1},
          where: 'id = ?',
          whereArgs: <Object>[rows.first['id']!],
        );
      }
    });
  }
}
