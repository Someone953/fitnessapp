import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DbHelper {
  static Database? _db;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'fitwell.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE profile (id INTEGER PRIMARY KEY, name TEXT, weight REAL, height REAL, bmi REAL, goal TEXT, date TEXT)''');
        await db.execute('''CREATE TABLE workout (id INTEGER PRIMARY KEY, title TEXT, sets INTEGER, reps INTEGER, date TEXT)''');
        await db.execute('''CREATE TABLE nutrition (id INTEGER PRIMARY KEY, food TEXT, calories INTEGER, protein INTEGER, date TEXT)''');
        await db.execute('''CREATE TABLE progress_photo (id INTEGER PRIMARY KEY, date TEXT, image_path TEXT, note TEXT)''');
      },
    );
  }

  static Database get db => _db!;

  static Future<void> insertSampleData() async {
    final count = await db.rawQuery('SELECT COUNT(*) as c FROM profile');
    if ((count.first['c'] as int) == 0) {
      await db.insert('profile', {'name': 'Alex', 'weight': 68.0, 'height': 1.7, 'bmi': 23.5, 'goal': 'Build Muscle', 'date': '2026-04-04'});
      await db.insert('workout', {'title': 'Push Day', 'sets': 4, 'reps': 10, 'date': '2026-04-04'});
      await db.insert('nutrition', {'food': 'Chicken Rice', 'calories': 650, 'protein': 45, 'date': '2026-04-04'});
    }
  }

  static Future<int> insert(String table, Map<String, dynamic> data) => db.insert(table, data);
  static Future<List<Map<String, dynamic>>> query(String table) => db.query(table);
  static Future<int> update(String table, Map<String, dynamic> data, int id) => db.update(table, data, where: 'id = ?', whereArgs: [id]);
  static Future<int> delete(String table, int id) => db.delete(table, where: 'id = ?', whereArgs: [id]);
}