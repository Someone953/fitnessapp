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
      version: 6,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          await db.execute('''CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, username TEXT UNIQUE, password TEXT)''');
          try { await db.execute('ALTER TABLE profile ADD COLUMN user_id INTEGER'); } catch (_) {}
          try { await db.execute('ALTER TABLE workout ADD COLUMN user_id INTEGER'); } catch (_) {}
          try { await db.execute('ALTER TABLE nutrition ADD COLUMN user_id INTEGER'); } catch (_) {}
          try { await db.execute('ALTER TABLE progress_photo ADD COLUMN user_id INTEGER'); } catch (_) {}
        }
        if (oldVersion < 4) {
          await db.execute('''CREATE TABLE IF NOT EXISTS routine_days (id INTEGER PRIMARY KEY, user_id INTEGER, day_name TEXT, muscle_group TEXT)''');
          await db.execute('''CREATE TABLE IF NOT EXISTS routine_exercises (id INTEGER PRIMARY KEY, day_id INTEGER, name TEXT, description TEXT, image_path TEXT, muscle_work TEXT)''');
        }
        if (oldVersion < 5) {
          await db.execute('''CREATE TABLE IF NOT EXISTS planner_containers (id INTEGER PRIMARY KEY, user_id INTEGER, title TEXT, FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE)''');
          await db.execute('''CREATE TABLE IF NOT EXISTS planner_blocks (id INTEGER PRIMARY KEY, container_id INTEGER, title TEXT, FOREIGN KEY (container_id) REFERENCES planner_containers (id) ON DELETE CASCADE)''');
          await db.execute('''CREATE TABLE IF NOT EXISTS planner_exercises (id INTEGER PRIMARY KEY, block_id INTEGER, name TEXT, description TEXT, image_path TEXT, sets INTEGER, reps INTEGER, FOREIGN KEY (block_id) REFERENCES planner_blocks (id) ON DELETE CASCADE)''');
        }
        if (oldVersion < 6) {
          try { await db.execute('ALTER TABLE nutrition ADD COLUMN carbs INTEGER'); } catch (_) {}
          try { await db.execute('ALTER TABLE nutrition ADD COLUMN fats INTEGER'); } catch (_) {}
        }
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''CREATE TABLE users (id INTEGER PRIMARY KEY, username TEXT UNIQUE, password TEXT)''');
    await db.execute('''CREATE TABLE profile (id INTEGER PRIMARY KEY, user_id INTEGER, name TEXT, age INTEGER, gender TEXT, weight REAL, height REAL, bmi REAL, fitness_level TEXT, goal TEXT, weight_target REAL, step_goal INTEGER, workout_goal INTEGER, date TEXT, FOREIGN KEY (user_id) REFERENCES users (id))''');
    await db.execute('''CREATE TABLE workout (id INTEGER PRIMARY KEY, user_id INTEGER, title TEXT, sets INTEGER, reps INTEGER, date TEXT, FOREIGN KEY (user_id) REFERENCES users (id))''');
    await db.execute('''CREATE TABLE nutrition (id INTEGER PRIMARY KEY, user_id INTEGER, food TEXT, calories INTEGER, protein INTEGER, carbs INTEGER, fats INTEGER, date TEXT, FOREIGN KEY (user_id) REFERENCES users (id))''');
    await db.execute('''CREATE TABLE progress_photo (id INTEGER PRIMARY KEY, user_id INTEGER, date TEXT, image_path TEXT, note TEXT, FOREIGN KEY (user_id) REFERENCES users (id))''');
    
    await db.execute('''CREATE TABLE planner_containers (id INTEGER PRIMARY KEY, user_id INTEGER, title TEXT, FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE)''');
    await db.execute('''CREATE TABLE planner_blocks (id INTEGER PRIMARY KEY, container_id INTEGER, title TEXT, FOREIGN KEY (container_id) REFERENCES planner_containers (id) ON DELETE CASCADE)''');
    await db.execute('''CREATE TABLE planner_exercises (id INTEGER PRIMARY KEY, block_id INTEGER, name TEXT, description TEXT, image_path TEXT, sets INTEGER, reps INTEGER, FOREIGN KEY (block_id) REFERENCES planner_blocks (id) ON DELETE CASCADE)''');
  }

  static Database get db => _db!;

  static Future<int> register(String username, String password) async => await db.insert('users', {'username': username, 'password': password});
  static Future<Map<String, dynamic>?> login(String username, String password) async {
    final res = await db.query('users', where: 'username = ? AND password = ?', whereArgs: [username, password]);
    return res.isNotEmpty ? res.first : null;
  }

  static Future<int> insert(String table, Map<String, dynamic> data) => db.insert(table, data);
  static Future<List<Map<String, dynamic>>> query(String table, {String? where, List<dynamic>? whereArgs}) => 
    db.query(table, where: where, whereArgs: whereArgs, orderBy: 'id DESC');
  static Future<int> update(String table, Map<String, dynamic> data, int id) => db.update(table, data, where: 'id = ?', whereArgs: [id]);
  static Future<int> delete(String table, int id) => db.delete(table, where: 'id = ?', whereArgs: [id]);
}
