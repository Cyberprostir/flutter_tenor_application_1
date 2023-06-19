import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:collection/collection.dart';
import 'package:async/async.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database?> get database async {
    if (_database != null) {
      return _database;
    }

    _database = await initializeDatabase();
    return _database;
  }

  Future<Database> initializeDatabase() async {
    final String databasesPath = await getDatabasesPath();
    final String path = join(databasesPath, 'favorites.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE favorites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            imageUrl TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertFavorite(String imageUrl) async {
    final Database? db = await database;
    await db?.insert(
      'favorites',
      {'imageUrl': imageUrl},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<String>> getFavorites() async {
    final Database? db = await database;
    final List<Map<String, dynamic>> maps = await db!.query('favorites');
    return List.generate(
        maps.length, (index) => maps[index]['imageUrl'] as String);
  }

  Future<void> deleteFavorite(String imageUrl) async {
    final Database? db = await database;
    await db?.delete('favorites', where: 'imageUrl = ?', whereArgs: [imageUrl]);
  }
}
