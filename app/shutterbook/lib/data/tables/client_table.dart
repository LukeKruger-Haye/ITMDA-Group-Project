import 'package:sqflite/sqflite.dart';
import '../db/database_helper.dart';
import '../models/client.dart';

class ClientTable{
  final dbHelper = DatabaseHelper.instance;

  Future<int> insertClient(Client client) async {
    Database db = await dbHelper.database;
    return await db.insert(
      'Clients', 
      client.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace 
    );
  }

  Future<Client?> getClientById(int id) async {
    Database db = await dbHelper.database;
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
    Database db = await dbHelper.database;
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
    Database db = await dbHelper.database;
    final maps = await db.query('Clients');
    return maps.map((m) => Client.fromMap(m)).toList();
  }

  Future<List<Client>> getClientsPaged(int limit, int offset) async {
    final db = await dbHelper.database;
    final maps = await db.query(
      'Clients',
      // orderBy: '', // Can add ordering here if we'd like
      limit: limit,
      offset: offset,
    );
    return maps.map((m) => Client.fromMap(m)).toList();
  }

  Future<int> updateClient(Client client) async {
    final db = await dbHelper.database;
    return await db.update(
      'Clients',
      client.toMap(),
      where: 'client_id = ?',
      whereArgs: [client.id]
    );
  }

  Future<int> deleteClient(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'Clients',
      where: 'client_id = ?',
      whereArgs: [id]
    );
  }

  Future<int> getClientCount() async {
    final db = await dbHelper.database;
    final count = await db.rawQuery('SELECT COUNT(*) FROM Clients');
    return Sqflite.firstIntValue(count) ?? 0;
  }
}
