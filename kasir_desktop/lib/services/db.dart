// lib/services/db.dart
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  sql.Database? _db;

  // ----------------------------- Open / Schema ------------------------------

  Future<sql.Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<sql.Database> _open() async {
    // FFI untuk desktop (Windows/macOS/Linux)
    sqfliteFfiInit();
    sql.databaseFactory = databaseFactoryFfi;

    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    final dbPath = p.join(dir.path, 'kasir_pos.sqlite');

    final db = await sql.openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, _) async => _createCoreTables(db),
      onOpen: (db) async {
        await _createCoreTables(db); // pastikan ada
        await _migrateSalesTable(db); // tambah kolom baru bila kurang
        await _ensureSaleItemsTable(db);
      },
    );
    return db;
  }

  Future<void> _createCoreTables(sql.Database db) async {
    // Tabel users untuk autentikasi
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL CHECK(role IN ('admin', 'karyawan')),
        full_name TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        last_login TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        description TEXT,
        price REAL NOT NULL DEFAULT 0,
        stock INTEGER NOT NULL DEFAULT 0,
        image_path TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total REAL NOT NULL,
        discount REAL NOT NULL DEFAULT 0,
        tax REAL NOT NULL DEFAULT 0,
        cash REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        qty INTEGER NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY(sale_id) REFERENCES sales(id),
        FOREIGN KEY(product_id) REFERENCES products(id)
      );
    ''');

    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_name ON products(name);');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);');
    await db
        .execute('CREATE INDEX IF NOT EXISTS idx_sales_created ON sales(created_at);');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON sale_items(sale_id);');
  }

  Future<Set<String>> _tableColumns(sql.Database db, String table) async {
    final info = await db.rawQuery("PRAGMA table_info($table)");
    return info.map((e) => (e['name'] as String).toLowerCase()).toSet();
  }

  Future<void> _migrateSalesTable(sql.Database db) async {
    final cols = await _tableColumns(db, 'sales');

    if (!cols.contains('discount')) {
      await db.execute(
          "ALTER TABLE sales ADD COLUMN discount REAL NOT NULL DEFAULT 0");
    }
    if (!cols.contains('tax')) {
      await db.execute("ALTER TABLE sales ADD COLUMN tax REAL NOT NULL DEFAULT 0");
    }
    if (!cols.contains('cash')) {
      await db.execute("ALTER TABLE sales ADD COLUMN cash REAL NOT NULL DEFAULT 0");
    }
    if (!cols.contains('created_at')) {
      await db.execute("ALTER TABLE sales ADD COLUMN created_at TEXT");
      await db.rawUpdate(
          "UPDATE sales SET created_at = COALESCE(created_at, datetime('now')) WHERE created_at IS NULL OR created_at = ''");
      await db.execute(
          "CREATE INDEX IF NOT EXISTS idx_sales_created ON sales(created_at)");
    }
  }

  Future<void> _ensureSaleItemsTable(sql.Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sale_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        qty INTEGER NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY(sale_id) REFERENCES sales(id),
        FOREIGN KEY(product_id) REFERENCES products(id)
      );
    ''');
  }

  // Utility publik
  Future<bool> isSchemaReady() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT name FROM sqlite_master
      WHERE type='table' AND name IN ('products','sales','sale_items');
    ''');
    return rows.length == 3;
  }

  Future<void> initSchema() async {
    final db = await database;
    await _createCoreTables(db);
    await _migrateSalesTable(db);
    await _ensureSaleItemsTable(db);
    await seedDefaultUsersIfEmpty();
  }

  Future<void> seedSampleProductsIfEmpty() async {
    final db = await database;
    final cnt = sql.Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM products'),
        ) ??
        0;
    if (cnt > 0) return;

    final batch = db.batch();
    batch.insert('products', {
      'name': 'Air Mineral 600ml',
      'category': 'Minuman',
      'price': 4000,
      'stock': 50
    });
    batch.insert('products', {
      'name': 'Kopi Sachet',
      'category': 'Minuman',
      'price': 3000,
      'stock': 80
    });
    batch.insert('products', {
      'name': 'Roti Tawar',
      'category': 'Makanan',
      'price': 12000,
      'stock': 20
    });
    await batch.commit(noResult: true);
  }

  Future<void> seedDefaultUsersIfEmpty() async {
    final db = await database;
    final cnt = sql.Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM users'),
        ) ??
        0;
    if (cnt > 0) return;

    final batch = db.batch();
    
    // Admin default
    batch.insert('users', {
      'username': 'admin',
      'password': 'admin123',
      'role': 'admin',
      'full_name': 'Administrator',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    // Karyawan default
    batch.insert('users', {
      'username': 'karyawan',
      'password': 'karyawan123',
      'role': 'karyawan',
      'full_name': 'Karyawan',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    await batch.commit(noResult: true);
  }

  // ------------------------------- User Management -----------------------------------

  Future<Map<String, dynamic>?> authenticateUser(String username, String password) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT id, username, role, full_name, is_active
      FROM users 
      WHERE username = ? AND password = ? AND is_active = 1
      LIMIT 1
    ''', [username, password]);
    
    if (result.isEmpty) return null;
    
    final user = result.first;
    
    // Update last_login
    await db.update(
      'users',
      {'last_login': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [user['id']],
    );
    
    return {
      'id': user['id'],
      'username': user['username'],
      'role': user['role'],
      'full_name': user['full_name'],
    };
  }

  Future<List<Map<String, Object?>>> getAllUsers() async {
    final db = await database;
    return db.rawQuery('''
      SELECT id, username, role, full_name, is_active, created_at, last_login
      FROM users
      ORDER BY created_at DESC
    ''');
  }

  Future<int> createUser({
    required String username,
    required String password,
    required String role,
    required String fullName,
    bool isActive = true,
  }) async {
    final db = await database;
    return db.insert('users', {
      'username': username,
      'password': password,
      'role': role,
      'full_name': fullName,
      'is_active': isActive ? 1 : 0,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int> updateUser({
    required int id,
    String? password,
    String? role,
    String? fullName,
    bool? isActive,
  }) async {
    final db = await database;
    final data = <String, dynamic>{};
    
    if (password != null) data['password'] = password;
    if (role != null) data['role'] = role;
    if (fullName != null) data['full_name'] = fullName;
    if (isActive != null) data['is_active'] = isActive ? 1 : 0;
    
    if (data.isEmpty) return 0;
    
    return db.update('users', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------------------- Produk -----------------------------------

  Future<int> insertProduct({
    required String name,
    String? category,
    String? description,
    required num price,
    required int stock,
    String? imagePath,
  }) async {
    final db = await database;
    return db.insert('products', {
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'stock': stock,
      'image_path': imagePath,
    });
  }

  Future<int> updateProduct({
    required int id,
    required String name,
    String? category,
    String? description,
    required num price,
    required int stock,
    String? imagePath,
  }) async {
    final db = await database;
    return db.update(
      'products',
      {
        'name': name,
        'category': category,
        'description': description,
        'price': price,
        'stock': stock,
        'image_path': imagePath,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  /// Ambil daftar kategori unik
  Future<List<String>> getCategories() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT DISTINCT COALESCE(NULLIF(TRIM(category),''),'Tanpa Kategori') AS cat
      FROM products
      ORDER BY cat
    ''');
    return rows.map((e) => (e['cat'] as String)).toList();
  }

  /// List produk dengan filter pencarian & kategori.
  Future<List<Map<String, Object?>>> products({
    String? query,
    String? category,
    bool inStockOnly = false,
    String orderBy = 'name COLLATE NOCASE ASC',
    int? limit,
    int? offset,
  }) async {
    final db = await database;

    final where = <String>[];
    final args = <Object?>[];

    if (query != null && query.trim().isNotEmpty) {
      where.add('(name LIKE ? OR description LIKE ?)');
      final like = '%${query.trim()}%';
      args..add(like)..add(like);
    }
    if (category != null && category.isNotEmpty) {
      where.add('category = ?');
      args.add(category);
    }
    if (inStockOnly) {
      where.add('stock > 0');
    }

    final whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';
    final lim = (limit == null) ? '' : 'LIMIT $limit';
    final off = (offset == null) ? '' : 'OFFSET $offset';

    return db.rawQuery('''
      SELECT id, name, category, description, price, stock, image_path
      FROM products
      $whereSql
      ORDER BY $orderBy
      $lim $off
    ''', args);
  }

  /// Versi ringkas untuk POS
  Future<List<Map<String, Object?>>> productsForSale({
    String? query,
    String? category,
  }) {
    // POS: tampilkan semua (stok 0 -> tombol tambah disabled)
    return products(query: query, category: category, inStockOnly: false);
  }

  // ---------------------------- Transaksi / POS -----------------------------

  /// Simpan transaksi + kurangi stok. `items`: {product_id, qty, price}
  Future<int> processSale({
    required List<Map<String, dynamic>> items,
    required num total,
    num discount = 0,
    num tax = 0,
    num cash = 0,
  }) async {
    final db = await database;

    return await db.transaction<int>((txn) async {
      final saleId = await txn.insert('sales', {
        'total': total,
        'discount': discount,
        'tax': tax,
        'cash': cash,
        'created_at': DateTime.now().toIso8601String(),
      });

      for (final it in items) {
        final pid = it['product_id'] as int;
        final qty = it['qty'] as int;
        final price = (it['price'] as num);

        await txn.insert('sale_items', {
          'sale_id': saleId,
          'product_id': pid,
          'qty': qty,
          'price': price,
        });

        // Kurangi stok (tidak biarkan minus)
        final cur = sql.Sqflite.firstIntValue(
              await txn.rawQuery('SELECT stock FROM products WHERE id = ?', [pid]),
            ) ??
            0;
        final newStock = (cur - qty).clamp(0, 1 << 31);
        await txn.update(
          'products',
          {'stock': newStock},
          where: 'id = ?',
          whereArgs: [pid],
        );
      }

      return saleId;
    });
  }

  // ----------------------------- Riwayat ------------------------------------

  Future<List<Map<String, Object?>>> salesHistory({
    DateTime? from,
    DateTime? to,
    String? query,
    int limit = 200,
    int offset = 0,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <Object?>[];

    if (from != null) {
      where.add('datetime(created_at) >= datetime(?)');
      args.add(from.toIso8601String());
    }
    if (to != null) {
      where.add('datetime(created_at) <= datetime(?)');
      args.add(to.toIso8601String());
    }
    if (query != null && query.isNotEmpty) {
      where.add('CAST(id AS TEXT) LIKE ?');
      args.add('%$query%');
    }

    final whereSql = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';

    return db.rawQuery('''
      SELECT s.id, s.total, s.discount, s.tax, s.cash, s.created_at,
             (SELECT COALESCE(SUM(qty),0) FROM sale_items si WHERE si.sale_id = s.id) AS item_count
      FROM sales s
      $whereSql
      ORDER BY s.id DESC
      LIMIT $limit OFFSET $offset
    ''', args);
  }

  Future<List<Map<String, Object?>>> saleItems(int saleId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT si.qty, si.price, p.name
      FROM sale_items si
      JOIN products p ON p.id = si.product_id
      WHERE si.sale_id = ?
    ''', [saleId]);
  }

  // ======== COMPAT SHIMS: agar kode lama tetap jalan ========

  // Lama: DatabaseService.instance.open()
  Future<void> open() async {
    await database;     // memastikan kebuka
    await initSchema(); // memastikan tabel ada
  }

  // Lama: countProducts()
  Future<int> countProducts() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM products');
    if (rows.isEmpty) return 0;
    final v = rows.first['c'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  // Lama: searchProducts(query)
  Future<List<Map<String, Object?>>> searchProducts(String query) {
    return products(query: query);
  }

  // Lama: updateStock(id, stockBaru)
  Future<int> updateStock(int id, int stock) async {
    final db = await database;
    return db.update('products', {'stock': stock},
        where: 'id = ?', whereArgs: [id]);
  }

  // Lama: imagesDir() -> folder simpan gambar
  Future<String> imagesDir() async {
    final dir = await getApplicationSupportDirectory();
    final images = Directory(p.join(dir.path, 'images'));
    if (!await images.exists()) {
      await images.create(recursive: true);
    }
    return images.path;
  }

  // ---------------------------- Dashboard Analytics -----------------------------

  Future<Map<String, dynamic>> getDashboardStats() async {
    final db = await database;
    
    // Total revenue hari ini
    final todayRevenue = sql.Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) 
      FROM sales 
      WHERE DATE(created_at) = DATE('now')
    ''')) ?? 0;

    // Total revenue bulan ini
    final monthRevenue = sql.Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COALESCE(SUM(total), 0) 
      FROM sales 
      WHERE strftime('%Y-%m', created_at) = strftime('%Y-%m', 'now')
    ''')) ?? 0;

    // Total transaksi hari ini
    final todayTransactions = sql.Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) 
      FROM sales 
      WHERE DATE(created_at) = DATE('now')
    ''')) ?? 0;

    // Total transaksi bulan ini
    final monthTransactions = sql.Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) 
      FROM sales 
      WHERE strftime('%Y-%m', created_at) = strftime('%Y-%m', 'now')
    ''')) ?? 0;

    // Total produk
    final totalProducts = sql.Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COUNT(*) FROM products
    ''')) ?? 0;

    // Total nilai inventory
    final inventoryValue = sql.Sqflite.firstIntValue(await db.rawQuery('''
      SELECT COALESCE(SUM(price * stock), 0) FROM products
    ''')) ?? 0;

    return {
      'todayRevenue': todayRevenue,
      'monthRevenue': monthRevenue,
      'todayTransactions': todayTransactions,
      'monthTransactions': monthTransactions,
      'totalProducts': totalProducts,
      'inventoryValue': inventoryValue,
    };
  }

  Future<List<Map<String, Object?>>> getLowStockProducts({int threshold = 10}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT id, name, category, stock, price
      FROM products 
      WHERE stock <= ?
      ORDER BY stock ASC, name ASC
      LIMIT 20
    ''', [threshold]);
  }

  Future<List<Map<String, Object?>>> getTopSellingProducts({int limit = 10}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT p.name, p.category, SUM(si.qty) as total_sold, SUM(si.qty * si.price) as revenue
      FROM sale_items si
      JOIN products p ON p.id = si.product_id
      JOIN sales s ON s.id = si.sale_id
      WHERE strftime('%Y-%m', s.created_at) = strftime('%Y-%m', 'now')
      GROUP BY p.id, p.name, p.category
      ORDER BY total_sold DESC
      LIMIT ?
    ''', [limit]);
  }

  Future<List<Map<String, Object?>>> getDailySales({int days = 7}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT 
        DATE(created_at) as date,
        COUNT(*) as transaction_count,
        COALESCE(SUM(total), 0) as revenue
      FROM sales 
      WHERE DATE(created_at) >= DATE('now', '-$days days')
      GROUP BY DATE(created_at)
      ORDER BY DATE(created_at) DESC
    ''');
  }

  Future<Map<String, dynamic>> getTodayDetailedStats() async {
    final db = await database;
    
    // Revenue dan transaksi hari ini
    final revenueResult = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(total), 0) as revenue,
        COUNT(*) as transactions
      FROM sales 
      WHERE DATE(created_at) = DATE('now')
    ''');
    
    // Items terjual hari ini
    final itemsResult = await db.rawQuery('''
      SELECT COALESCE(SUM(si.qty), 0) as items_sold
      FROM sale_items si
      JOIN sales s ON s.id = si.sale_id
      WHERE DATE(s.created_at) = DATE('now')
    ''');
    
    final revenue = (revenueResult.first['revenue'] as num?) ?? 0;
    final transactions = (revenueResult.first['transactions'] as int?) ?? 0;
    final itemsSold = (itemsResult.first['items_sold'] as int?) ?? 0;
    
    return {
      'revenue': revenue,
      'transactions': transactions,
      'itemsSold': itemsSold,
    };
  }

  // Lama: addProduct(name, category, price, stock [, imagePath, description])
  Future<int> addProduct(
    String name,
    String? category,
    num price,
    int stock, [
    String? imagePath,
    String? description,
  ]) async {
    return insertProduct(
      name: name,
      category: category,
      description: description,
      price: price,
      stock: stock,
      imagePath: imagePath,
    );
  }
}
