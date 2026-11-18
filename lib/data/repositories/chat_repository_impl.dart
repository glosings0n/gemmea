import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:http/http.dart' as http;
import 'package:gemmea/core/services/gemma_engine_manager.dart';
import 'package:gemmea/core/utils/text_sanitizer.dart';
import 'package:gemmea/data/datasources/sqlite_helper.dart';
import 'package:gemmea/domain/entities/eac_country_profile.dart';
import 'package:gemmea/domain/repositories/chat_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sautilm_sdk/sautilm_sdk.dart';

class ChatRepositoryImpl implements ChatRepository {
  final SQLiteHelper dbHelper = SQLiteHelper.instance;
  InferenceChat? _chat;

  ChatRepositoryImpl() {
    GemmaEngineManager.setResetChatCallback(() {
      dev.log("ChatRepositoryImpl: Resetting cached _chat session", name: 'CHAT_REPO_IMPL');
      _chat = null;
    });
  }

  static const String _sharedDownloadDir = '/storage/emulated/0/Download/Gemma';
  static const String _sharedDocumentsDir = '/storage/emulated/0/Documents/Gemma';
  static const List<String> _modelFilenames = [
    'gemma.litertlm',
    'gemma-4-E2B-it.litertlm',
    'gemma.bin',
  ];

  Future<File?> _resolveModelFile() async {
    // 1. Check shared Download/Gemma directory
    for (final filename in _modelFilenames) {
      final file = File('$_sharedDownloadDir/$filename');
      if (await _isValidModel(file)) {
        dev.log("Gemma model resolved from shared Download: ${file.path}", name: 'CHAT_REPO_IMPL');
        return file;
      }
    }

    // 2. Check shared Documents/Gemma directory
    for (final filename in _modelFilenames) {
      final file = File('$_sharedDocumentsDir/$filename');
      if (await _isValidModel(file)) {
        dev.log("Gemma model resolved from shared Documents: ${file.path}", name: 'CHAT_REPO_IMPL');
        return file;
      }
    }

    // 3. Check local app documents directory
    try {
      final directory = await getApplicationDocumentsDirectory();
      for (final filename in _modelFilenames) {
        final file = File('${directory.path}/$filename');
        if (await _isValidModel(file)) {
          dev.log("Gemma model resolved from app documents: ${file.path}", name: 'CHAT_REPO_IMPL');
          return file;
        }
      }
    } catch (_) {}

    // 4. Candidate fallback locations
    final candidates = [
      '/storage/emulated/0/Download/gemmea/gemma.litertlm',
      '/storage/emulated/0/Download/gemma.litertlm',
      '/sdcard/Download/Gemma/gemma.litertlm',
      '/sdcard/Download/gemma.litertlm',
    ];
    for (final path in candidates) {
      final file = File(path);
      if (await _isValidModel(file)) {
        dev.log("Gemma model resolved from candidate path: $path", name: 'CHAT_REPO_IMPL');
        return file;
      }
    }

    return null;
  }

