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
          'address': customer.address,
          'area': customer.area,
          'local_mobile_ref': customer.localMobileRef,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveCustomer(CustomerModel customer) async {
    final db = await _dbHelper.database;
    await db.insert(
      'cached_customers',
      {
        'id': customer.id,
        'name': customer.name,
        'phone': customer.phone,
        'address': customer.address,
        'area': customer.area,
        'local_mobile_ref': customer.localMobileRef,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CustomerModel>> getCustomers({String? query}) async {
    final db = await _dbHelper.database;
    List<Map<String, dynamic>> maps;

    if (query != null && query.isNotEmpty) {
      maps = await db.query(
        'cached_customers',
        where: 'name LIKE ? OR phone LIKE ? OR area LIKE ?',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
      );
    } else {
      maps = await db.query('cached_customers');
    }

    return List.generate(maps.length, (i) {
      return CustomerModel(
        id: maps[i]['id'] as int?,
        name: maps[i]['name'] as String?,
        phone: maps[i]['phone'] as String?,
        address: maps[i]['address'] as String?,
        area: maps[i]['area'] as String?,
        localMobileRef: maps[i]['local_mobile_ref'] as String?,
      );
    });
  }

  Future<void> clearCustomers() async {
    final db = await _dbHelper.database;
    await db.delete('cached_customers');
  }

  Future<CustomerModel?> getCustomerById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'cached_customers',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) {
      return null;
    }

    return CustomerModel(
      id: maps[0]['id'] as int?,
      name: maps[0]['name'] as String?,
      phone: maps[0]['phone'] as String?,
      address: maps[0]['address'] as String?,
      area: maps[0]['area'] as String?,
      localMobileRef: maps[0]['local_mobile_ref'] as String?,
    );
  }

  /// Replaces the temp-negative-ID row (identified by local_mobile_ref) with the real server ID.
  Future<void> updateCustomerWithRealId(String mobileRef, int realId) async {
    final db = await _dbHelper.database;
    final existing = await db.query(
      'cached_customers',
      where: 'local_mobile_ref = ?',
      whereArgs: [mobileRef],
    );

    if (existing.isEmpty) return;

    final oldId = existing[0]['id'] as int?;
    if (oldId == null) return;

    await db.delete(
      'cached_customers',
      where: 'id = ?',
      whereArgs: [oldId],
    );

    await db.insert(
      'cached_customers',
      {
        ...existing[0],
        'id': realId,
        'local_mobile_ref': null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
