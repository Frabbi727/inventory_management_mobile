import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'offline_database.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE cached_orders(
          id INTEGER PRIMARY KEY,
          order_no TEXT,
          status TEXT,
          data TEXT
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE cached_customers ADD COLUMN address TEXT',
      );
      await db.execute('ALTER TABLE cached_customers ADD COLUMN area TEXT');
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE cached_customers ADD COLUMN local_mobile_ref TEXT',
      );
      await db.execute('''
        CREATE TABLE IF NOT EXISTS cached_allocation_items(
          id INTEGER PRIMARY KEY,
          allocation_id INTEGER NOT NULL,
          product_id INTEGER NOT NULL,
          product_variant_id INTEGER,
          product_name_snapshot TEXT,
          unit_price_snapshot REAL,
          quantity_allocated REAL,
          quantity_sold REAL,
          quantity_returned REAL
        )
      ''');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pending_actions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        endpoint TEXT NOT NULL,
        method TEXT NOT NULL,
        payload TEXT NOT NULL,
        mobile_ref TEXT NOT NULL UNIQUE,
        status TEXT NOT NULL DEFAULT 'pending'
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_products(
        id INTEGER PRIMARY KEY,
        name TEXT,
        price REAL,
        stock INTEGER,
        has_variants INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_customers(
        id INTEGER PRIMARY KEY,
        name TEXT,
        phone TEXT,
        address TEXT,
        area TEXT,
        local_mobile_ref TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_orders(
        id INTEGER PRIMARY KEY,
        order_no TEXT,
        status TEXT,
        data TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cached_allocation_items(
        id INTEGER PRIMARY KEY,
        allocation_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_variant_id INTEGER,
        product_name_snapshot TEXT,
        unit_price_snapshot REAL,
        quantity_allocated REAL,
        quantity_sold REAL,
        quantity_returned REAL
      )
    ''');
  }
}