  Future<bool> _isValidModel(File file) async {
    try {
      if (!await file.exists()) return false;
      final len = await file.length();
      return len > 50 * 1024 * 1024;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> checkModelInstalled() async {
    try {
      final resolved = await _resolveModelFile();
      if (resolved != null) {
        dev.log("Checked model file existence: true (${resolved.path})", name: 'CHAT_REPO_IMPL');
        return true;
      }

      final directory = await getApplicationDocumentsDirectory();
      final litertlmFile = File('${directory.path}/gemma.litertlm');
      final binFile = File('${directory.path}/gemma.bin');
      
      // Auto-migrate old gemma.bin to gemma.litertlm if it exists on the user's device
      if (await binFile.exists() && !await litertlmFile.exists()) {
        try {
          await binFile.rename(litertlmFile.path);
          dev.log("Auto-migrated old gemma.bin to gemma.litertlm successfully.", name: 'CHAT_REPO_IMPL');
          return await _isValidModel(litertlmFile);
        } catch (e, stack) {
          dev.log("Error migrating old gemma.bin to gemma.litertlm", name: 'CHAT_REPO_IMPL', error: e, stackTrace: stack);
        }
      }
      
      return false;
    } catch (e, stack) {
      dev.log("Error checking model installed state", name: 'CHAT_REPO_IMPL', error: e, stackTrace: stack);
      return false;
    }
  }

  @override
  Future<void> initializeGemma(Function(double) onProgress) async {
    return GemmaEngineManager.runWithLock(() async {
      try {
        await GemmaEngineManager.ensureInitialized();
        
        File? targetFile = await _resolveModelFile();
        
        if (targetFile == null) {
          File destinationFile;
          File tempModelFile;

          try {
            final sharedDir = Directory(_sharedDownloadDir);
            if (!await sharedDir.exists()) {
              await sharedDir.create(recursive: true);
            }
            destinationFile = File('${sharedDir.path}/gemma.litertlm');
            tempModelFile = File('${sharedDir.path}/gemma.litertlm.tmp');
          } catch (_) {
            final directory = await getApplicationDocumentsDirectory();
            destinationFile = File('${directory.path}/gemma.litertlm');
            tempModelFile = File('${directory.path}/gemma.litertlm.tmp');
          }

          // Clean up any stale/incomplete temp files from previous aborted attempts
          if (await tempModelFile.exists()) {
            await tempModelFile.delete();
          }

          // Check internet connectivity first using lightweight DNS lookup
          try {
            final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 4));
            if (result.isEmpty || result.first.rawAddress.isEmpty) {
              throw const SocketException('No internet connection available');
            }
          } catch (e, stack) {
            dev.log("No internet connection for first-time download", name: 'CHAT_REPO_IMPL', error: e, stackTrace: stack);
            throw const SocketException('Internet connection is required for the first-time model download. Please connect to the internet and try again.');
          }

          final url = 'https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm/resolve/main/gemma-4-E2B-it.litertlm';
          final client = http.Client();
          
          try {
            dev.log("Starting model download stream from HuggingFace to ${destinationFile.path}...", name: 'CHAT_REPO_IMPL');
            final request = http.Request('GET', Uri.parse(url));
            final response = await client.send(request);
            
            if (response.statusCode != 200) {
              throw HttpException('Failed to download model file (Status: ${response.statusCode})');
            }
            
            final contentLength = response.contentLength ?? 0;
            int downloadedBytes = 0;
            
            // Write to temporary file first
            final IOSink sink = tempModelFile.openWrite();
            
            await response.stream.forEach((chunk) {
              downloadedBytes += chunk.length;
              sink.add(chunk);
              
              if (contentLength > 0) {
                onProgress(downloadedBytes / contentLength);
              }
            });
            
            await sink.close();

            // ONLY RENAME TO FINAL BINARY UPON 100% COMPLETE DOWNLOAD
            if (await tempModelFile.exists()) {
              await tempModelFile.rename(destinationFile.path);
              dev.log("Model file successfully downloaded to ${destinationFile.path}", name: 'CHAT_REPO_IMPL');
              targetFile = destinationFile;
            }
          } catch (e, stack) {
            dev.log("Download failed or interrupted", name: 'CHAT_REPO_IMPL', error: e, stackTrace: stack);
            if (await tempModelFile.exists()) {
              await tempModelFile.delete();
            }
            rethrow;
          } finally {
            client.close();
          }
        }

        // Register this local file as the active model in FlutterEdgeAi
        if (targetFile != null && await targetFile.exists()) {
          try {
            dev.log("Installing Gemma model from ${targetFile.path} in FlutterEdgeAi plugin...", name: 'CHAT_REPO_IMPL');
            await FlutterEdgeAi.installModel(
              modelType: ModelType.gemmaIt,
              fileType: ModelFileType.litertlm,
            )
            .fromFile(targetFile.path)
            .install();
            dev.log("Gemma model installation completed successfully", name: 'CHAT_REPO_IMPL');
          } catch (e, stack) {
            dev.log("Model install registration note: $e", name: 'CHAT_REPO_IMPL', error: e, stackTrace: stack);
          }
        }
      } catch (e, stack) {
        dev.log("Error in initializeGemma", name: 'CHAT_REPO_IMPL', error: e, stackTrace: stack);
        rethrow;
      }
    });
  }

