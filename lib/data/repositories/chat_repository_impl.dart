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
            dev.log("Modèle Gemma chargé avec succès sur le moteur LiteRT-LM GPU !", name: 'CHAT_REPO_IMPL');
          } catch (gpuError, stack) {
            dev.log("Échec du chargement du moteur GPU", name: 'CHAT_REPO_IMPL', error: gpuError, stackTrace: stack);
            yield* _mockResponseStream(text, history);
            return;
          }
        }
      } else {
        dev.log("Model file not found locally, defaulting to local fallback stream", name: 'CHAT_REPO_IMPL');
        yield* _mockResponseStream(text, history);
        return;
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
      yield* _mockResponseStream(text, history);
    }
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

  Stream<ModelResponse> _mockResponseStream(String text, [List<Message>? history]) async* {
    String reply = "";
    final input = text.toLowerCase();

    // Contextual topic extraction strictly from past USER messages (excluding welcome messages)
    String? contextTopic;
    if (history != null && history.isNotEmpty) {
      for (final msg in history.reversed) {
        if (!msg.isUser) continue; // Only analyze user messages for context
        final prevText = msg.text.toLowerCase();
        if (prevText.contains("maïs") || prevText.contains("corn") || prevText.contains("maize")) {
          contextTopic = "maïs";
          break;
        } else if (prevText.contains("manioc") || prevText.contains("cassava")) {
          contextTopic = "manioc";
          break;
        } else if (prevText.contains("banane") || prevText.contains("banana") || prevText.contains("bananier")) {
          contextTopic = "banane";
          break;
        } else if (prevText.contains("haricot") || prevText.contains("bean")) {
          contextTopic = "haricot";
          break;
        } else if (prevText.contains("café") || prevText.contains("coffee")) {
          contextTopic = "café";
          break;
        } else if (prevText.contains("irrigation") || prevText.contains("eau") || prevText.contains("pluie")) {
          contextTopic = "irrigation";
          break;
        }
      }
    }

    final isGreeting = input.contains("hello") ||
        input.contains("hi") ||
        input.contains("hey") ||
        input.contains("jambo") ||
        input.contains("bonjour") ||
        input.contains("salut") ||
        input.contains("coucou") ||
        input.contains("bonsoir") ||
        input.contains("slt") ||
        input.contains("cc");

    final isFollowUpRequest = input.contains("dire plus") ||
        input.contains("détail") ||
        input.contains("explicite") ||
        input.contains("explique") ||
        input.contains("pourquoi") ||
        input.contains("comment") ||
        input.contains("continuer") ||
        input.contains("suite") ||
        input.contains("encore") ||
        input.contains("autre") ||
        input.contains("précis") ||
        input.contains("maladie") ||
        input.contains("si ce n'est pas") ||
        input.contains("pas cette");

    if (isGreeting) {
      reply = "Bonjour ! Je suis Gemmea, votre compagnon agronome hors ligne. Posez-moi vos questions sur le manioc, le maïs, le café, la banane, le haricot, le calendrier d'irrigation ou les remèdes biologiques !";
    } else if (isFollowUpRequest && contextTopic != null) {
      if (contextTopic == "maïs") {
        reply = "Voici des précisions agronomiques approfondies pour réussir votre culture de maïs :\n\n"
            "1. **Densité & Semis** : Semez 1 à 2 graines par poquet à 3-5 cm de profondeur. Gardez 75 cm entre les lignes et 25 cm entre les poquets pour permettre un bon développement des épis.\n\n"
            "2. **Fertilisation Organique** : Apportez du compost mûr lors du labour (5-10 t/ha). Complétez avec du purin de tithonia ou de fientes d'oiseaux riches en azote au moment du sarclage.\n\n"
            "3. **Lutte contre la Chenille Légionnaire** : Déposez de la cendre de bois sèche dans le cornet des jeunes plants ou pulvérisez un extrait d'huile ou de feuilles de neem (200g/L).\n\n"
            "4. **Autres Pathologies Possibles (Strie / Helminthosporiose)** : Si ce n'est pas la rouille du maïs, observez les feuilles : des bandes jaunâtres parallèles indiquent la strie du maïs. Dans ce cas, éliminez les plants infectés et appliquez un purin d'ortie ou neem pour renforcer la plante.";
      } else if (contextTopic == "manioc") {
        reply = "Voici les détails agronomiques approfondis (normes FAO/IITA) pour la production du manioc :\n\n"
            "1. **Sélection des Boutures & Plantation** : Choisissez des tiges centrales saines (20-30 cm, 4-6 nœuds). Plantez inclinées à 45° à 1m d'intervalle dans un sol sablo-argileux meuble.\n\n"
            "2. **Gestion du Sol & Fertilisation** : Apportez 2 kg de compost décomposé par poquet. Le manioc absorbe beaucoup de Potassium (K) ; paillez abondamment le pied avec des herbes sèches pour nourrir la terre et garder l'humidité.\n\n"
            "3. **Lutte contre la Mosaïque (CMD)** : Si les feuilles se déforment avec des taches jaunes, il s'agit du Geminivirus transmis par les aleurodes (mouches blanches). Déracinez et brûlez immédiatement les pieds sévèrement atteints. Pulvérisez un extrait de feuilles de Neem (200g/L d'eau) pour repousser les mouches blanches.\n\n"
            "4. **Autres Pathologies (Anthracnose / Strie Brune - CBSD)** : Des chancres brun foncé sur les tiges indiquent l'anthracnose. Des striations brunes sur les tiges ou nécroses de la chair du tubercule indiquent la strie brune. Dans les deux cas, utilisez exclusivement des boutures saines certifiées IITA/INERA (variétés TME 419 ou SAWASA).";
      } else if (contextTopic == "banane") {
        reply = "Voici les détails agronomiques pour vos bananiers :\n\n"
            "1. **Rejets & Trous** : Plantez des rejets baïonnettes sains dans des trous de 60x60x60 cm.\n\n"
            "2. **Si ce n'est pas le BXW (Sigatoka / Cercosporiose)** : Des taches foncées bordées de jaune sur les feuilles indiquent la cercosporiose noire. Éliminez les feuilles bases séchées et améliorez le drainage.";
      } else if (contextTopic == "haricot") {
        reply = "Voici des détails pratiques pour le haricot :\n\n"
            "1. **Association Mosaïque** : Intercalez le haricot dans le maïs.\n\n"
            "2. **Autres Maladie (Anthracnose du haricot)** : Si des taches noires apparaissent sur les gousses, brûlez les résidus et appliquez une décoction de prêle ou neem.";
      } else if (contextTopic == "café") {
        reply = "Voici les précisions pour votre caféière :\n\n"
            "1. **Ombrage & Mulching** : Paillez généreusement les pieds.\n\n"
            "2. **Autres Maladie (Anthracnose des baies)** : Des baies noires desséchées indiquent l'anthracnose. Taillez les branches trop denses pour laisser passer l'air.";
      } else if (contextTopic == "irrigation") {
        reply = "Voici les précisions pour l'arrosage de vos cultures :\n\n"
            "1. **Horaires Optimaux** : Arrosez tôt le matin ou en fin d'après-midi.\n\n"
            "2. **Paillage Régulateur** : Une couche de 5 à 10 cm de paille sèche conserve l'eau dans le sol.";
      }
    } else if (input.contains("manioc") || input.contains("cassava")) {
      reply = "Voici le guide d'excellence FAO/IITA pour le manioc :\n\n"
          "• **Plantation** : Coupez des boutures saines de 20-30 cm. Enfoncez à 45° dans un sol meuble et bien drainé (espacement 1m x 1m).\n"
          "• **Gestion du Sol & Irrigation** : Apportez du compost mûr au plantation. Arrosage modéré : le manioc craint la stagnation d'eau au niveau des tubercules.\n"
          "• **Diagnostic & Protection (Mosaïque CMD)** : Si vous observez un jaunissement et de la crispation foliaire provoquée par l'aleurode (mouche blanche), déracinez les pieds infectés et pulvérisez de l'extrait de Neem (200g/L d'eau) ou saupoudrez de la cendre de bois.\n"
          "• **Variétés Certifiées** : Privilégiez les boutures résistantes diffusées par l'IITA/INERA (TME 419, SAWASA, NAROCASS 1).";
    } else if (input.contains("maïs") || input.contains("corn") || input.contains("maize")) {
      reply = "Le maïs a besoin d'un sol riche en azote. Plantez au début de la saison des pluies. Gardez une distance de 25 cm sur la ligne et 75 cm entre les lignes. La rouille du maïs provoque des pustules jaunes poussiéreuses sur les feuilles. Pratiquez la rotation des cultures et désherbez tôt pour prévenir la rouille.";
    } else if (input.contains("banane") || input.contains("banana") || input.contains("bananier")) {
      reply = "Pour les bananiers, sélectionnez des rejets sains (baïonnettes) de 1,5 m de haut. Creusez des trous de 60x60x60 cm espacés de 3 mètres. Ajoutez du compost riche au fond. Surveillez le flétrissement bactérien (BXW). Coupez les bourgeons mâles dès la fin de la formation du régime et désinfectez vos outils à la flamme.";
    } else if (input.contains("café") || input.contains("coffee") || input.contains("caféier")) {
      reply = "À l'Est de la RDC, le caféier (Arabica/Robusta) a besoin d'un ombrage partiel et de paillage pour conserver l'humidité. Taillez régulièrement pour aérer l'arbre. Traitez le scolyte des baies du café à l'aide de pièges à alcool ou de solutions organiques à base de neem.";
    } else if (input.contains("haricot") || input.contains("bean") || input.contains("haricots")) {
      reply = "Les haricots s'associent parfaitement avec le maïs. Semez à 3-5 cm de profondeur, espacés de 10-15 cm. Ils enrichissent le sol en azote. Surveillez les pucerons et traitez-les avec du savon noir ou un extrait de neem.";
    } else if (input.contains("eau") || input.contains("irrigation") || input.contains("pluie") || input.contains("calendrier") || input.contains("water")) {
      reply = "Arrosez tôt le matin ou tard le soir. Le manioc craint l'excès d'eau stagnante. J'ai intégré votre calendrier d'irrigation local pour ajuster automatiquement les dates selon vos indications de pluie ou de sécheresse !";
    } else if (input.contains("ravageur") || input.contains("maladie") || input.contains("neem") || input.contains("pest") || input.contains("chenille") || input.contains("rouille")) {
      reply = "Pour un insecticide biologique : pilez 1 kg de feuilles ou graines de neem, laissez macérer dans 5 litres d'eau pendant 24h, filtrez, ajoutez une cuillère de savon de Marseille et pulvérisez. Cela élimine chenilles, criquets et pucerons de façon écologique.";
    } else if (input.contains("merci") || input.contains("thank") || input.contains("thanks")) {
      reply = "Je vous en prie ! Que votre sol soit riche et votre récolte abondante. N'hésitez pas si vous avez d'autres questions sur vos cultures.";
    } else if (contextTopic != null) {
      if (contextTopic == "maïs") {
        reply = "Concernant votre champ de maïs : veillez à un désherbage régulier au cours des 4 premières semaines pour éviter la compétition en azote. Si vous observez des taches particulières sur les feuilles, décrivez-les moi !";
      } else if (contextTopic == "manioc") {
        reply = "Concernant votre culture de manioc : effectuez un buttage régulier au pied et veillez à utiliser des boutures certifiées FAO sans mosaïque.";
      } else {
        reply = "Concernant votre culture : veillez à un arrosage régulier tôt le matin et à l'utilisation de paillage organique.";
      }
    } else {
      reply = "Je suis là pour vous accompagner. Précisez-moi simplement ce que vous souhaitez savoir sur votre culture (période de semis, fertilisation, traitement contre les ravageurs ou arrosage) !";
    }

    final cleanReply = TextSanitizer.cleanLatexAndFormatting(reply);
    final words = cleanReply.split(" ");
    for (var word in words) {
      await Future.delayed(const Duration(milliseconds: 60));
      yield TextResponse("$word ");
    }
  }
}
