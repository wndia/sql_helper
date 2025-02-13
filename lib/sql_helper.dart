import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SQLHelper {
  static Future<Database> db() async {
    return openDatabase(
      join(await getDatabasesPath(), 'kindacode.db'),
      version: 2,
      onCreate: (Database database, int version) async {
        await database.execute("""
          CREATE TABLE items(
            id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
            title TEXT,
            description TEXT,
            note TEXT,
            image TEXT,
            createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
          )
        """);
      },
    );
  }

  static Future<List<Map<String, dynamic>>> getItems() async {
    final db = await SQLHelper.db();
    return db.query('items', orderBy: "id");
  }

  static Future<List<Map<String, dynamic>>> getItem(int id) async {
    final db = await SQLHelper.db();
    return db.query('items', where: "id = ?", whereArgs: [id], limit: 1);
  }

  static Future<int> createItem(
      String title, String? description, String? note, String? image) async {
    final db = await SQLHelper.db();
    final data = {
      'title': title,
      'description': description,
      'note': note,
      'image': image
    };
    return db.insert('items', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> updateItem(int id, String title, String? description,
      String? note, String? image) async {
    final db = await SQLHelper.db();
    final data = {
      'title': title,
      'description': description,
      'note': note,
      'image': image,
      'createdAt': DateTime.now().toString()
    };
    return db.update('items', data, where: "id = ?", whereArgs: [id]);
  }

  static Future<void> deleteItem(int id) async {
    final db = await SQLHelper.db();
    await db.delete('items', where: "id = ?", whereArgs: [id]);
  }
}
