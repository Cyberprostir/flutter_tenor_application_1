import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class DatabaseHelper {
  static Database? _database;

  static Future<Database> getDatabase() async {
    if (_database != null) {
      return _database!;
    }

    // Create a new database instance
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final String dbPath = await getDatabasesPath();
    final String pathString = path.join(dbPath, 'gif_database.db');

    return openDatabase(
      pathString,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE gifs(id TEXT PRIMARY KEY, gif_url TEXT, tinygif_url TEXT)',
        );
      },
    );
  }

  static Future<void> saveFavoriteGif(Map<String, dynamic> gif) async {
    final Database db = await getDatabase();

    await db.insert('gifs', gif, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<Map<String, dynamic>>> getFavoriteGifs() async {
    final Database db = await getDatabase();

    return db.query('gifs');
  }

  static Future<void> deleteFavoriteGif(String id) async {
    final Database db = await getDatabase();

    await db.delete('gifs', where: 'id = ?', whereArgs: [id]);
  }
}