  @override
  Future<List<Message>> getChatMessages() async {
    try {
      dev.log("Fetching chat messages from SQLite...", name: 'CHAT_REPO_IMPL');
      final list = await dbHelper.getConversations();
      return list.map((m) => Message(
        text: m['message'] as String,
        isUser: (m['role'] as String) == 'user',
      )).toList();
    } catch (e, stack) {
      dev.log("Error getting chat messages", name: 'CHAT_REPO_IMPL', error: e, stackTrace: stack);
      return [];
    }
  }

  @override
  Future<void> saveChatMessage(Message message) async {
    try {
      dev.log("Saving chat message (isUser: ${message.isUser})...", name: 'CHAT_REPO_IMPL');
      await dbHelper.insertMessage({
        'role': message.isUser ? 'user' : 'model',
        'message': message.text,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e, stack) {
      dev.log("Error saving chat message", name: 'CHAT_REPO_IMPL', error: e, stackTrace: stack);
    }
  }

  @override
  Future<void> clearChat() async {
    try {
      dev.log("Clearing chat history in SQLite...", name: 'CHAT_REPO_IMPL');
      await dbHelper.clearChat();
      _chat = null;
    } catch (e, stack) {
      dev.log("Error clearing chat history", name: 'CHAT_REPO_IMPL', error: e, stackTrace: stack);
    }
  }

  bool _isSimpleGreeting(String input) {
    final clean = input.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final greetings = {'salut', 'bonjour', 'bonsoir', 'jambo', 'habari', 'coucou', 'hello', 'hi', 'merci', 'cv', 'comment vas tu', 'comment allez vous'};
    return greetings.contains(clean) || (clean.split(' ').length <= 2 && greetings.any((g) => clean.startsWith(g)));
  }

  /// Builds deterministic EAC/DRC zone context + plot calculations via `sautilm_sdk`.
  @visibleForTesting
  static String buildDeterministicAgronomySupplement(
    String query, {
    String? countryCode,
  }) {
    final profile = EacCountryProfile.byCode(
      countryCode ?? SQLiteHelper.currentCountryCode,
    );
    final lines = <String>[
      'ZONE AGRONOMIQUE ACTIVE : ${profile.fullNameFr} (${profile.code}) | '
          'Institut NARS : ${profile.narsInstitute} | '
          'Régime pluviométrique : ${profile.rainfallRegimeSummary}',
    ];

    final normalized = query.replaceAll(',', '.');
    final lower = normalized.toLowerCase();

    final dimMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*m\s*(?:x|×|\*|sur)\s*(\d+(?:\.\d+)?)\s*m',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (dimMatch != null &&
        (lower.contains('manioc') ||
            lower.contains('cassava') ||
            lower.contains('bouture') ||
            lower.contains('plant'))) {
      final lengthM = double.tryParse(dimMatch.group(1)!);
      final widthM = double.tryParse(dimMatch.group(2)!);
      if (lengthM != null && widthM != null && lengthM > 0 && widthM > 0) {
        final exactCuttings = AgronomyPlotCalculator.cassavaCuttings1mBy1m(
          lengthMeters: lengthM,
          widthMeters: widthM,
        );
        final withReserve = AgronomyPlotCalculator.cassavaCuttings1mBy1m(
          lengthMeters: lengthM,
          widthMeters: widthM,
          reservePct: 0.10,
        );
        lines.add(
          'CALCUL EXACT MANIOC (${lengthM}m x ${widthM}m à 1m x 1m) : '
          '$exactCuttings boutures exactes ($withReserve avec +10% de réserve de regarnissage).',
        );
      }
    }

    final neemAreaMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:m2|m²)',
      caseSensitive: false,
    ).firstMatch(normalized);
    if (neemAreaMatch != null && lower.contains('neem')) {
      final area = double.tryParse(neemAreaMatch.group(1)!);
      if (area != null && area > 0) {
        final liters = AgronomyPlotCalculator.neemBiopesticideLiters(
          areaSqMeters: area,
        );
        lines.add(
          'CALCUL EXACT BIOPESTICIDE NEEM ($area m²) : $liters litres de solution foliaire prêts à pulvériser.',
        );
      }
    }

