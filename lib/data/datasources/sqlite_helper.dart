import 'dart:developer' as dev;
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
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      return await openDatabase(
        path,
        version: 3,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );
    } catch (e, stack) {
      dev.log("Error initializing SQLite DB", name: 'SQLITE_HELPER', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute("ALTER TABLE diagnostics ADD COLUMN status TEXT NOT NULL DEFAULT 'new'");
      } catch (e, stack) {
        dev.log("Migration v2 note: $e", name: 'SQLITE_HELPER', error: e, stackTrace: stack);
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute("ALTER TABLE diagnostics ADD COLUMN estimated_loss_usd REAL DEFAULT 0.0");
      } catch (e, stack) {
        dev.log("Migration v3 note: $e", name: 'SQLITE_HELPER', error: e, stackTrace: stack);
      }
      await _createFAOTables(db);
    }
  }

  Future<void> _createDB(Database db, int version) async {
    try {
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
          status TEXT NOT NULL DEFAULT 'new',
          estimated_loss_usd REAL DEFAULT 0.0
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

      await _createFAOTables(db);

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
      dev.log("Database created and seeded successfully", name: 'SQLITE_HELPER');
    } catch (e, stack) {
      dev.log("Error creating database tables", name: 'SQLITE_HELPER', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> _createFAOTables(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS fao_knowledge_base (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          topic TEXT NOT NULL,
          crop_name TEXT NOT NULL,
          keywords TEXT NOT NULL,
          content TEXT NOT NULL,
          organic_remedy TEXT NOT NULL,
          estimated_loss_pct REAL NOT NULL,
          source_citation TEXT NOT NULL
        )
      ''');

      // Seed FAO Official Agronomic Guidelines
      await db.insert('fao_knowledge_base', {
        'topic': 'Cassava Mosaic Disease (CMD)',
        'crop_name': 'Manioc',
        'keywords': 'manioc cassava mosaiqueCMD feuille jaunissement taches decoloration',
        'content': 'La mosaïque du manioc est causée par un geminivirus transmis par la mouche blanche (Bemisia tabaci). Symptômes: déformation des feuilles, décoloration mosaïque jaune-vert, réduction du rendement des tubercules de 40% à 70%.',
        'organic_remedy': '1. Éliminer et brûler immédiatement les plants infectés. 2. Utiliser des boutures de variétés résistantes certifiées FAO (ex. TME 419). 3. Pulvériser de la cendre de bois ou un extrait d eau de neem pour repousser les mouches blanches.',
        'estimated_loss_pct': 55.0,
        'source_citation': 'Guide FAO de Protection des Cultures en Afrique de l Est (2024), Chap. 4, p. 28-32',
      });

      await db.insert('fao_knowledge_base', {
        'topic': 'Common Maize Rust (Puccinia sorghi)',
        'crop_name': 'Maïs',
        'keywords': 'mais maize rouille tavelure poudree pustules rouille brune',
        'content': 'La rouille du maïs se manifeste par de petites pustules brun-orange sur les deux faces de la feuille. Favorisée par l humidité élevée et des températures de 16°C à 23°C. Risque de perte de rendement de 20% à 45%.',
        'organic_remedy': '1. Effectuer une rotation des cultures avec des légumineuses (haricots). 2. Appliquer un extrait d ail/piment en spray foliaire biologique. 3. Éviter la sur-irrigation foliaire le soir.',
        'estimated_loss_pct': 35.0,
        'source_citation': 'Manuel Santé des Recoltes FAO/IITA (2023), Section 2.1',
      });

      await db.insert('fao_knowledge_base', {
        'topic': 'Banana Bacterial Wilt (BXW)',
        'crop_name': 'Banane',
        'keywords': 'banane banana fletrissement bacterienBXW jaunissement foliaire fanaison',
        'content': 'BXW causé par Xanthomonas vasicola. Symptômes: jaunissement rapide et flétrissement des feuilles, suintement bactérien jaune à la coupe du pseudo-tronc, pourriture précoce du régime.',
        'organic_remedy': '1. Stériliser immédiatement les outils de coupe à la flamme ou avec une solution de javel à 10%. 2. Enlever le bourgeon mâle dès que la dernière main est formée. 3. Déraciner les souches atteintes.',
        'estimated_loss_pct': 80.0,
        'source_citation': 'Bulletin d Urgence Sanitaire Bananiere FAO (2024), p. 12',
      });
      dev.log("FAO knowledge base table seeded successfully", name: 'SQLITE_HELPER');
    } catch (e, stack) {
      dev.log("Error creating FAO tables", name: 'SQLITE_HELPER', error: e, stackTrace: stack);
    }
  }

  // --- Helpers for Conversations ---
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final db = await database;
      return await db.query('conversations', orderBy: 'timestamp ASC');
    } catch (e, stack) {
      dev.log("Error fetching conversations", name: 'SQLITE_HELPER', error: e, stackTrace: stack);
      return [];
    }
  }

  Future<int> insertMessage(Map<String, dynamic> msg) async {
    try {
      final db = await database;
      return await db.insert('conversations', msg);
    } catch (e, stack) {
      dev.log("Error inserting conversation message", name: 'SQLITE_HELPER', error: e, stackTrace: stack);
      return -1;
    }
  }

  Future<void> clearChat() async {
    try {
      final db = await database;
      await db.delete('conversations');
    } catch (e, stack) {
      dev.log("Error clearing conversations", name: 'SQLITE_HELPER', error: e, stackTrace: stack);
    }
  }

  // --- Helpers for Diagnostics ---
  Future<List<Map<String, dynamic>>> getDiagnostics() async {
    try {
      final db = await database;
      return await db.query('diagnostics', orderBy: 'timestamp DESC');
    } catch (e, stack) {
      dev.log("Error fetching diagnostics", name: 'SQLITE_HELPER', error: e, stackTrace: stack);
      return [];
    }
  }

  Future<int> insertDiagnostic(Map<String, dynamic> diag) async {
    try {
      final db = await database;
      return await db.insert('diagnostics', diag);
    } catch (e, stack) {
      dev.log("Error inserting diagnostic", name: 'SQLITE_HELPER', error: e, stackTrace: stack);
      return -1;
    }
  }

  Future<int> markAllDiagnosticsAsRead() async {
    try {
      final db = await database;
      return await db.update(
        'diagnostics',
        {'status': 'read'},
        where: 'status = ?',
        whereArgs: ['new'],
      );
    } catch (e, stack) {
      dev.log("Error marking diagnostics as read", name: 'SQLITE_HELPER', error: e, stackTrace: stack);
      return 0;
    }
  }

  Future<int> deleteDiagnostic(int id) async {
    try {
      final db = await database;
      return await db.delete(
        'diagnostics',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e, stack) {
      dev.log("Error deleting diagnostic ID: $id", name: 'SQLITE_HELPER', error: e, stackTrace: stack);
      return 0;
    }
  }

  // --- Helpers for Calendar ---
  Future<List<Map<String, dynamic>>> getCalendarEvents() async {
    try {
      final db = await database;
      return await db.query('calendar', orderBy: 'event_date ASC');
    } catch (e, stack) {
      dev.log("Error fetching calendar events", name: 'SQLITE_HELPER', error: e, stackTrace: stack);
      return [];
    }
  }

  Future<int> insertCalendarEvent(Map<String, dynamic> event) async {
    try {
      final db = await database;
      return await db.insert('calendar', event);
    } catch (e, stack) {
      dev.log("Error inserting calendar event", name: 'SQLITE_HELPER', error: e, stackTrace: stack);
      return -1;
    }
  }

  Future<int> updateCalendarEvent(int id, Map<String, dynamic> event) async {
    try {
      final db = await database;
      return await db.update('calendar', event, where: 'id = ?', whereArgs: [id]);
    } catch (e, stack) {
      dev.log("Error updating calendar event ID: $id", name: 'SQLITE_HELPER', error: e, stackTrace: stack);
      return 0;
    }
  }

  Future<int> deleteCalendarEventByDate(String date) async {
    try {
      final db = await database;
      return await db.delete('calendar', where: 'event_date = ?', whereArgs: [date]);
    } catch (e, stack) {
      dev.log("Error deleting calendar event date: $date", name: 'SQLITE_HELPER', error: e, stackTrace: stack);
      return 0;
    }
  }

  Future<int> updateRainStatus(String date, int isRainy) async {
    try {
      final db = await database;
      return await db.update(
        'calendar',
        {'is_rainy': isRainy},
        where: 'event_date = ?',
        whereArgs: [date],
      );
    } catch (e, stack) {
      dev.log("Error updating rain status for date: $date", name: 'SQLITE_HELPER', error: e, stackTrace: stack);
      return 0;
    }
  }

  // --- Helpers for FAO Knowledge Base (RAG) ---
  Future<List<Map<String, dynamic>>> searchFAOKnowledge(String query) async {
    try {
      final db = await database;
      final cleanQuery = query.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
      final terms = cleanQuery.split(' ').where((t) => t.length > 2).toList();

      if (terms.isEmpty) {
        return await db.query('fao_knowledge_base', limit: 3);
      }

      final whereClause = terms.map((_) => "(keywords LIKE ? OR content LIKE ? OR topic LIKE ?)").join(' OR ');
      final whereArgs = <String>[];
      for (final term in terms) {
        whereArgs.addAll(['%$term%', '%$term%', '%$term%']);
      }

      final results = await db.query(
        'fao_knowledge_base',
        where: whereClause,
        whereArgs: whereArgs,
        limit: 3,
      );

      if (results.isEmpty) {
        return await db.query('fao_knowledge_base', limit: 3);
      }

      return results;
    } catch (e, stack) {
      dev.log("Error searching FAO knowledge base", name: 'SQLITE_HELPER', error: e, stackTrace: stack);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFAOByCrop(String cropName) async {
    try {
      final db = await database;
      return await db.query(
        'fao_knowledge_base',
        where: 'crop_name LIKE ? OR keywords LIKE ?',
        whereArgs: ['%$cropName%', '%$cropName%'],
      );
    } catch (e, stack) {
      dev.log("Error fetching FAO knowledge by crop: $cropName", name: 'SQLITE_HELPER', error: e, stackTrace: stack);
      return [];
    }
  }

  Future<void> close() async {
    try {
      final db = _database;
      if (db != null) {
        await db.close();
      }
    } catch (e, stack) {
      dev.log("Error closing database", name: 'SQLITE_HELPER', error: e, stackTrace: stack);
    }
  }
}
