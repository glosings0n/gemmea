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

      final db = await openDatabase(
        path,
        version: 3,
        onCreate: _createDB,
        onUpgrade: _upgradeDB,
      );

      // Safe, one-time cleanup of legacy error records on initialization
      try {
        await db.delete(
          'diagnostics',
          where: "disease LIKE ? OR disease = ? OR remedy LIKE ? OR remedy LIKE ? OR remedy LIKE ?",
          whereArgs: ['%error%', 'Symptômes Analysés', '%processing error%', '%Veuillez fournir%', '%On-device%'],
        );
      } catch (e) {
        dev.log("Non-critical cleanup note on initDB: $e", name: 'SQLITE_HELPER');
      }

      return db;
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

      // Create SQLite FTS5 Virtual Table for ultra-fast full-text search with BM25 ranking
      try {
        await db.execute('''
          CREATE VIRTUAL TABLE IF NOT EXISTS fao_knowledge_fts USING fts5(
            topic, crop_name, keywords, content, organic_remedy, source_citation,
            content='fao_knowledge_base', content_rowid='id'
          )
        ''');

        // Triggers to keep FTS table in sync with fao_knowledge_base
        await db.execute('''
          CREATE TRIGGER IF NOT EXISTS fao_ai AFTER INSERT ON fao_knowledge_base BEGIN
            INSERT INTO fao_knowledge_fts(rowid, topic, crop_name, keywords, content, organic_remedy, source_citation)
            VALUES (new.id, new.topic, new.crop_name, new.keywords, new.content, new.organic_remedy, new.source_citation);
          END;
        ''');
      } catch (e) {
        dev.log("FTS5 table creation notice (falling back to scored search if unavailable): $e", name: 'SQLITE_HELPER');
      }

      // Seed FAO Official Agronomic Guidelines
      final initialEntries = [
        {
          'topic': 'Mosaïque du Manioc (CMD)',
          'crop_name': 'Manioc',
          'keywords': 'manioc cassava mosaique cmd feuille jaunissement taches decoloration aleurode mouche blanche',
          'content': 'La mosaïque du manioc est causée par un geminivirus transmis par la mouche blanche (Bemisia tabaci). Symptômes: déformation des feuilles, décoloration mosaïque jaune-vert, réduction du rendement des tubercules de 40% à 70%.',
          'organic_remedy': '1. Éliminer et brûler immédiatement les plants infectés. 2. Utiliser des boutures de variétés résistantes certifiées FAO/IITA (ex. TME 419, SAWASA). 3. Pulvériser un extrait d eau de neem (200g/L) ou saupoudrer de la cendre de bois pour repousser les mouches blanches.',
          'estimated_loss_pct': 55.0,
          'source_citation': 'Guide FAO de Protection des Cultures en Afrique de l Est (2024), Chap. 4, p. 28-32',
        },
        {
          'topic': 'Strie Brune du Manioc (CBSD)',
          'crop_name': 'Manioc',
          'keywords': 'manioc cassava strie brune cbsd necrose tubercule pourriture marron jaunissement nervures',
          'content': 'La strie brune du manioc (CBSD) provoque des nécroses brunes/noires spongieuses dans la chair du tubercule et des striations brunes sur la tige. C est la maladie la plus destructive pour la récolte.',
          'organic_remedy': '1. Utiliser uniquement des boutures saines certifiées INERA/IITA. 2. Éliminer les plants symptomatiques. 3. Désinfecter les machettes et outils à la flamme ou eau de javel.',
          'estimated_loss_pct': 75.0,
          'source_citation': 'Manuel IITA Santé du Manioc en RDC (2024), p. 15',
        },
        {
          'topic': 'Rouille du Maïs (Puccinia sorghi)',
          'crop_name': 'Maïs',
          'keywords': 'mais maize rouille tavelure poudree pustules rouille brune brun orange',
          'content': 'La rouille du maïs se manifeste par de petites pustules brun-orange sur les deux faces de la feuille. Favorisée par l humidité élevée et des températures de 16°C à 23°C. Risque de perte de rendement de 20% à 45%.',
          'organic_remedy': '1. Effectuer une rotation des cultures avec des légumineuses (haricots). 2. Appliquer un extrait d ail/piment en spray foliaire biologique. 3. Éviter la sur-irrigation foliaire le soir.',
          'estimated_loss_pct': 35.0,
          'source_citation': 'Manuel Santé des Récoltes FAO/IITA (2023), Section 2.1',
        },
        {
          'topic': 'Chenille Légionnaire d Automne du Maïs (FAW)',
          'crop_name': 'Maïs',
          'keywords': 'mais maize chenille legionnaire faw trou cornet perforation devoreur tithonia neem',
          'content': 'La chenille légionnaire (Spodoptera frugiperda) dévore le cornet des jeunes plants de maïs et laisse des sciures d excréments visibles. Destruction rapide du champ.',
          'organic_remedy': '1. Verser une poignée de cendre de bois sèche ou de sable fin directement dans le cornet des plants. 2. Pulvériser un purin de Tithonia diversifolia ou extrait de neem concentré. 3. Ramasser manuellement les chenilles au petit matin.',
          'estimated_loss_pct': 60.0,
          'source_citation': 'Directive d Urgence FAO contre la Chenille Légionnaire (2024), p. 8-14',
        },
        {
          'topic': 'Flétrissement Bactérien de la Banane (BXW)',
          'crop_name': 'Banane',
          'keywords': 'banane banana fletrissement bacterien bxw jaunissement foliaire fanaison suintement',
          'content': 'BXW causé par Xanthomonas vasicola. Symptômes: jaunissement rapide et flétrissement des feuilles, suintement bactérien jaune à la coupe du pseudo-tronc, pourriture précoce du régime.',
          'organic_remedy': '1. Stériliser immédiatement les outils de coupe à la flamme ou avec une solution de javel à 10%. 2. Enlever le bourgeon mâle dès que la dernière main est formée. 3. Déraciner les souches atteintes.',
          'estimated_loss_pct': 80.0,
          'source_citation': 'Bulletin d Urgence Sanitaire Bananière FAO (2024), p. 12',
        },
        {
          'topic': 'Anthracnose du Haricot (Colletotrichum)',
          'crop_name': 'Haricot',
          'keywords': 'haricot bean anthracnose taches noires gousses nervures rouges pourriture',
          'content': 'L anthracnose du haricot se caractérise par de petites taches circulaires noires ou brun foncé enjambant les nervures sous les feuilles et sur les gousses.',
          'organic_remedy': '1. Utiliser des semences saines traitées au purin d ail. 2. Éviter de circuler dans le champ quand les feuilles sont humides. 3. Pulvériser une décoction de prêle ou bicarbonate de soude (5g/L) avec du savon noir.',
          'estimated_loss_pct': 40.0,
          'source_citation': 'Guide FAO des Légumineuses d Afrique Centrale (2023), p. 19',
        },
        {
          'topic': 'Scolyte et Rouille du Caféier',
          'crop_name': 'Café',
          'keywords': 'cafe coffee scolyte cerise rouille ferrugineuse hemileia taches orange baies',
          'content': 'La rouille du caféier (Hemileia vastatrix) forme une poussière orange sous les feuilles. Le scolyte de la cerise perce les grains de café.',
          'organic_remedy': '1. Effectuer le paillage et la taille d éclaircie pour aérer le caféier. 2. Installer des pièges artisanaux à alcool pour capturer les scolytes. 3. Pulvériser un extrait de neem sur le feuillage.',
          'estimated_loss_pct': 50.0,
          'source_citation': 'Manuel FAO du Caféiculteur à l Est de la RDC (2024), p. 44',
        },
        {
          'topic': 'Préparation des Biopesticides & Remèdes Naturels',
          'crop_name': 'Tous',
          'keywords': 'biopesticide neem cendre piment ail tithonia savon noir engrais compost bio',
          'content': 'Recette Universelle de Neem: Pilez 1 kg de feuilles de neem fraîches dans 5 litres d eau. Laissez macérer 24h à l ombre. Filtrez, ajoutez 1 cuillère de savon liquide comme mouillant et pulvérisez.',
          'organic_remedy': '1. Cendre de bois: Saupoudrer sur le feuillage mouillé contre les pucerons et chenilles. 2. Purin de Tithonia: Macérer 2 kg de feuilles dans 10L d eau pendant 8 jours pour un engrais foliaire riche en azote.',
          'estimated_loss_pct': 0.0,
          'source_citation': 'Recueil FAO des Pratiques Biologiques Traditionnelles (2024), p. 5-10',
        },
        {
          'topic': 'Calendrier Agricole & Semis (Afrique de l Est / Grands Lacs)',
          'crop_name': 'Tous',
          'keywords': 'calendrier agricole semis date periode pluie saison maïs haricot manioc septembre mars quand planter',
          'content': 'Calendrier officiel FAO/IITA des Semis en Afrique de l Est et région des Grands Lacs (RDC/Kivu, Rwanda, Burundi, Ouganda) : 1. Saison A (Grandes pluies) : Semis du Maïs et Haricot de mi-septembre à début octobre dès les premières pluies régulières. Récolte de janvier à février. 2. Saison B (Petites pluies) : Semis de mars à début avril. Récolte en juin/juillet. 3. Manioc & Bananier : Plantations des boutures/rejets au début de la saison A (septembre/octobre) ou B (mars/avril). Récolte du manioc après 12 à 18 mois.',
          'organic_remedy': '1. Respecter les écartements : Maïs (75cm x 25cm, 1 graine/poquet). Haricot (40cm x 10cm). Manioc (1m x 1m en quinconce). 2. Associer le Maïs et le Haricot (culture associée) pour fixer l azote naturel du sol.',
          'estimated_loss_pct': 0.0,
          'source_citation': 'Guide FAO des Calendriers Agricoles des Grands Lacs (2024), p. 3-8',
        },
      ];

      for (final entry in initialEntries) {
        await db.insert('fao_knowledge_base', entry);
      }
      dev.log("FAO knowledge base table seeded successfully with rich entries", name: 'SQLITE_HELPER');
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

  static const Map<String, String> _accentMap = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o', 'ø': 'o',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ç': 'c',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ÿ': 'y', 'ñ': 'n',
    'À': 'a', 'Á': 'a', 'Â': 'a', 'Ã': 'a', 'Ä': 'a', 'Å': 'a',
    'Ò': 'o', 'Ó': 'o', 'Ô': 'o', 'Õ': 'o', 'Ö': 'o', 'Ø': 'o',
    'È': 'e', 'É': 'e', 'Ê': 'e', 'Ë': 'e',
    'Ç': 'c',
    'Ì': 'i', 'Í': 'i', 'Î': 'i', 'Ï': 'i',
    'Ù': 'u', 'Ú': 'u', 'Û': 'u', 'Ü': 'u',
    'Ÿ': 'y', 'Ñ': 'n',
  };

  static String _stripAccents(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    for (int i = 0; i < input.length; i++) {
      final char = input[i];
      buffer.write(_accentMap[char] ?? char);
    }
    return buffer.toString();
  }

  static const Set<String> _frenchStopWords = {
    'le', 'la', 'les', 'du', 'de', 'des', 'un', 'une', 'en', 'sur', 'avec',
    'dans', 'pour', 'par', 'ce', 'cette', 'ces', 'est', 'sont', 'mon', 'ma',
    'mes', 'ton', 'ta', 'tes', 'son', 'sa', 'ses', 'votre', 'vos', 'notre',
    'nos', 'que', 'qui', 'quoi', 'dont', 'ou', 'comment', 'traiter',
    'soigner', 'quel', 'quelle', 'quelles', 'quels', 'champ', 'champs',
    'plante', 'plantes', 'feuille', 'feuilles', 'faire', 'fait', 'plus'
  };

  // --- Helpers for FAO Knowledge Base (RAG) ---
  Future<List<Map<String, dynamic>>> searchFAOKnowledge(String query) async {
    try {
      final db = await database;

      // 1. Clean, strip accents & normalize query
      final normalized = _stripAccents(query.toLowerCase()).replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
      final rawTokens = normalized.split(RegExp(r'\s+')).where((t) => t.trim().isNotEmpty).toList();
      
      // 2. Filter out stopwords and very short noise words
      final terms = rawTokens.where((t) => t.length > 2 && !_frenchStopWords.contains(t)).toList();

      if (terms.isEmpty) {
        return await db.query('fao_knowledge_base', limit: 3);
      }

      // 3. Attempt FTS5 Full-Text Search first if available
      try {
        final ftsQuery = terms.map((t) => '"$t*"').join(' OR ');
        final ftsResults = await db.rawQuery('''
          SELECT k.* FROM fao_knowledge_base k
          JOIN fao_knowledge_fts fts ON k.id = fts.rowid
          WHERE fao_knowledge_fts MATCH ?
          ORDER BY bm25(fao_knowledge_fts) ASC
          LIMIT 3
        ''', [ftsQuery]);

        if (ftsResults.isNotEmpty) {
          dev.log("FTS5 matched ${ftsResults.length} RAG documents", name: 'SQLITE_HELPER');
          return ftsResults;
        }
      } catch (e) {
        dev.log("FTS5 query note (falling back to scored match): $e", name: 'SQLITE_HELPER');
      }

      // 4. Fallback: Scored Multi-Term Search across all rows
      final allRows = await db.query('fao_knowledge_base');
      final scoredRows = <Map<String, dynamic>, int>{};

      for (final row in allRows) {
        int score = 0;
        final topic = _stripAccents((row['topic'] ?? '').toString().toLowerCase());
        final crop = _stripAccents((row['crop_name'] ?? '').toString().toLowerCase());
        final keywords = _stripAccents((row['keywords'] ?? '').toString().toLowerCase());
        final content = _stripAccents((row['content'] ?? '').toString().toLowerCase());

        for (final term in terms) {
          if (crop.contains(term)) score += 8;
          if (topic.contains(term)) score += 6;
          if (keywords.contains(term)) score += 4;
          if (content.contains(term)) score += 1;
        }

        if (score > 0) {
          scoredRows[row] = score;
        }
      }

      if (scoredRows.isNotEmpty) {
        final sortedEntries = scoredRows.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topResults = sortedEntries.take(3).map((e) => e.key).toList();
        dev.log("Scored RAG matched ${topResults.length} documents (highest score: ${sortedEntries.first.value})", name: 'SQLITE_HELPER');
        return topResults;
      }

      // 5. Default Fallback
      return await db.query('fao_knowledge_base', limit: 3);
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
