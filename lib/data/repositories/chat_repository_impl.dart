import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter_gemma/flutter_gemma.dart';
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

        // Register this local file as the active model in FlutterGemma
        try {
          dev.log("Installing Gemma model in FlutterGemma plugin...", name: 'CHAT_REPO_IMPL');
          await FlutterGemma.installModel(
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

  @override
  Stream<ModelResponse> getGemmaResponseStream(String text, [List<Message>? history]) async* {
    yield* GemmaEngineManager.runStreamWithLock(() async* {
      await GemmaEngineManager.ensureInitialized();

      if (_chat == null) {
        final directory = await getApplicationDocumentsDirectory();
        final modelFile = File('${directory.path}/gemma.litertlm');
        
        if (await modelFile.exists()) {
          bool loaded = false;
          try {
            dev.log("Attempting CPU backend initialization for Gemma...", name: 'CHAT_REPO_IMPL');
            try {
              await FlutterGemma.installModel(
                modelType: ModelType.gemmaIt,
                fileType: ModelFileType.litertlm,
              )
              .fromFile(modelFile.path)
              .install();
            } catch (e) {
              dev.log("Model install registration note: $e", name: 'CHAT_REPO_IMPL');
            }

            final model = await FlutterGemma.getActiveModel(
              maxTokens: 1024,
              preferredBackend: PreferredBackend.cpu,
            );

            final faoDocs = await dbHelper.searchFAOKnowledge(text);
            final faoContext = faoDocs.map((d) => "- ${d['topic']}: ${d['content']} Remède: ${d['organic_remedy']} (Source: ${d['source_citation']})").join("\n");

            String historyFormatted = "";
            if (history != null && history.length > 1) {
              final recentHistory = _getRecentHistoryWindow(history);
              if (recentHistory.isNotEmpty) {
                final formattedHistoryItems = recentHistory.map((m) => "${m.isUser ? 'Utilisateur' : 'Gemmea'}: ${m.text}").join("\n");
                historyFormatted = "\n\nHISTORIQUE RÉCENT DE LA CONVERSATION :\n$formattedHistoryItems";
              }
            }

            final systemPrompt = '''
Tu es Gemmea, un assistant agronome utile sous forme d'IA hors ligne destiné aux agriculteurs de l'Est de la République Démocratique du Congo (RDC) et de l'Afrique de l'Est.
NE salue PAS à chaque message. Ne dis jamais 'Jambo' ou 'Bonjour' lors des réponses de suivi dans la conversation. Réponds directement et précisément aux questions de l'utilisateur.
N'utilise AUCUN émoji dans tes réponses. Rédige un texte purement professionnel sans émojis ni icônes.

RÈGLE D'ANCRAGE (RAG FAO) :
Voici les extraits officiels de la FAO pertinents extraits de la base locale :
$faoContext
$historyFormatted

Utilise ces données FAO et cet historique pour fournir des conseils directs, précis et écologiques. Reste très concis, clair, et cite la source FAO.
''';

            _chat = await model.createChat(
              modelType: ModelType.gemmaIt,
              systemInstruction: systemPrompt,
            );

            loaded = true;
            dev.log("Modèle Gemma chargé avec succès sur le moteur LiteRT-LM CPU !", name: 'CHAT_REPO_IMPL');
          } catch (cpuError, stack) {
            dev.log("Échec du chargement du moteur CPU", name: 'CHAT_REPO_IMPL', error: cpuError, stackTrace: stack);
          }

          if (!loaded) {
            try {
              dev.log("Attempting GPU fallback backend for Gemma...", name: 'CHAT_REPO_IMPL');
              final model = await FlutterGemma.getActiveModel(
                maxTokens: 1024,
                preferredBackend: PreferredBackend.gpu,
              );
              final faoDocs = await dbHelper.searchFAOKnowledge(text);
              final faoContext = faoDocs.map((d) => "- ${d['topic']}: ${d['content']} Remède: ${d['organic_remedy']} (Source: ${d['source_citation']})").join("\n");

              String historyFormatted = "";
              if (history != null && history.length > 1) {
                final recentHistory = _getRecentHistoryWindow(history);
                if (recentHistory.isNotEmpty) {
                  final formattedHistoryItems = recentHistory.map((m) => "${m.isUser ? 'Utilisateur' : 'Gemmea'}: ${m.text}").join("\n");
                  historyFormatted = "\n\nHISTORIQUE RÉCENT DE LA CONVERSATION :\n$formattedHistoryItems";
                }
              }

              final systemPrompt = '''
Tu es Gemmea, un assistant agronome utile sous forme d'IA hors ligne destiné aux agriculteurs de l'Est de la République Démocratique du Congo (RDC) et de l'Afrique de l'Est.
NE salue PAS à chaque message. Ne dis jamais 'Jambo' ou 'Bonjour' lors des réponses de suivi dans la conversation. Réponds directement et précisément aux questions de l'utilisateur.
N'utilise AUCUN émoji dans tes réponses. Rédige un texte purement professionnel sans émojis ni icônes.

MISE EN FORME MARKDOWN :
Utilise une mise en forme Markdown riche et très soignée (titres avec ###, texte important en **gras**, sous-titres, listes à puces -) pour que tes réponses soient claires, très lisibles, structurées et professionnelles pour l'agriculteur. Ne mets simplement aucun émoji.

RÈGLE D'ANCRAGE (RAG FAO) :
Voici les extraits officiels de la FAO pertinents extraits de la base locale :
$faoContext
$historyFormatted

Utilise ces données FAO et cet historique pour fournir des conseils directs, précis, détaillés et écologiques. Reste structuré, clair, et cite la source FAO.
''';

              _chat = await model.createChat(
                modelType: ModelType.gemmaIt,
                systemInstruction: systemPrompt,
              );

              loaded = true;
              dev.log("Modèle Gemma chargé avec succès sur le moteur LiteRT-LM GPU !", name: 'CHAT_REPO_IMPL');
            } catch (gpuError, stack) {
              dev.log("Échec du chargement du moteur GPU", name: 'CHAT_REPO_IMPL', error: gpuError, stackTrace: stack);
              throw Exception("Échec de l'initialisation du moteur LiteRT Gemma sur GPU/CPU local. Veuillez vérifier le fichier gemma.litertlm.");
            }
          }
        } else {
          dev.log("Model file not found locally", name: 'CHAT_REPO_IMPL');
          throw Exception("Le fichier de modèle local 'gemma.litertlm' est introuvable. Veuillez télécharger le modèle Gemma 4 pour lancer l'inférence locale.");
        }
      }

      try {
        dev.log("Sending query chunk to Gemma session...", name: 'CHAT_REPO_IMPL');
        final userMessage = Message.text(text: text, isUser: true);
        await _chat!.addQuery(userMessage);
        
        await for (final chunk in _chat!.generateChatResponseAsync()) {
          if (chunk is TextResponse) {
            yield TextResponse(TextSanitizer.cleanLatexAndFormatting(chunk.token));
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
    
    final past = validHistory.sublist(0, validHistory.length - 1);
    final recent = past.length > 4 ? past.sublist(past.length - 4) : past;
    
    return recent.map((m) {
      final text = m.text.length > 250 ? "${m.text.substring(0, 250)}..." : m.text;
      return Message.text(text: text, isUser: m.isUser);
    }).toList();
  }

}
