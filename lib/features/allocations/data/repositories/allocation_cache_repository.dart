import 'package:sqflite/sqflite.dart';

import '../../../../core/offline/database_helper.dart';
import '../models/allocation_model.dart';

class AllocationCacheRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> saveItems(
    int allocationId,
    List<AllocationItemModel> items,
  ) async {
    final db = await _dbHelper.database;
    await db.delete(
      'cached_allocation_items',
      where: 'allocation_id = ?',
      whereArgs: [allocationId],
    );

    final batch = db.batch();
    for (final item in items) {
      batch.insert(
        'cached_allocation_items',
        {
          'id': item.id,
          'allocation_id': allocationId,
          'product_id': item.productId,
          'product_variant_id': item.productVariantId,
          'product_name_snapshot': item.productNameSnapshot,
          'unit_price_snapshot': item.unitPriceSnapshot,
          'quantity_allocated': item.quantityAllocated,
          'quantity_sold': item.quantitySold,
          'quantity_returned': item.quantityReturned,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<AllocationItemModel>> getItems(int allocationId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'cached_allocation_items',
      where: 'allocation_id = ?',
      whereArgs: [allocationId],
    );

    return maps.map((row) => AllocationItemModel(
      id: row['id'] as int,
      productId: row['product_id'] as int,
      productVariantId: row['product_variant_id'] as int?,
      productNameSnapshot: row['product_name_snapshot'] as String? ?? '',
      unitPriceSnapshot: (row['unit_price_snapshot'] as num?)?.toDouble() ?? 0,
      quantityAllocated: (row['quantity_allocated'] as num?)?.toDouble() ?? 0,
      quantitySold: (row['quantity_sold'] as num?)?.toDouble() ?? 0,
      quantityReturned: (row['quantity_returned'] as num?)?.toDouble() ?? 0,
    )).toList();
  }

  Future<void> decrementSold(int itemId, double qty) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE cached_allocation_items SET quantity_sold = quantity_sold + ? WHERE id = ?',
      [qty, itemId],
    );
  }

  Future<void> clear() async {
    final db = await _dbHelper.database;
    await db.delete('cached_allocation_items');
  }
}
