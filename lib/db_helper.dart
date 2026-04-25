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
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''CREATE TABLE users (
          id INTEGER PRIMARY KEY, 
          username TEXT, 
          email TEXT UNIQUE,
          password TEXT
        )''');
        await db.execute('''CREATE TABLE profile (
          id INTEGER PRIMARY KEY, 
          user_id INTEGER,
          name TEXT, 
          age INTEGER,
          gender TEXT,
          weight REAL, 
          height REAL, 
          bmi REAL, 
          fitness_level TEXT,
          goal TEXT, 
          weight_target REAL,
          step_goal INTEGER,
          workout_goal INTEGER,
          date TEXT,
          FOREIGN KEY (user_id) REFERENCES users (id)
        )''');
        await db.execute('''CREATE TABLE workout (id INTEGER PRIMARY KEY, user_id INTEGER, title TEXT, sets INTEGER, reps INTEGER, date TEXT, FOREIGN KEY (user_id) REFERENCES users (id))''');
        await db.execute('''CREATE TABLE nutrition (id INTEGER PRIMARY KEY, user_id INTEGER, food TEXT, calories INTEGER, protein INTEGER, date TEXT, FOREIGN KEY (user_id) REFERENCES users (id))''');
        await db.execute('''CREATE TABLE progress_photo (id INTEGER PRIMARY KEY, user_id INTEGER, date TEXT, image_path TEXT, note TEXT, FOREIGN KEY (user_id) REFERENCES users (id))''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('''CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY, 
            username TEXT UNIQUE, 
            password TEXT
          )''');
          // Add user_id columns if they don't exist
          try { await db.execute('ALTER TABLE profile ADD COLUMN user_id INTEGER'); } catch (_) {}
          try { await db.execute('ALTER TABLE workout ADD COLUMN user_id INTEGER'); } catch (_) {}
          try { await db.execute('ALTER TABLE nutrition ADD COLUMN user_id INTEGER'); } catch (_) {}
          try { await db.execute('ALTER TABLE progress_photo ADD COLUMN user_id INTEGER'); } catch (_) {}
        }
      },
    );
  }

  static Database get db => _db!;

  // User Auth Methods
  static Future<int> register(String email, String password, String username) async {
    return await db.insert('users', {
      'email': email,
      'password': password,
      'username': username,
    });
  }

  static Future<Map<String, dynamic>?> login(String email, String password) async {
    final res = await db.query('users', where: 'email = ? AND password = ?', whereArgs: [email, password]);
    return res.isNotEmpty ? res.first : null;
  }

  static Future<void> insertSampleData() async {
    // Optional: add sample user and profile if needed
  }

  static Future<int> insert(String table, Map<String, dynamic> data) => db.insert(table, data);
  static Future<List<Map<String, dynamic>>> query(String table, {int? userId, String? where, List<dynamic>? whereArgs}) {
    String? finalWhere = where;
    List<dynamic>? finalArgs = whereArgs;

    if (userId != null) {
      if (finalWhere == null) {
        finalWhere = 'user_id = ?';
        finalArgs = [userId];
      } else {
        finalWhere = '$finalWhere AND user_id = ?';
        finalArgs = [...(finalArgs ?? []), userId];
      }
    }
    return db.query(table, where: finalWhere, whereArgs: finalArgs, orderBy: 'id DESC');
  }
  static Future<int> update(String table, Map<String, dynamic> data, int id) => db.update(table, data, where: 'id = ?', whereArgs: [id]);
  static Future<int> delete(String table, int id) => db.delete(table, where: 'id = ?', whereArgs: [id]);
}
