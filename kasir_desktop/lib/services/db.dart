import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  Database? _db;
  Database get db => _db!;

  Future<String> _baseDir() async => Directory.current.path;

  Future<String> imagesDir() async {
    final base = await _baseDir();
    final dir = Directory(p.join(base, 'images'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir.path;
  }

  Future<void> open() async {
    if (_db != null) return;
    final path = p.join(await _baseDir(), 'kasir_inventory.db');
    _db = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, v) async => _createV2(db),
        onUpgrade: (db, oldV, newV) async {
          if (oldV < 2) {
            await db.execute('ALTER TABLE products ADD COLUMN category TEXT;');
            await db.execute('ALTER TABLE products ADD COLUMN description TEXT;');
            await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT;');
            await db.execute('ALTER TABLE products ADD COLUMN active INTEGER NOT NULL DEFAULT 1;');
          }
        },
      ),
    );
  }

  Future<void> _createV2(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        category TEXT,
        description TEXT,
        image_path TEXT,
        active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        total REAL NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');
  }

  Future<int> countProducts() async {
    final res = await db.rawQuery('SELECT COUNT(*) as c FROM products');
    return _firstInt(res, 'c');
  }

  Future<List<Map<String, Object?>>> searchProducts({String? query, String? category}) async {
    final where = <String>[];
    final args = <Object?>[];
    if (query != null && query.isNotEmpty) {
      where.add('(name LIKE ? OR COALESCE(description, "") LIKE ?)');
      args..add('%$query%')..add('%$query%');
    }
    if (category != null && category.isNotEmpty) {
      where.add('COALESCE(category, "") = ?');
      args.add(category);
    }
    return db.query(
      'products',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : args,
      orderBy: 'name COLLATE NOCASE ASC',
    );
  }

  // === dipakai halaman Kasir ===
  Future<List<Map<String, Object?>>> productsForSale({String? query, String? category}) async {
    final where = <String>['active = 1'];
    final args = <Object?>[];
    if (query != null && query.isNotEmpty) {
      where.add('(name LIKE ? OR COALESCE(description, "") LIKE ?)');
      args..add('%$query%')..add('%$query%');
    }
    if (category != null && category.isNotEmpty) {
      where.add('COALESCE(category, "") = ?');
      args.add(category);
    }
    return db.query(
      'products',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'name COLLATE NOCASE ASC',
    );
  }

  Future<List<String>> getCategories() async {
    final rows = await db.rawQuery(
      'SELECT DISTINCT category FROM products '
      'WHERE category IS NOT NULL AND category <> "" '
      'ORDER BY category');
    return rows.map((e) => (e['category'] as String)).toList();
  }

  Future<int> addProduct({
    required String name,
    required double price,
    required int stock,
    String? category,
    String? description,
    String? imagePath,
    bool active = true,
  }) async {
    return db.insert('products', {
      'name': name,
      'price': price,
      'stock': stock,
      'category': category,
      'description': description,
      'image_path': imagePath,
      'active': active ? 1 : 0,
    });
  }

  Future<int> updateStock({required int productId, required int stock}) async {
    return db.update('products', {'stock': stock}, where: 'id = ?', whereArgs: [productId]);
  }

  Future<void> deleteProduct(int id) async {
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  /// Simpan transaksi penjualan (total sudah NET setelah diskon)
  /// items = [{'product_id': int, 'qty': int, 'price': num}]
  Future<int> processSale({
    required List<Map<String, dynamic>> items,
    required num total,
    DateTime? date,
  }) async {
    return db.transaction<int>((txn) async {
      final saleId = await txn.insert('sales', {
        'date': (date ?? DateTime.now()).toIso8601String(),
        'total': total.toDouble(),
      });
      for (final it in items) {
        final pid = it['product_id'] as int;
        final qty = it['qty'] as int;
        final price = (it['price'] as num).toDouble();
        await txn.insert('sale_items', {
          'sale_id': saleId,
          'product_id': pid,
          'quantity': qty,
          'price': price,
        });
        await txn.rawUpdate('UPDATE products SET stock = stock - ? WHERE id = ?', [qty, pid]);
      }
      return saleId;
    });
  }

  int _firstInt(List<Map<String, Object?>> rows, String key) {
    if (rows.isEmpty) return 0;
    final v = rows.first[key];
    if (v is int) return v;
    if (v is BigInt) return v.toInt();
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
