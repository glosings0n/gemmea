import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_litertlm/flutter_gemma_litertlm.dart';
import 'package:http/http.dart' as http;
import 'package:gemmea/data/datasources/sqlite_helper.dart';
import 'package:gemmea/domain/repositories/chat_repository.dart';
import 'package:path_provider/path_provider.dart';

class ChatRepositoryImpl implements ChatRepository {
  final SQLiteHelper dbHelper = SQLiteHelper.instance;
  InferenceChat? _chat;
  static bool _isEngineInitialized = false;

  static Future<void> _ensureEngineInitialized() async {
    if (!_isEngineInitialized) {
      try {
        dev.log("Initializing FlutterGemma LiteRT-LM Engine...", name: 'CHAT_REPO_IMPL');
        await FlutterGemma.initialize(
          inferenceEngines: const [LiteRtLmEngine()],
        );
        _isEngineInitialized = true;
        dev.log("FlutterGemma engine initialized successfully", name: 'CHAT_REPO_IMPL');
      } catch (e, stack) {
        dev.log("Engine initialization note: $e", name: 'CHAT_REPO_IMPL', error: e, stackTrace: stack);
      }
    }
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
    try {
      await _ensureEngineInitialized();
      
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
  Stream<ModelResponse> getGemmaResponseStream(String text) async* {
    if (_chat == null) {
      final directory = await getApplicationDocumentsDirectory();
      final modelFile = File('${directory.path}/gemma.litertlm');
      
      if (await modelFile.exists()) {
        bool loaded = false;
        // Try GPU backend first
        try {
          dev.log("Attempting GPU backend initialization for Gemma...", name: 'CHAT_REPO_IMPL');
          await FlutterGemma.installModel(
            modelType: ModelType.gemmaIt,
            fileType: ModelFileType.litertlm,
          )
          .fromFile(modelFile.path)
          .install();

          final model = await FlutterGemma.getActiveModel(
            maxTokens: 1024,
            preferredBackend: PreferredBackend.gpu,
          );
          // Perform FAO RAG Query to fetch official grounded citations
          final faoDocs = await dbHelper.searchFAOKnowledge(text);
          final faoContext = faoDocs.map((d) => "- ${d['topic']}: ${d['content']} Remède: ${d['organic_remedy']} (Source: ${d['source_citation']})").join("\n");

          final systemPrompt = '''
Tu es Gemmea, un assistant agronome utile sous forme d'IA hors ligne destiné aux agriculteurs de l'Est de la République Démocratique du Congo (RDC) et de l'Afrique de l'Est.
Salue toujours en disant 'Jambo 👋🏾' (avec l'émoji noir 👋🏾).

RÈGLE DE ANCRAGE (RAG FAO) :
Voici les extraits officiels de la FAO pertinents extraits de la base locale :
$faoContext

Utilise ces données FAO pour fournir des conseils directs, précis et écologiques. Reste très concis, clair, et cite la source FAO.
''';

          _chat = await model.createChat(
            modelType: ModelType.gemmaIt,
            systemInstruction: systemPrompt,
          );
          loaded = true;
          dev.log("Modèle Gemma chargé avec succès sur le moteur LiteRT-LM GPU !", name: 'CHAT_REPO_IMPL');
        } catch (gpuError, stack) {
          dev.log("Échec du chargement du moteur GPU", name: 'CHAT_REPO_IMPL', error: gpuError, stackTrace: stack);
          if (gpuError.toString().contains("channel-error") || gpuError.toString().contains("PlatformException")) {
            throw Exception("Impossible d'établir la connexion avec le moteur du modèle local.\n\nVeuillez fermer complètement l'application et la relancer à froid (par exemple, relancez 'flutter run' dans votre terminal) pour lier les bibliothèques locales MediaPipe.");
          }
        }

        // Fallback to CPU if GPU failed
        if (!loaded) {
          try {
            dev.log("Attempting CPU fallback backend for Gemma...", name: 'CHAT_REPO_IMPL');
            final model = await FlutterGemma.getActiveModel(
              maxTokens: 1024,
              preferredBackend: PreferredBackend.cpu,
            );
             final faoDocs = await dbHelper.searchFAOKnowledge(text);
             final faoContext = faoDocs.map((d) => "- ${d['topic']}: ${d['content']} Remède: ${d['organic_remedy']} (Source: ${d['source_citation']})").join("\n");

             final systemPrompt = '''
Tu es Gemmea, un assistant agronome utile sous forme d'IA hors ligne destiné aux agriculteurs de l'Est de la République Démocratique du Congo (RDC) et de l'Afrique de l'Est.
Salue toujours en disant 'Jambo 👋🏾' (avec l'émoji noir 👋🏾).

RÈGLE DE ANCRAGE (RAG FAO) :
Voici les extraits officiels de la FAO pertinents extraits de la base locale :
$faoContext

Utilise ces données FAO pour fournir des conseils directs, précis et écologiques. Reste très concis, clair, et cite la source FAO.
''';

             _chat = await model.createChat(
              modelType: ModelType.gemmaIt,
              systemInstruction: systemPrompt,
            );
            loaded = true;
            dev.log("Modèle Gemma chargé avec succès sur le moteur LiteRT-LM CPU !", name: 'CHAT_REPO_IMPL');
          } catch (cpuError, stack) {
            dev.log("Échec du chargement du moteur CPU", name: 'CHAT_REPO_IMPL', error: cpuError, stackTrace: stack);
            if (cpuError.toString().contains("channel-error") || cpuError.toString().contains("PlatformException") || cpuError.toString().contains("StateError")) {
              throw Exception("Impossible d'établir la connexion avec le moteur du modèle local.\n\nVeuillez fermer complètement l'application et la relancer à froid (par exemple, relancez 'flutter run' dans votre terminal) pour lier les bibliothèques locales MediaPipe.");
            }
            yield* _mockResponseStream(text);
            return;
          }
        }
      } else {
        dev.log("Model file not found locally, defaulting to local fallback stream", name: 'CHAT_REPO_IMPL');
        yield* _mockResponseStream(text);
        return;
      }
    }

    try {
      dev.log("Sending query chunk to Gemma session...", name: 'CHAT_REPO_IMPL');
      final userMessage = Message.text(text: text, isUser: true);
      await _chat!.addQuery(userMessage);
      
      await for (final chunk in _chat!.generateChatResponseAsync()) {
        yield chunk;
      }
    } catch (e, stack) {
      dev.log("Error generating chat response stream", name: 'CHAT_REPO_IMPL', error: e, stackTrace: stack);
      if (e.toString().contains("channel-error") || e.toString().contains("PlatformException")) {
        throw Exception("Impossible d'établir la connexion avec le moteur du modèle local.\n\nVeuillez fermer complètement l'application et la relancer à froid (par exemple, relancez 'flutter run' dans votre terminal) pour lier les bibliothèques locales MediaPipe.");
      }
      yield* _mockResponseStream(text);
    }
  }

  Stream<ModelResponse> _mockResponseStream(String text) async* {
    String reply = "";
    final input = text.toLowerCase();
    
    if (input.contains("manioc") || input.contains("cassava")) {
      reply = "Jambo 👋🏾 ! Pour planter du manioc de manière optimale : coupez des boutures de tiges saines (20 à 30 cm de long, 4 à 6 nœuds). Plantez-les inclinées à 45 degrés dans un sol limoneux bien drainé, à 1 mètre d'intervalle. La mosaïque du manioc (CMD) est une maladie grave qui provoque l'enroulement et le jaunissement des feuilles. Éliminez-la en déracinant les plants infectés et en utilisant des boutures résistantes fournies par l'IITA ou l'INERA.";
    } else if (input.contains("maïs") || input.contains("corn") || input.contains("maize")) {
      reply = "Jambo 👋🏾 ! Le maïs a besoin d'un sol riche en azote. Plantez au début de la saison des pluies. Gardez une distance de 25 cm sur la ligne et 75 cm entre les lignes. La rouille du maïs provoque des pustules jaunes poussiéreuses sur les feuilles. Pratiquez la rotation des cultures et désherbez tôt pour prévenir la rouille.";
    } else if (input.contains("banane") || input.contains("banana") || input.contains("bananier")) {
      reply = "Jambo 👋🏾 ! Pour les bananiers, sélectionnez des rejets sains (baïonnettes) de 1,5 m de haut. Creusez des trous de 60x60x60 cm espacés de 3 mètres. Ajoutez du compost riche au fond. Surveillez le flétrissement bactérien (BXW). Coupez les bourgeons mâles dès la fin de la formation du régime et désinfectez vos outils à la flamme.";
    } else if (input.contains("café") || input.contains("coffee") || input.contains("caféier")) {
      reply = "Jambo 👋🏾 ! À l'Est de la RDC, le caféier (Arabica/Robusta) a besoin d'un ombrage partiel et de paillage pour conserver l'humidité. Taillez régulièrement pour aérer l'arbre. Traitez le scolyte des baies du café à l'aide de pièges à alcool ou de solutions organiques à base de neem.";
    } else if (input.contains("haricot") || input.contains("bean") || input.contains("haricots")) {
      reply = "Jambo 👋🏾 ! Les haricots s'associent parfaitement avec le maïs. Semez à 3-5 cm de profondeur, espacés de 10-15 cm. Ils enrichissent le sol en azote. Surveillez les pucerons et traitez-les avec du savon noir ou un extrait de neem.";
    } else if (input.contains("eau") || input.contains("irrigation") || input.contains("pluie") || input.contains("calendrier") || input.contains("water")) {
      reply = "Jambo 👋🏾 ! Arrosez tôt le matin ou tard le soir. Le manioc craint l'excès d'eau stagnante. J'ai intégré votre calendrier d'irrigation local pour ajuster automatiquement les dates selon vos indications de pluie ou de sécheresse !";
    } else if (input.contains("ravageur") || input.contains("maladie") || input.contains("neem") || input.contains("pest")) {
      reply = "Jambo 👋🏾 ! Pour un insecticide biologique : pilez 1 kg de feuilles ou graines de neem, laissez macérer dans 5 litres d'eau pendant 24h, filtrez, ajoutez une cuillère de savon de Marseille et pulvérisez. Cela élimine chenilles, criquets et pucerons de façon écologique.";
    } else if (input.contains("hello") || input.contains("hi") || input.contains("hey") || input.contains("jambo") || input.contains("bonjour")) {
      reply = "Jambo 👋🏾 ! Je suis Gemmea, votre compagnon agronome hors ligne pour l'Est de la RDC. Posez-moi vos questions sur le manioc, le maïs, le café, la banane, le haricot, le calendrier d'irrigation ou les remèdes biologiques !";
    } else if (input.contains("merci") || input.contains("thank") || input.contains("thanks")) {
      reply = "Je vous en prie ! Que votre sol soit riche et votre récolte abondante. N'hésitez pas si vous avez d'autres questions sur vos cultures.";
    } else {
      reply = "L'agriculture à l'Est de la RDC et en Afrique de l'Est exige de la patience et du savoir-faire. Parlez-moi de vos cultures (Banane, Haricot, Manioc, Patate douce, Maïs, Café) ou décrivez les ravageurs que vous observez, et je vous proposerai des solutions biologiques adaptées !";
    }

    final words = reply.split(" ");
    for (var word in words) {
      await Future.delayed(const Duration(milliseconds: 60));
      yield TextResponse("$word ");
    }
  }
}
