import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'auth_database.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE,
        password TEXT,
        username TEXT UNIQUE,
        role INTEGER DEFAULT 2
      )
    ''');

    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL,
        image TEXT NOT NULL,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE cart(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        product_id INTEGER,
        quantity INTEGER,
        FOREIGN KEY (user_id) REFERENCES users (id),
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // Crear usuario admin por defecto
    await db.insert('users', {
      'email': 'admin@admin.com',
      'password': 'admin',
      'username': 'admin',
      'role': 1
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE products(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          price REAL NOT NULL,
          stock INTEGER NOT NULL,
          image TEXT NOT NULL,
          description TEXT
        )
      ''');

      await db.execute('''
        CREATE TABLE cart(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id INTEGER,
          product_id INTEGER,
          quantity INTEGER,
          FOREIGN KEY (user_id) REFERENCES users (id),
          FOREIGN KEY (product_id) REFERENCES products (id)
        )
      ''');
    }
  }
  Future<Map<String, dynamic>?> getUserById(int id) async {
    final Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<Map<String, dynamic>?> getAdminUser() async {
    final Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: ['admin', 'admin'],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<bool> registerUser(String email, String password, String username) async {
    try {
      final Database db = await database;
      await db.insert('users', {
        'email': email,
        'password': password,
        'username': username,
        'role': 2
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> loginUser(String userOrEmail, String password) async {
    final Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: '(email = ? OR username = ?) AND password = ?',
      whereArgs: [userOrEmail, userOrEmail, password],
    );

    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final Database db = await database;
    return await db.query('users', where: 'username != ?', whereArgs: ['admin']);
  }

  Future<bool> updateUser(int id, String email, String username, String password, int role) async {
    try {
      final Database db = await database;
      await db.update(
        'users',
        {
          'email': email,
          'username': username,
          'password': password,
          'role': role,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUser(int id) async {
    try {
      final Database db = await database;
      await db.delete('users', where: 'id = ?', whereArgs: [id]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addProduct(String name, double price, int stock, String image, String description) async {
    try {
      final Database db = await database;
      await db.insert('products', {
        'name': name,
        'price': price,
        'stock': stock,
        'image': image,
        'description': description,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final Database db = await database;
    return await db.query('products');
  }

  Future<bool> updateProduct(int id, String name, double price, int stock, String image, String description) async {
    try {
      final Database db = await database;
      await db.update(
        'products',
        {
          'name': name,
          'price': price,
          'stock': stock,
          'image': image,
          'description': description,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      final Database db = await database;
      await db.delete('products', where: 'id = ?', whereArgs: [id]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addToCart(int userId, int productId, int quantity) async {
    try {
      final Database db = await database;
      final existingItem = await db.query(
        'cart',
        where: 'user_id = ? AND product_id = ?',
        whereArgs: [userId, productId],
      );

      if (existingItem.isNotEmpty) {
        await db.update(
          'cart',
          {
            'quantity': (existingItem.first['quantity'] as int) + quantity
          },
          where: 'user_id = ? AND product_id = ?',
          whereArgs: [userId, productId],
        );
      } else {
        await db.insert('cart', {
          'user_id': userId,
          'product_id': productId,
          'quantity': quantity,
        });
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getCartItems(int userId) async {
    final Database db = await database;
    return await db.rawQuery('''
      SELECT cart.*, products.name, products.price, products.image
      FROM cart
      JOIN products ON cart.product_id = products.id
      WHERE cart.user_id = ?
    ''', [userId]);
  }

  Future<bool> updateCartItemQuantity(int userId, int productId, int quantity) async {
    try {
      final Database db = await database;
      if (quantity <= 0) {
        await db.delete(
          'cart',
          where: 'user_id = ? AND product_id = ?',
          whereArgs: [userId, productId],
        );
      } else {
        await db.update(
          'cart',
          {'quantity': quantity},
          where: 'user_id = ? AND product_id = ?',
          whereArgs: [userId, productId],
        );
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearCart(int userId) async {
    try {
      final Database db = await database;
      await db.delete('cart', where: 'user_id = ?', whereArgs: [userId]);
      return true;
    } catch (e) {
      return false;
    }
  }
}