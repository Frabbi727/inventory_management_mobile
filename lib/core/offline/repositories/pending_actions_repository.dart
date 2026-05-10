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

  Future<bool> hasPendingUpdate(String endpoint) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'pending_actions',
      where: 'endpoint = ? AND status = ?',
      whereArgs: [endpoint, 'pending'],
    );
    return result.isNotEmpty;
  }
}
