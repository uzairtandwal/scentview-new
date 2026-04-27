import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product_model.dart';
import '../models/banner.dart'; 
import '../models/address_model.dart';
import 'dart:convert';

class DBHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'scentview.db');
    return await openDatabase(
      path,
      version: 9, // Incremented version to add missing product columns
      onCreate: (db, version) async {
        await _createProductTable(db);
        await _createBannerTable(db);
        await _createAddressTable(db);
        await _createSearchHistoryTable(db);
        await _createCategoryTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 6) {
          // Drop and recreate product table to fix schema mismatch
          await db.execute('DROP TABLE IF EXISTS products');
          await _createProductTable(db);
          
          if (oldVersion < 4) {
            await _createAddressTable(db);
          }
          await db.execute('DROP TABLE IF EXISTS search_history');
          await _createSearchHistoryTable(db);
        }
        if (oldVersion < 7) {
          await _createCategoryTable(db);
        }
        if (oldVersion < 8) {
          // Add slug column to categories
          await db.execute('DROP TABLE IF EXISTS categories');
          await _createCategoryTable(db);
        }
        if (oldVersion < 9) {
          // Add missing columns to products table
          await db.execute('DROP TABLE IF EXISTS products');
          await _createProductTable(db);
        }
      },
    );
  }

  // === TABLE CREATION LOGIC ===
  
  Future<void> _createProductTable(Database db) async {
    await db.execute('''
      CREATE TABLE products(
        id TEXT PRIMARY KEY,
        name TEXT,
        description TEXT,
        price REAL,
        sale_price REAL,
        image_url TEXT,
        image_url_100ml TEXT,
        images_json TEXT,
        images_50ml_json TEXT,
        images_100ml_json TEXT,
        variants_json TEXT,
        category TEXT,
        scent_family TEXT,
        brand TEXT,
        size TEXT,
        quantity INTEGER,
        price_100ml REAL,
        quantity_100ml INTEGER,
        notes_top TEXT,
        notes_middle TEXT,
        notes_base TEXT,
        is_featured INTEGER,
        is_slider INTEGER,
        badge_text TEXT,
        sku TEXT,
        is_active INTEGER,
        tags_json TEXT,
        customer_product_name TEXT
      )
    ''');
  }

  Future<void> _createBannerTable(Database db) async {
    await db.execute('''
      CREATE TABLE banners(
        id TEXT PRIMARY KEY,
        title TEXT,
        image_url TEXT,
        target_screen TEXT,
        target_id TEXT,
        is_active INTEGER,
        description TEXT,
        sort_order INTEGER
      )
    ''');
  }

  Future<void> _createCategoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE categories(
        id TEXT PRIMARY KEY,
        name TEXT,
        slug TEXT,
        image_url TEXT
      )
    ''');
  }

  Future<void> _createAddressTable(Database db) async {
    await db.execute('''
      CREATE TABLE addresses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        fullName TEXT,
        phone TEXT,
        fullAddress TEXT,
        isDefault INTEGER
      )
    ''');
  }
  
  Future<void> _createSearchHistoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE search_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        query TEXT, 
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  // === PRODUCT METHODS ===
  
  Future<void> insertProducts(List<Product> products) async {
    try {
      final db = await database;
      await db.delete('products'); 
      
      Batch batch = db.batch();
      for (var product in products) {
        batch.insert(
          'products',
          product.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      print("❌ DBHelper Product Insert Error: $e");
    }
  }

  Future<List<Product>> getProducts() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('products');
      return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
    } catch (e) {
      print("❌ DBHelper Product Get Error: $e");
      return [];
    }
  }

  // === BANNER METHODS ===

  Future<void> insertBanners(List<Banner> banners) async {
    try {
      final db = await database;
      await db.delete('banners'); 
      Batch batch = db.batch();
      for (var banner in banners) {
        batch.insert('banners', banner.toDbMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      print("❌ DBHelper Banner Error: $e");
    }
  }

  Future<List<Banner>> getBanners() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('banners', orderBy: 'sort_order ASC');
    return List.generate(maps.length, (i) => Banner.fromDbMap(maps[i]));
  }

  // === ADDRESS METHODS ===

  Future<void> insertAddress(UserAddress address) async {
    final db = await database;
    await db.insert(
      'addresses',
      address.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<UserAddress>> getAddresses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('addresses');
    return List.generate(maps.length, (i) {
      return UserAddress(
        id: maps[i]['id'],
        title: maps[i]['title'],
        fullName: maps[i]['fullName'],
        phone: maps[i]['phone'],
        fullAddress: maps[i]['fullAddress'],
        isDefault: maps[i]['isDefault'] == 1,
      );
    });
  }

  Future<void> deleteAddress(int id) async {
    final db = await database;
    await db.delete('addresses', where: 'id = ?', whereArgs: [id]);
  }

  // === SEARCH HISTORY METHODS ===
  
  Future<void> saveSearchQuery(String query) async {
    final db = await database;
    await db.delete('search_history', where: 'query = ?', whereArgs: [query]);
    await db.insert('search_history', {'query': query});
  }

  Future<List<String>> getRecentSearches() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('search_history', orderBy: 'timestamp DESC', limit: 5);
      return List.generate(maps.length, (i) => maps[i]['query'] as String);
    } catch (e) {
      return [];
    }
  }

  Future<void> clearSearchHistory() async {
    final db = await database;
    await db.delete('search_history');
  }

  // === CATEGORY METHODS ===

  Future<void> insertCategories(List<Map<String, dynamic>> categories) async {
    try {
      final db = await database;
      await db.delete('categories');
      Batch batch = db.batch();
      for (var cat in categories) {
        batch.insert('categories', cat, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    } catch (e) {
      print("❌ DBHelper Category Error: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final db = await database;
      return await db.query('categories');
    } catch (e) {
      print("❌ DBHelper Category Get Error: $e");
      return [];
    }
  }
}
