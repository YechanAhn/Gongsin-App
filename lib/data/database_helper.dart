import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/study_session.dart';
import '../models/subject.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    _database ??= await _initDB('gongsin.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE study_sessions (
        id TEXT PRIMARY KEY,
        subjectId TEXT NOT NULL,
        startTime INTEGER NOT NULL,
        endTime INTEGER NOT NULL,
        durationSeconds INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE subjects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        emoji TEXT NOT NULL,
        colorIndex INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE whitelisted_apps (
        packageName TEXT PRIMARY KEY,
        appName TEXT NOT NULL,
        addedAt INTEGER NOT NULL
      )
    ''');

    // Insert default subjects
    for (final subject in Subject.defaults) {
      await db.insert('subjects', subject.toMap());
    }
  }

  // ─── Study Sessions ───

  Future<void> insertSession(StudySession session) async {
    final db = await database;
    await db.insert('study_sessions', session.toMap());
  }

  Future<List<StudySession>> getSessionsForDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final maps = await db.query(
      'study_sessions',
      where: 'startTime >= ? AND startTime < ?',
      whereArgs: [
        startOfDay.millisecondsSinceEpoch,
        endOfDay.millisecondsSinceEpoch,
      ],
      orderBy: 'startTime DESC',
    );
    return maps.map((m) => StudySession.fromMap(m)).toList();
  }

  Future<List<StudySession>> getSessionsForMonth(int year, int month) async {
    final db = await database;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);
    final maps = await db.query(
      'study_sessions',
      where: 'startTime >= ? AND startTime < ?',
      whereArgs: [
        startOfMonth.millisecondsSinceEpoch,
        endOfMonth.millisecondsSinceEpoch,
      ],
      orderBy: 'startTime DESC',
    );
    return maps.map((m) => StudySession.fromMap(m)).toList();
  }

  Future<Map<DateTime, double>> getDailyHoursForMonth(int year, int month) async {
    final sessions = await getSessionsForMonth(year, month);
    final Map<DateTime, double> dailyHours = {};
    for (final session in sessions) {
      final date = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      dailyHours[date] = (dailyHours[date] ?? 0) + session.durationHours;
    }
    return dailyHours;
  }

  Future<double> getTotalHoursForDate(DateTime date) async {
    final sessions = await getSessionsForDate(date);
    return sessions.fold(0.0, (sum, s) => sum + s.durationHours);
  }

  // ─── Subjects ───

  Future<List<Subject>> getSubjects() async {
    final db = await database;
    final maps = await db.query('subjects', orderBy: 'colorIndex ASC');
    return maps.map((m) => Subject.fromMap(m)).toList();
  }

  Future<void> insertSubject(Subject subject) async {
    final db = await database;
    await db.insert('subjects', subject.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteSubject(String id) async {
    final db = await database;
    await db.delete('subjects', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Whitelisted Apps ───

  Future<void> addWhitelistedApp(String packageName, String appName) async {
    final db = await database;
    await db.insert('whitelisted_apps', {
      'packageName': packageName,
      'appName': appName,
      'addedAt': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeWhitelistedApp(String packageName) async {
    final db = await database;
    await db.delete('whitelisted_apps',
        where: 'packageName = ?', whereArgs: [packageName]);
  }

  Future<List<Map<String, dynamic>>> getWhitelistedApps() async {
    final db = await database;
    return await db.query('whitelisted_apps', orderBy: 'appName ASC');
  }

  Future<bool> isAppWhitelisted(String packageName) async {
    final db = await database;
    final result = await db.query('whitelisted_apps',
        where: 'packageName = ?', whereArgs: [packageName]);
    return result.isNotEmpty;
  }
}
