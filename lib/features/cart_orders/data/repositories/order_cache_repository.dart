import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../../core/offline/database_helper.dart';
import '../models/order_model.dart';

class OrderCacheRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> saveOrders(List<OrderModel> orders) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (var order in orders) {
      if (order.id == null) continue;
      
      batch.insert(
        'cached_orders',
        {
          'id': order.id,
          'order_no': order.orderNo,
          'status': order.status,
          'data': jsonEncode(order.toJson()),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveOrder(OrderModel order) async {
    if (order.id == null) return;
    
    final db = await _dbHelper.database;
    await db.insert(
      'cached_orders',
      {
        'id': order.id,
        'order_no': order.orderNo,
        'status': order.status,
        'data': jsonEncode(order.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<OrderModel>> getOrders({String? status}) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> maps;

    if (status != null && status.isNotEmpty) {
      maps = await db.query(
        'cached_orders',
        where: 'status = ?',
        whereArgs: [status],
      );
    } else {
      maps = await db.query('cached_orders');
    }

    return List.generate(maps.length, (i) {
      final data = jsonDecode(maps[i]['data'] as String) as Map<String, dynamic>;
      return OrderModel.fromJson(data);
    });
  }

  Future<OrderModel?> getOrderById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cached_orders',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    final data = jsonDecode(maps[0]['data'] as String) as Map<String, dynamic>;
    return OrderModel.fromJson(data);
  }

  Future<void> deleteOrder(int id) async {
    final db = await _dbHelper.database;
    await db.delete('cached_orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearCache() async {
    final db = await _dbHelper.database;
    await db.delete('cached_orders');
  }
}
