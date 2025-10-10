import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models/booking.dart';
import 'models/client.dart';
import 'models/quote.dart';

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
      ''');

    await db.execute('''
      CREATE TABLE Quotes (
      quote_id INTEGER PRIMARY KEY AUTOINCREMENT,
      client_id INTEGER NOT NULL, 
      total_price REAL NOT NULL,
      description TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (client_id) REFERENCES Clients(client_id) ON DELETE CASCADE
      )
      ''');

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
      ''');
  }

  Future<int> insertClient(Client client) async {
    Database db = await instance.database;
    return await db.insert(
      'Clients', 
      client.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace 
    );
  }

  Future<Client?> getClientById(int id) async {
    Database db = await instance.database;
    final maps = await db.query(
      'Clients', 
      where: 'client_id = ?',
      whereArgs: [id]
    );

    if (maps.isNotEmpty) {
            return Client.fromMap(maps.first);
        }

    return null;
  }

  Future<Client?> getClientByEmail(String email) async {
    Database db = await instance.database;
    final maps = await db.query(
      'Clients', 
      where: 'email = ?',
      whereArgs: [email]
    );

    if (maps.isNotEmpty) {
            return Client.fromMap(maps.first);
        }

    return null;
  }

  Future<List<Client>> getAllClients() async {
    Database db = await instance.database;
    final maps = await db.query('clients');
    return maps.map((m) => Client.fromMap(m)).toList();
  }

  Future<List<Client>> getClientsPaged(int limit, int offset) async {
    final db = await instance.database;
    final maps = await db.query(
      'Clients',
      // orderBy: '', // Can add ordering here if we'd like
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Client.fromMap(m)).toList();
  }

  Future<int> updateClient(Client client) async {
    final db = await instance.database;
    return await db.update(
      'Clients',
      client.toMap(),
      where: 'client_id = ?',
      whereArgs: [client.id]
    );
  }

  Future<int> deleteClient(int id) async {
    final db = await instance.database;
    return await db.delete(
      'Clients',
      where: 'client_id = ?',
      whereArgs: [id]
    );
  }

  Future<int> getClientCount() async {
    final db = await instance.database;
    final count = await db.rawQuery('SELECT COUNT(*) FROM Clients');
    return Sqflite.firstIntValue(count) ?? 0;
  }

  // Qoutes

  Future<int> insertQuote(Quote quote) async {
    Database db = await instance.database;
    return await db.insert(
      'Quotes', 
      quote.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace 
    );
  }

  Future<Quote?> getQuoteById(int id) async {
    Database db = await instance.database;
    final maps = await db.query(
      'Quotes', 
      where: 'quote_id = ?',
      whereArgs: [id]
    );

    if (maps.isNotEmpty) {
            return Quote.fromMap(maps.first);
        }

    return null;
  }

  Future<List<Quote>> getAllQuotes() async {
    Database db = await instance.database;
    final maps = await db.query(
      'Quotes',
      orderBy: 'created_at DESC'
    );
    return maps.map((m) => Quote.fromMap(m)).toList();
  }

  Future<List<Quote>> getQuotesPaged(int limit, int offset) async {
    final db = await instance.database;
    final maps = await db.query(
      'Quotes',
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Quote.fromMap(m)).toList();
  }

  Future<int> updateQuote(Quote quote) async {
    final db = await instance.database;
    return await db.update(
      'Quotes',
      quote.toMap(),
      where: 'quote_id = ?',
      whereArgs: [quote.id]
    );
  }

  Future<int> deleteQuotes(int id) async {
    final db = await instance.database;
    return await db.delete(
      'Quotes',
      where: 'quote_id = ?',
      whereArgs: [id]
    );
  }

  Future<int> getQuoteCount() async {
    final db = await instance.database;
    final count = await db.rawQuery('SELECT COUNT(*) FROM Quotes');
    return Sqflite.firstIntValue(count) ?? 0;
  }

  // Bookings

  Future<int> insertBooking(Booking booking) async {
    final db = await instance.database;
    return await db.insert(
      'Bookings',
      booking.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Booking?> getBookingById(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'Bookings',
      where: 'booking_id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
            return Booking.fromMap(maps.first);
        }

    return null;
  }

  Future<List<Booking>> getAllBookings() async {
    final db = await instance.database;
    final maps = await db.query(
      'Bookings', 
      orderBy: 'booking_date DESC'
    );
    return maps.map((m) => Booking.fromMap(m)).toList();
  }

  Future<List<Booking>> getBookingsByClient(int clientId) async {
    final db = await instance.database;
    final maps = await db.query(
      'Bookings',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'booking_date DESC',
    );
    return maps.map((m) => Booking.fromMap(m)).toList();
  }

  Future<int> updateBooking(Booking booking) async {
    final db = await instance.database;
    return await db.update(
      'Bookings',
      booking.toMap(),
      where: 'booking_id = ?',
      whereArgs: [booking.bookingId],
    );
  }

  Future<int> deleteBooking(int id) async {
    final db = await instance.database;
    return await db.delete(
      'Bookings',
      where: 'booking_id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getBookingCount() async {
    final db = await instance.database;
    final x = await db.rawQuery('SELECT COUNT(*) FROM Bookings');
    return Sqflite.firstIntValue(x) ?? 0;
  }

  Future<List<Booking>> getBookingsByStatus(String status) async {
    final db = await instance.database;
    final maps = await db.query(
      'Bookings',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'booking_date DESC',
    );
    return maps.map((m) => Booking.fromMap(m)).toList();
  }

  Future<List<Booking>> getBookingsPaged(int limit, int offset) async {
    final db = await instance.database;
    final maps = await db.query(
      'Bookings',
      orderBy: 'booking_date DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Booking.fromMap(m)).toList();
  }
} 
