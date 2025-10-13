import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final _databaseName = 'shutterbook.db';
  static final _databaseVersion = 1;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Clients (
        client_id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL
      )
      '''
    );

    await db.execute('''
      CREATE TABLE Quotes (
        quote_id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id INTEGER NOT NULL, 
        total_price REAL NOT NULL,
        description TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (client_id) REFERENCES Clients(client_id) ON DELETE CASCADE
      )
      '''
    );

    await db.execute('''
      CREATE TABLE Bookings (
        booking_id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote_id INTEGER NOT NULL,
        client_id INTEGER NOT NULL, 
        booking_date DATE NOT NULL,
        status TEXT DEFAULT 'Scheduled',
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (client_id) REFERENCES Clients(client_id) ON DELETE CASCADE
        FOREIGN KEY (quote_id) REFERENCES Quotes(quote_id) ON DELETE CASCADE
      )
      '''
    );
  }
} 
