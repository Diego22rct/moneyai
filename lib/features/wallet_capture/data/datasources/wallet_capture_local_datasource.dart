import 'package:moneyai/features/expenses/data/services/sqlite_service.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/wallet_capture.dart';
import 'package:sqflite/sqflite.dart';

class WalletCaptureLocalDataSource {
  WalletCaptureLocalDataSource(this._sqliteService);

  final SQLiteService _sqliteService;

  Future<bool> insertIfAbsent(WalletCapture capture) async {
    final db = await _sqliteService.database;
    final map = capture.toMap()..remove('id');

    final id = await db.insert(
      SQLiteService.walletCapturesTable,
      map,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    return id > 0;
  }

  Future<List<WalletCapture>> listPending() async {
    final db = await _sqliteService.database;
    final rows = await db.query(
      SQLiteService.walletCapturesTable,
      where: 'status = ?',
      whereArgs: <Object>[WalletCaptureStatus.pending.name],
      orderBy: 'posted_at DESC',
    );
    return rows.map(WalletCapture.fromMap).toList();
  }

  Future<void> markConfirmed(int id, int expenseId) async {
    final db = await _sqliteService.database;
    // Wipe raw notification texts on confirmation for user privacy
    await db.update(
      SQLiteService.walletCapturesTable,
      <String, Object?>{
        'status': WalletCaptureStatus.confirmed.name,
        'expense_id': expenseId,
        'raw_title': null,
        'raw_text': null,
      },
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }

  Future<void> dismiss(int id) async {
    final db = await _sqliteService.database;
    // Wipe raw notification texts on dismissal for user privacy
    await db.update(
      SQLiteService.walletCapturesTable,
      <String, Object?>{
        'status': WalletCaptureStatus.dismissed.name,
        'raw_title': null,
        'raw_text': null,
      },
      where: 'id = ?',
      whereArgs: <Object>[id],
    );
  }
}