    return lines.join('\n');
  }

  @override
  Stream<ModelResponse> getGemmaResponseStream(String text, [List<Message>? history]) async* {
    yield* GemmaEngineManager.runStreamWithLock(() async* {
      await GemmaEngineManager.ensureInitialized();

      final modelFile = await _resolveModelFile();

      if (modelFile == null || !await modelFile.exists()) {
        dev.log("Model file not found locally", name: 'CHAT_REPO_IMPL');
        throw Exception("Le fichier de modèle local 'gemma.litertlm' est introuvable. Veuillez télécharger le modèle Gemma 4 pour lancer l'inférence locale.");
      }

      // Fetch dynamic RAG context for the specific user query only if it's a technical query (not a simple greeting)
      String faoContext = "";
      if (!_isSimpleGreeting(text)) {
        final supplement = buildDeterministicAgronomySupplement(text);
        final faoDocs = await dbHelper.searchFAOKnowledge(text);
        final docsBlock = faoDocs.isNotEmpty
            ? faoDocs.map((d) {
                final content = (d['content'] ?? '').toString();
                final trimmedContent = content.length > 400 ? "${content.substring(0, 400)}..." : content;
                return "- ${d['topic']}: $trimmedContent Remède/Action: ${d['organic_remedy']} (Source: ${d['source_citation']})";
              }).join("\n")
            : "";
        faoContext = docsBlock.isNotEmpty ? "$supplement\n$docsBlock" : supplement;
      }

      String historyFormatted = "";
      if (history != null && history.length > 1) {
        final recentHistory = _getRecentHistoryWindow(history);
        if (recentHistory.isNotEmpty) {
          final formattedHistoryItems = recentHistory.map((m) => "- ${m.isUser ? 'Utilisateur' : 'Gemmea'}: ${m.text}").join("\n");
          historyFormatted = "\n\nHISTORIQUE DES 5 DERNIERS MESSAGES :\n$formattedHistoryItems";
        }
      }

      final systemPrompt = '''
Tu es Gemmea, l'assistant agronome IA hors-ligne pour la RDC (Kivu, Ituri) et l'Afrique de l'Est (Rwanda, Burundi, Ouganda, Kenya, Tanzanie).

RÈGLE DE RIGUEUR SCIENTIFIQUE ET DE VÉRACITÉ :
1. Appuie-toi en priorité sur les [DONNÉES OFFICIELLES FAO DE RÉFÉRENCE] ci-dessous lorsque des fiches locales sont fournies, en citant leur source exacte.
2. N'invente JAMAIS un chiffre, un dosage de pesticide de synthèse, une date de semis locale ou une référence FAO absente des documents vérifiés.
3. Si une culture, une maladie rare, une posologie phytosanitaire ou une zone agro-écologique précise dépasse les fiches disponibles hors ligne, dis-le honnêtement et recommande une confirmation auprès d'un agronome de terrain ou des instituts nationaux (INERA, NARO, RAB, ISABU, KALRO, TARI).

REPÈRES AGRO-CLIMATIQUES (NE PAS GÉNÉRALISER SANS PRÉCISER LA ZONE) :
- Grands Lacs bimodaux (Nord/Sud-Kivu, Ituri Sud, Rwanda, Burundi, Ouganda Ouest) :
  * Saison A (grandes pluies) : semis généralement entre septembre et novembre selon l'altitude ; récolte janvier/février.
  * Saison B (petites pluies) : semis généralement entre mars et avril ; récolte juin/juillet.
  * Note Afrique de l'Est : au Kenya/Tanzanie/Nord-Ouganda, les régimes varient (Long Rains mars–mai, Short Rains oct–déc, ou zones unimodales du centre/sud de la Tanzanie). Demandez ou précisez la zone si non fournie.
- Pratiques culture associées fréquentes (Grands Lacs, à adapter selon variété et pente) : paillage, compost organique, boutures saines de manioc certifiées (ex: TME 419), protection antiérosive sur collines.

RÈGLES D'EXPRESSION CONVERSATIONNELLE :
1. Réponds STRICTEMENT et DIRECTEMENT à la question posée sans tourner autour du pot.
2. Pour les salutations (ex: "salut", "bonjour", "habari", "merci") : réponds de manière courtoise, naturelle et TRÈS BRÈVE (1 sentence).
3. Pour les questions techniques, de calendrier ou de traitement : réponds directement avec une structure Markdown claire (mots-clés en **gras**, étapes numérotées 1. 2. 3., conseils sous forme de puces - ).
4. N'utilise AUCUN émoji ni icône.
$historyFormatted
${faoContext.isNotEmpty ? '\n\nDONNÉES OFFICIELLES FAO DE RÉFÉRENCE :\n$faoContext' : ''}
''';

      InferenceModel model;
      try {
        dev.log("Attempting CPU backend initialization for Gemma with 2048 tokens...", name: 'CHAT_REPO_IMPL');
        model = await FlutterEdgeAi.getActiveModel(
          supportImage: true,
          maxTokens: 2048,
          preferredBackend: PreferredBackend.cpu,
        );
      } catch (e) {
        dev.log("Fallback to GPU/default backend for Gemma...", name: 'CHAT_REPO_IMPL');
        model = await FlutterEdgeAi.getActiveModel(
          supportImage: true,
          maxTokens: 2048,
          preferredBackend: PreferredBackend.gpu,
        );
      }

      _chat = await model.createChat(
        modelType: ModelType.gemmaIt,
        systemInstruction: systemPrompt,
      );

      try {
        dev.log("Sending query chunk to Gemma session...", name: 'CHAT_REPO_IMPL');
        final userMessage = Message.text(text: text, isUser: true);
        await _chat!.addQuery(userMessage);
        
        await for (final chunk in _chat!.generateChatResponseAsync()) {
          if (chunk is TextResponse) {
            final solved = DeterministicMathSolver.solveCalcTags(chunk.token);
            yield TextResponse(TextSanitizer.cleanLatexAndFormatting(solved, preserveWhitespace: true));
          } else {
            yield chunk;
          }
        }
      } catch (e, stack) {
        dev.log("Error generating chat response stream", name: 'CHAT_REPO_IMPL', error: e, stackTrace: stack);
        _chat = null;
        if (e.toString().contains("channel-error") || e.toString().contains("PlatformException")) {
          throw Exception("Impossible d'établir la connexion avec le moteur du modèle local.\n\nVeuillez relancer l'application.");
        }
        rethrow;
      }
    });
  }

  List<Message> _getRecentHistoryWindow(List<Message>? history) {
    if (history == null || history.length <= 1) return [];
    final validHistory = history
        .where((m) =>
            m.text.trim().isNotEmpty &&
            !m.text.startsWith("Jambo") &&
            !m.text.startsWith("Toutes mes excuses") &&
            !m.text.startsWith("Je ne peux pas"))
        .toList();
    if (validHistory.length <= 1) return [];
    
    // Take the last 5 messages from history before the current query
    final past = validHistory.sublist(0, validHistory.length - 1);
    final recent = past.length > 5 ? past.sublist(past.length - 5) : past;
    
    return recent.map((m) {
      final text = m.text.length > 250 ? "${m.text.substring(0, 250)}..." : m.text;
      return Message.text(text: text, isUser: m.isUser);
    }).toList();
  }

}
