import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;

class DatabaseHelper {
  static Future<void> createTables(sql.Database database) async {
    await database.execute(
        """CREATE TABLE items(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        latitude REAL,
        longitude REAL,
        sync BOOL DEFAULT 0,
        createdAt INTEGER,
        isBackground INTEGER
      )
      """);
  }

  // static Future<void> createTables(sql.Database database) async {
  //   await database.execute("""CREATE TABLE items(
  //       id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
  //       latitude TEXT,
  //       longitude TEXT,
  //       sync BOOL DEFAULT 0,
  //       createdAt INTEGER
  //     )
  //     """);
  // }
// id: the id of a item
// title, description: name and description of your activity
// created_at: the time that the item was created. It will be automatically handled by SQLite

  static Future<sql.Database> db() async {
    return sql.openDatabase(
      'tracker.db',
      version: 1,
      onCreate: (sql.Database database, int version) async {
        await createTables(database);
      },
    );
  }

  // Create new item
  static Future<int> createItem(String? latitude, String? longitude,
      int? createdAt, String? isBackground) async {
    final db = await DatabaseHelper.db();

    final data = {
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt,
      'isBackground': isBackground,
    };
    final id = await db.insert('items', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  // Read all items
  static Future<List<Map<String, dynamic>>> getItems() async {
    final db = await DatabaseHelper.db();
    // return db.query('items', orderBy: "id");
    return db.query('items', where: "sync = 0", orderBy: "id DESC");
  }

  static Future<List<Map<String, dynamic>>> getAllItems() async {
    final db = await DatabaseHelper.db();
    // return db.query('items', orderBy: "id");
    return db.query('items', orderBy: "id DESC");
  }

  // Get a single item by id
  //We dont use this method, it is for you if you want it.
  static Future<List<Map<String, dynamic>>> getItem(int id) async {
    final db = await DatabaseHelper.db();
    return db.query('items', where: "id = ?", whereArgs: [id], limit: 1);
  }

  // Update an item by id
  static Future<int> updateItem(int id, bool? sync) async {
    final db = await DatabaseHelper.db();

    final data = {
      'sync': sync,
    };

    final result =
        await db.update('items', data, where: "id = ?", whereArgs: [id]);
    return result;
  }

  // Delete
  static Future<void> deleteItem() async {
    final db = await DatabaseHelper.db();
    try {
      await db.delete("items");
    } catch (err) {
      debugPrint("Something went wrong when deleting an item: $err");
    }
  }
}
