import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/booking.dart';

class BookingTable {
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertBooking(Booking booking) async {
    final db = await dbHelper.database;
    return await db.insert(
      'Bookings',
      booking.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Booking?> getBookingById(int id) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'Bookings',
      where: 'booking_id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) return Booking.fromMap(maps.first);
    return null;
  }

  Future<List<Booking>> getAllBookings() async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'Bookings', 
      orderBy: 'booking_date DESC'
    );
    return maps.map((m) => Booking.fromMap(m)).toList();
  }

  Future<List<Booking>> getBookingsByClient(int clientId) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'Bookings',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'booking_date DESC',
    );
    return maps.map((m) => Booking.fromMap(m)).toList();
  }

  Future<int> updateBooking(Booking booking) async {
    final db = await dbHelper.database;
    return await db.update(
      'Bookings',
      booking.toMap(),
      where: 'booking_id = ?',
      whereArgs: [booking.bookingId],
    );
  }

  Future<int> deleteBooking(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'Bookings',
      where: 'booking_id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getBookingCount() async {
    final db = await dbHelper.database;
    final x = await db.rawQuery('SELECT COUNT(*) FROM Bookings');
    return Sqflite.firstIntValue(x) ?? 0;
  }

  Future<List<Booking>> getBookingsByStatus(String status) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'Bookings',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'booking_date DESC',
    );
    return maps.map((m) => Booking.fromMap(m)).toList();
  }

  Future<List<Booking>> getBookingsPaged(int limit, int offset) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'Bookings',
      orderBy: 'booking_date DESC',
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Booking.fromMap(m)).toList();
  }
}
