import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../models/pending_action_model.dart';

class PendingActionsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insertAction(PendingAction action) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'pending_actions',
      action.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<PendingAction>> getPendingActions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pending_actions',
      where: "status = ?",
      whereArgs: ['pending'],
      orderBy: 'id ASC',
    );
    return List.generate(maps.length, (i) {
      return PendingAction.fromMap(maps[i]);
    });
  }

  Future<int> getPendingActionsCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) FROM pending_actions WHERE status = ?',
      ['pending'],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> deleteAction(int id) async {
    final db = await _dbHelper.database;
    await db.delete(
      'pending_actions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateActionStatus(int id, String status) async {
    final db = await _dbHelper.database;
    await db.update(
      'pending_actions',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> hasPendingPutAction(String endpoint) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'pending_actions',
      where: 'endpoint = ? AND method = ? AND status = ?',
      whereArgs: [endpoint, 'PUT', 'pending'],
    );
    return result.isNotEmpty;
  }

  Future<void> updateActionPayload(int id, String newPayload) async {
    final db = await _dbHelper.database;
    await db.update(
      'pending_actions',
      {'payload': newPayload},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<PendingAction>> getPendingOrderActions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pending_actions',
      where: "status = ? AND endpoint LIKE ? AND method = ?",
      whereArgs: ['pending', '%/orders', 'POST'],
      orderBy: 'id ASC',
    );
    return maps.map(PendingAction.fromMap).toList();
  }

  Future<List<PendingAction>> getFailedOrderActions() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pending_actions',
      where: "status = ? AND endpoint LIKE ? AND method = ?",
      whereArgs: ['failed', '%/orders', 'POST'],
      orderBy: 'id ASC',
    );
    return maps.map(PendingAction.fromMap).toList();
  }
}
