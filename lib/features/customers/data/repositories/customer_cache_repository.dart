import 'package:sqflite/sqflite.dart';
import '../../../../core/offline/database_helper.dart';
import '../models/customer_model.dart';

class CustomerCacheRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<void> saveCustomers(List<CustomerModel> customers) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    for (var customer in customers) {
      batch.insert(
        'cached_customers',
        {
          'id': customer.id,
          'name': customer.name,
          'phone': customer.phone,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<CustomerModel>> getCustomers({String? query}) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> maps;

    if (query != null && query.isNotEmpty) {
      maps = await db.query(
        'cached_customers',
        where: 'name LIKE ? OR phone LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
      );
    } else {
      maps = await db.query('cached_customers');
    }

    return List.generate(maps.length, (i) {
      return CustomerModel(
        id: maps[i]['id'],
        name: maps[i]['name'],
        phone: maps[i]['phone'],
      );
    });
  }

  Future<void> clearCustomers() async {
    final db = await _dbHelper.database;
    await db.delete('cached_customers');
  }
}
