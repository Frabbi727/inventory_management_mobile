import 'package:sqflite/sqflite.dart';
import '../../../../core/offline/database_helper.dart';
import '../models/product_model.dart';

class ProductCacheRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> saveProducts(List<ProductModel> products) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (var product in products) {
      batch.insert(
        'cached_products',
        {
          'id': product.id,
          'name': product.name,
          'price': product.sellingPrice,
          'stock': product.currentStock,
          'has_variants': (product.hasVariants ?? false) ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<ProductModel>> getProducts({String? query}) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> maps;

    if (query != null && query.isNotEmpty) {
      maps = await db.query(
        'cached_products',
        where: 'name LIKE ?',
        whereArgs: ['%$query%'],
      );
    } else {
      maps = await db.query('cached_products');
    }

    return List.generate(maps.length, (i) {
      return ProductModel(
        id: maps[i]['id'],
        name: maps[i]['name'],
        sellingPrice: maps[i]['price'],
        currentStock: maps[i]['stock'],
        hasVariants: maps[i]['has_variants'] == 1,
      );
    });
  }

  Future<void> clearProducts() async {
    final db = await _dbHelper.database;
    await db.delete('cached_products');
  }

  Future<ProductModel?> getProductById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cached_products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return ProductModel(
      id: maps[0]['id'],
      name: maps[0]['name'],
      sellingPrice: maps[0]['price'],
      currentStock: maps[0]['stock'],
      hasVariants: maps[0]['has_variants'] == 1,
    );
  }
}
