import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:http/http.dart' as http;
import 'package:gemmea/core/services/gemma_engine_manager.dart';
import 'package:gemmea/core/utils/text_sanitizer.dart';
import 'package:gemmea/data/datasources/sqlite_helper.dart';
import 'package:gemmea/domain/repositories/chat_repository.dart';
import 'package:path_provider/path_provider.dart';

class ChatRepositoryImpl implements ChatRepository {
  final SQLiteHelper dbHelper = SQLiteHelper.instance;
  InferenceChat? _chat;

  ChatRepositoryImpl() {
    GemmaEngineManager.setResetChatCallback(() {
      dev.log("ChatRepositoryImpl: Resetting cached _chat session", name: 'CHAT_REPO_IMPL');
      _chat = null;
    });
  }

  @override
  Future<bool> checkModelInstalled() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final litertlmFile = File('${directory.path}/gemma.litertlm');
      final binFile = File('${directory.path}/gemma.bin');
      
      // Auto-migrate old gemma.bin to gemma.litertlm if it exists on the user's device
      if (await binFile.exists() && !await litertlmFile.exists()) {
        try {
          await binFile.rename(litertlmFile.path);
          dev.log("Auto-migrated old gemma.bin to gemma.litertlm successfully.", name: 'CHAT_REPO_IMPL');
        } catch (e, stack) {
          dev.log("Error migrating old gemma.bin to gemma.litertlm", name: 'CHAT_REPO_IMPL', error: e, stackTrace: stack);
        }
      }
      
      final exists = await litertlmFile.exists();
      dev.log("Checked model file existence: $exists", name: 'CHAT_REPO_IMPL');
      return exists;
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
        
        final directory = await getApplicationDocumentsDirectory();
        final modelFile = File('${directory.path}/gemma.litertlm');
        final tempModelFile = File('${directory.path}/gemma.litertlm.tmp');
        
        if (!await modelFile.exists()) {
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
            dev.log("Starting model download stream from HuggingFace...", name: 'CHAT_REPO_IMPL');
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
              await tempModelFile.rename(modelFile.path);
              dev.log("Model file successfully downloaded and placed in Documents", name: 'CHAT_REPO_IMPL');
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
        try {
          dev.log("Installing Gemma model in FlutterEdgeAi plugin...", name: 'CHAT_REPO_IMPL');
          await FlutterEdgeAi.installModel(
            modelType: ModelType.gemmaIt,
            fileType: ModelFileType.litertlm,
          )
          .fromFile(modelFile.path)
          .install();
          dev.log("Gemma model installation completed successfully", name: 'CHAT_REPO_IMPL');
        } catch (e, stack) {
          dev.log("Model install registration note: $e", name: 'CHAT_REPO_IMPL', error: e, stackTrace: stack);
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

  @override
  Stream<ModelResponse> getGemmaResponseStream(String text, [List<Message>? history]) async* {
    yield* GemmaEngineManager.runStreamWithLock(() async* {
      await GemmaEngineManager.ensureInitialized();

      final directory = await getApplicationDocumentsDirectory();
      final modelFile = File('${directory.path}/gemma.litertlm');

      if (!await modelFile.exists()) {
        dev.log("Model file not found locally", name: 'CHAT_REPO_IMPL');
        throw Exception("Le fichier de modèle local 'gemma.litertlm' est introuvable. Veuillez télécharger le modèle Gemma 4 pour lancer l'inférence locale.");
      }

      // Fetch dynamic RAG context for the specific user query only if it's a technical query (not a simple greeting)
      String faoContext = "";
      if (!_isSimpleGreeting(text)) {
        final faoDocs = await dbHelper.searchFAOKnowledge(text);
        if (faoDocs.isNotEmpty) {
          faoContext = faoDocs.map((d) {
            final content = (d['content'] ?? '').toString();
            final trimmedContent = content.length > 400 ? "${content.substring(0, 400)}..." : content;
            return "- ${d['topic']}: $trimmedContent Remède/Action: ${d['organic_remedy']} (Source: ${d['source_citation']})";
          }).join("\n");
        }
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
Tu es Gemmea, l'expert agronome IA de terrain pour l'Afrique de l'Est et la région des Grands Lacs (RDC/Kivu, Rwanda, Burundi, Ouganda).

RÈGLE ABSOLUE ANTI-AVERTISSEMENT :
INTERDICTION STRICTE d'utiliser des phrases vagues, d'esquiver les questions ou d'ajouter des clauses de non-responsabilité du type "Vérifiez auprès d'un expert local" ou "Consultez les recommandations spécifiques de votre zone". Tu ES l'expert agronomique de référence ! Donne TOUJOURS des réponses affirmatives, concrètes, datées, dosées et directement applicables sur le terrain par le fermier.

CONNAISSANCES RÉGIONALES INTÉGRÉES (AFRIQUE DE L'EST / GRANDS LACS) :
- Climat : Tropical d'altitude / équatorial à 2 saisons des pluies principales :
  * Saison A (grandes pluies) : Semis du Maïs et du Haricot de mi-septembre à début octobre aux premières pluies. Récolte en janvier/février.
  * Saison B (petites pluies) : Semis de mars à début avril. Récolte en juin/juillet.
  * Manioc & Bananier : Boutures saines plantées en début de saison A (septembre) ou saison B (mars). Récolte du manioc après 12 à 18 mois.
- Densités & Écartements : Maïs (75cm x 25cm, 1 graine/poquet), Haricot (40cm x 10cm), Manioc (1m x 1m en quinconce).
- Sol : Sols argilo-volcaniques fertiles mais sensibles à l'érosion. Préconiser le paillage, le compost bio et la culture associée Maïs-Haricot.

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
            yield TextResponse(TextSanitizer.cleanLatexAndFormatting(chunk.token, preserveWhitespace: true));
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
