// Shutterbook — booking_table.dart
// Database access helpers for bookings. CRUD and query helpers used by
// the bookings UI. Keep business logic out of this file; it should only
// translate between Booking models and the SQL layer.
import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/booking.dart';
import '../models/booking_with_client.dart';

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
    final maps = await db.query('Bookings', orderBy: 'booking_date DESC');
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

  //Joining the client table to get client name for the bookings
  Future<List<BookingWithClient>> getBookingsForItemWithClientNames(int itemId) async {
    final db = await dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT 
        B.booking_id,
        B.client_id,
        B.quote_id,
        B.booking_date,
        B.status,
        B.created_at,
        (C.first_name || ' ' || C.last_name) AS client_name
      FROM Bookings B
      INNER JOIN BookingInventory BI ON BI.booking_id = B.booking_id
      LEFT JOIN Clients C ON B.client_id = C.client_id
      WHERE BI.item_id = ?
      ORDER BY B.booking_date DESC
    ''', [itemId]);

    return rows.map((r) => BookingWithClient.fromMap(r)).toList();
  }

  /// Finds bookings that would conflict with the given [when].
  ///
  /// Because the app schedules at hour granularity in the calendar,
  /// we consider any booking within the same hour a potential conflict.
  /// If [excludeBookingId] is provided, that row will be ignored (useful
  /// when editing an existing booking).
  Future<List<Booking>> findHourConflicts(DateTime when, {int? excludeBookingId}) async {
    final db = await dbHelper.database;
    // Define the hour range: [hourStart, hourStart + 1h)
    final hourStart = DateTime(when.year, when.month, when.day, when.hour);
    final hourEnd = hourStart.add(const Duration(hours: 1));
    final where = excludeBookingId == null
        ? 'booking_date >= ? AND booking_date < ?'
        : 'booking_date >= ? AND booking_date < ? AND booking_id <> ?';
    final whereArgs = excludeBookingId == null
        ? [hourStart.toString(), hourEnd.toString()]
        : [hourStart.toString(), hourEnd.toString(), excludeBookingId];

    final maps = await db.query(
      'Bookings',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'booking_date ASC',
    );
    return maps.map((m) => Booking.fromMap(m)).toList();
  }

  
}