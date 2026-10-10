import 'package:moneyai/features/expenses/data/services/sqlite_service.dart';
import 'package:moneyai/features/model_selection/domain/entities/model_option.dart';
import 'package:sqflite/sqflite.dart';

class AiRuntimeConfigLocalDataSource {
  AiRuntimeConfigLocalDataSource(this._sqliteService);

  final SQLiteService _sqliteService;

  Future<String?> getModelPath(AiTask task) async {
    final row = await _getConfigRow(task);
    return row?['model_path'] as String?;
  }

  Future<void> setModelPath({
    required AiTask task,
    required String? path,
  }) async {
    await _upsertTaskConfig(
      task: task,
      values: <String, Object?>{'model_path': _normalizeNullable(path)},
    );
  }

  Future<String?> getNativeLibPath(AiTask task) async {
    final row = await _getConfigRow(task);
    return row?['native_lib_path'] as String?;
  }

  Future<void> setNativeLibPath({
    required AiTask task,
    required String? path,
  }) async {
    await _upsertTaskConfig(
      task: task,
      values: <String, Object?>{'native_lib_path': _normalizeNullable(path)},
    );
  }

  Future<String> getWhisperVariant() async {
    final row = await _getConfigRow(AiTask.stt);
    final String? variant = row?['whisper_variant'] as String?;
    if (variant == null || variant.trim().isEmpty) {
      return 'tiny';
    }
    return variant;
  }

  Future<void> setWhisperVariant(String variant) async {
    final String normalized = variant.trim();
    await _upsertTaskConfig(
      task: AiTask.stt,
      values: <String, Object?>{
        'whisper_variant': normalized.isEmpty ? 'tiny' : normalized,
      },
    );
  }

  Future<Map<String, Object?>?> _getConfigRow(AiTask task) async {
    final db = await _sqliteService.database;
    final rows = await db.query(
      SQLiteService.modelRuntimeConfigsTable,
      where: 'task = ?',
      whereArgs: <Object>[task.key],
      limit: 1,
    );

    if (rows.isEmpty) {
      await _upsertTaskConfig(task: task, values: const <String, Object?>{});
      return _getConfigRow(task);
    }

    return rows.first;
  }

  Future<void> _upsertTaskConfig({
    required AiTask task,
    required Map<String, Object?> values,
  }) async {
    final db = await _sqliteService.database;

    final Map<String, Object?> payload = <String, Object?>{
      'task': task.key,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      ...values,
    };

    await db.insert(
      SQLiteService.modelRuntimeConfigsTable,
      payload,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  String? _normalizeNullable(String? value) {
    if (value == null) {
      return null;
    }

    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}
