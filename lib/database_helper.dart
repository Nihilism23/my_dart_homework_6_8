import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'course.dart';
import 'simple_storage.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  final SimpleStorage _simpleStorage = SimpleStorage.instance;

  DatabaseHelper._init() {
    if (!kIsWeb) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<dynamic> get database async {
    if (kIsWeb) {
      return _simpleStorage;
    }
    if (_database != null) return _database!;
    _database = await _initDB('courses.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE courses ADD COLUMN weekType INTEGER NOT NULL DEFAULT 0');
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        classroom TEXT NOT NULL,
        dayOfWeek INTEGER NOT NULL,
        period INTEGER NOT NULL,
        colorIndex INTEGER NOT NULL DEFAULT 0,
        weekType INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<int> insertCourse(Course course) async {
    if (kIsWeb) {
      return await _simpleStorage.insertCourse(course);
    }
    final db = await instance.database;
    return await db.insert('courses', course.toMap());
  }

  Future<List<Course>> getAllCourses() async {
    if (kIsWeb) {
      return await _simpleStorage.getAllCourses();
    }
    final db = await instance.database;
    final result = await db.query('courses');
    return result.map((map) => Course.fromMap(map)).toList();
  }

  Future<int> deleteCourse(int id) async {
    if (kIsWeb) {
      return await _simpleStorage.deleteCourse(id);
    }
    final db = await instance.database;
    return await db.delete('courses', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateCourse(Course course) async {
    if (kIsWeb) {
      return await _simpleStorage.updateCourse(course);
    }
    final db = await instance.database;
    return await db.update(
      'courses',
      course.toMap(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  Future close() async {
    if (kIsWeb) return;
    final db = await instance.database;
    await db.close();
  }
}
