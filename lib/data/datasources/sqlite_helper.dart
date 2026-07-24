import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class SQLiteHelper {
  static final SQLiteHelper instance = SQLiteHelper._init();
  static Database? _database;

  SQLiteHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gemmea.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE diagnostics ADD COLUMN status TEXT NOT NULL DEFAULT 'new'");
      } catch (e) {
        // Safe check if column already exists
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Conversations Table
    await db.execute('''
      CREATE TABLE conversations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role TEXT NOT NULL,
        message TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    // 2. Diagnostics Table
    await db.execute('''
      CREATE TABLE diagnostics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        crop_name TEXT NOT NULL,
        disease TEXT NOT NULL,
        confidence REAL NOT NULL,
        remedy TEXT NOT NULL,
        image_path TEXT,
        timestamp TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'new'
      )
    ''');

    // 3. Calendar/Watering Schedule Table
    await db.execute('''
      CREATE TABLE calendar (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        event_date TEXT NOT NULL,
        description TEXT NOT NULL,
        is_rainy INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Seed initial values for water schedule on first creation
    await db.insert('calendar', {
      'title': 'Irrigation du Manioc',
      'event_date': DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0],
      'description': "Cycle d'irrigation léger régulier. Assurez-vous que le sol est humide mais pas saturé.",
      'is_rainy': 0,
    });

    await db.insert('calendar', {
      'title': 'Irrigation du Maïs',
      'event_date': DateTime.now().add(const Duration(days: 2)).toIso8601String().split('T')[0],
      'description': 'Irriguer le champ de maïs. Arroser profondément pour soutenir le développement des racines.',
      'is_rainy': 0,
    });
  }

  // --- Helpers for Conversations ---
  Future<List<Map<String, dynamic>>> getConversations() async {
    final db = await database;
    return await db.query('conversations', orderBy: 'timestamp ASC');
  }

  Future<int> insertMessage(Map<String, dynamic> msg) async {
    final db = await database;
    return await db.insert('conversations', msg);
  }

  Future<void> clearChat() async {
    final db = await database;
    await db.delete('conversations');
  }

  // --- Helpers for Diagnostics ---
  Future<List<Map<String, dynamic>>> getDiagnostics() async {
    final db = await database;
    return await db.query('diagnostics', orderBy: 'timestamp DESC');
  }

  Future<int> insertDiagnostic(Map<String, dynamic> diag) async {
    final db = await database;
    return await db.insert('diagnostics', diag);
  }

  Future<int> markAllDiagnosticsAsRead() async {
    final db = await database;
    return await db.update(
      'diagnostics',
      {'status': 'read'},
      where: 'status = ?',
      whereArgs: ['new'],
    );
  }

  Future<int> deleteDiagnostic(int id) async {
    final db = await database;
    return await db.delete(
      'diagnostics',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Helpers for Calendar ---
  Future<List<Map<String, dynamic>>> getCalendarEvents() async {
    final db = await database;
    return await db.query('calendar', orderBy: 'event_date ASC');
  }

  Future<int> insertCalendarEvent(Map<String, dynamic> event) async {
    final db = await database;
    return await db.insert('calendar', event);
  }

  Future<int> updateCalendarEvent(int id, Map<String, dynamic> event) async {
    final db = await database;
    return await db.update('calendar', event, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCalendarEventByDate(String date) async {
    final db = await database;
    return await db.delete('calendar', where: 'event_date = ?', whereArgs: [date]);
  }

  Future<int> updateRainStatus(String date, int isRainy) async {
    final db = await database;
    return await db.update(
      'calendar',
      {'is_rainy': isRainy},
      where: 'event_date = ?',
      whereArgs: [date],
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
