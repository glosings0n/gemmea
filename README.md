# 🌿 Gemmea — Assistant agronomique & gestion agricole 100% hors ligne avec Google Gemma 4

[![Flutter](https://img.shields.io/badge/Flutter-3.27+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Google Gemma 4](https://img.shields.io/badge/Google_Gemma_4-LiteRT--LM-4285F4?logo=google&logoColor=white)](https://ai.google.dev/gemma)
[![SQLite RAG](https://img.shields.io/badge/SQLite-FTS5_RAG-003B57?logo=sqlite&logoColor=white)](https://www.sqlite.org/fts5.html)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Gemmea** est une application mobile d'aide à la décision agronomique conçue pour fonctionner **100% hors ligne, sans aucune connexion internet**. Son nom réunit **"Mmea"** (*plante* ou *culture* en swahili, langue parlée en RDC et en Afrique de l'Est) et **Gemma** (le modèle d'intelligence artificielle ouvert de Google).

L'application associe la vision multimodale et la génération de texte de **Google Gemma 4** (`gemma-4-E2B-it.litertlm`) exécuté localement sur le téléphone avec une architecture **RAG (Retrieval-Augmented Generation) ancrée sur une base de données SQLite FTS5** contenant les guides agronomiques officiels de la **FAO** et de l'**IITA**.

---

## 💡 Genesis & Impact Terrain

À Bukavu, dans l'Est de la RDC (Sud-Kivu), comme dans la majorité des régions rurales d'Afrique subsaharienne, l'accès à internet est souvent inexistant, instable ou financièrement inabordable pour les petits agriculteurs et les coopératives locales.

Pourtant, les menaces phytosanitaires sur les cultures vivrières y sont majeures :
* **Mosaïque du Manioc** (*Cassava Mosaic Virus*) & **Strie Brune**
* **Rouille du Maïs** (*Puccinia sorghi*) & **Chenille Légionnaire d'Automne**
* **Flétrissement Bactérien du Bananier** (*BXW*)

**Gemmea** a été développée pour répondre à ce défi : apporter la puissance de l'IA générative directement dans le creux de la main de l'agriculteur au champ, **avec zéro dépendance au réseau mobile ou cloud.**

---

## 🏗️ Architecture Technique : Gemma 4 + RAG SQLite + Flutter

```
[ 📱 Utilisateur / Agriculteur au champ ]
        │
        ├── 1. Photo de Feuille OU Question Chat
        ▼
┌─────────────────────────────────────────────────────────────┐
│ 🔎 1. MOTEUR RAG LOCAL (SQLite FTS5)                       │
│ - Recherche plein texte pondérée dans les guides FAO / IITA │
│ - Extraits officiels : symptômes, remèdes bio & calendrier  │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼ 2. Injection du Contexte Factuel
┌─────────────────────────────────────────────────────────────┐
│ 🧠 2. MOTEUR GEMMA 4 LOCAL (LiteRT-LM / CPU Thread)          │
│ - GemmaEngineManager (verrouillage mémoire & sessions)     │
│ - Multimodal VLM (Analyse d'image - 4096 tokens)             │
│ - Assistant Chat Conversational (Séquentiel - 2048 tokens)  │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼ 3. Réponse Ancrée & Directe
┌─────────────────────────────────────────────────────────────┐
│ 📊 3. INTERFACE FLUTTER & RAPPORTS                          │
│ - Diagnostic visuel structuré & Recettes Biologiques        │
│ - Synthèse Vocale (TTS) & Rapports de santé PDF             │
└─────────────────────────────────────────────────────────────┘
```

### 1. Le Moteur RAG Local (SQLite FTS5)
Afin d'éviter tout risque d'hallucination agronomique et de fournir des conseils scientifiquement éprouvés :
* **Base de connaissances FTS5** : Fiches officielles FAO et IITA indexées localement avec recherche plein texte pondérée ([`sqlite_helper.dart`](lib/data/datasources/sqlite_helper.dart)).
* **Ancrage dynamique** : Pour chaque question technique ou scan, les passages factuels pertinents sont extraits et injectés dans le prompt système de Gemma sous forme de contraintes factuelles strictes ([`chat_repository_impl.dart`](lib/data/repositories/chat_repository_impl.dart)).
* **Calendrier Régional Intégré** : Intégration directe des saisons agricoles de l'Afrique de l'Est et des Grands Lacs (Saisons A & B, dates de semis, écartements).

### 2. Exécution de Gemma 4 sur l'Appareil
* **Package Native Binding** : Utilisation de `flutter_gemma` qui embarque le runtime **LiteRT-LM** (Google LiteRT pour LLM sur mobile).
* **Gestionnaire de Ressources Membre (`GemmaEngineManager`)** : Implémentation d'un gestionnaire de mémoire thread-safe ([`gemma_engine_manager.dart`](lib/core/services/gemma_engine_manager.dart)) avec verrou d'exécution (`_isEngineActive`) pour garantir la stabilité et éviter le surdimensionnement RAM sur smartphone.
* **Analyse Multimodale VLM (Scan de Feuille)** :
  * Traitement de l'image capturée via [`gemma_local_source.dart`](lib/data/datasources/gemma_local_source.dart) configuré à **`maxTokens: 4096`**.
  * **Court-circuit immédiat** : Si l'image n'est pas un végétal (visage, objet, etc.), Gemma stoppe l'analyse immédiatement pour renvoyer une alerte *"Feuille non détectée"* en un temps record.
  * Structure de réponse en 7 sections agronomiques officielles.
* **Assistant Chat** :
  * Fenêtre glissante conservant l'historique des **5 derniers messages**.
  * Régulation du débit à **`maxTokens: 2048`** pour des réponses réactives.
  * Directives strictes sans clauses génériques de non-responsabilité (*"Vous êtes l'expert de référence"*).

---

## 📂 Structure du Code & Fichiers Clés

Pour évaluer la qualité d'ingénierie du projet, voici les composants majeurs du dépôt :

* 🧠 **Moteur et Verrou d'Exécution Gemma 4** : [`lib/core/services/gemma_engine_manager.dart`](lib/core/services/gemma_engine_manager.dart)  
  Gestionnaire central de l'instance LiteRT-LM et isolation des sessions d'inférence.
* 📚 **Base de Données & Moteur RAG SQLite** : [`lib/data/datasources/sqlite_helper.dart`](lib/data/datasources/sqlite_helper.dart)  
  Indexation FTS5 des guides agronomiques FAO/IITA et requêtes de recherche contextuelle.
* 📷 **Source Multimodale Gemma VLM** : [`lib/data/datasources/gemma_local_source.dart`](lib/data/datasources/gemma_local_source.dart)  
  Inférence visuelle locale, validation des végétaux et prompt engineering multimodal.
* 💬 **Dépôt du Chat & Infiltration RAG** : [`lib/data/repositories/chat_repository_impl.dart`](lib/data/repositories/chat_repository_impl.dart)  
  Assemblage du RAG, règles conversationnelles régionales et gestion du flux de streaming.
* 📄 **Service de Génération de Rapports PDF** : [`lib/core/services/pdf_report_service.dart`](lib/core/services/pdf_report_service.dart)  
  Exportation hors ligne des bilans sanitaires de la ferme.
* 🎛️ **Logique Métier BLoC/Cubit** : [`lib/presentation/bloc/`](lib/presentation/bloc/)  
  Découplage propre de l'état de l'application (`ScanCubit`, `ChatCubit`, `HomeCubit`).

---

## 🛠️ Comment exécuter le projet localement

### Prérequis
1. **Flutter SDK** (v3.27.0 ou supérieure) installé et configuré.
2. **Android SDK** (Android 10 / API 29+ recommandé, téléphone physique recommandé avec au moins 4 Go de RAM).
3. **Poids du modèle** : Le fichier du modèle Gemma 4 (`gemma-4-E2B-it.litertlm`) est placé dans le dossier `assets/` de l'application ou téléchargé au premier lancement via LiteRT.

### Étapes d'Exécution

```bash
# 1. Cloner le dépôt GitHub
git clone https://github.com/glosings0n/gemmea.git
cd gemmea

# 2. Installer les dépendances Flutter
flutter pub get

# 3. Exécuter la suite de tests unitaires pour vérifier l'intégrité du projet
flutter test

# 4. Lancer l'application en mode release sur un appareil Android connecté en USB
flutter run --release
```

---

## ⚠️ Limitations Actuelles & Défis Techniques

Bien que **Gemmea** soit pleinement fonctionnelle en mode 100% hors ligne, certaines limitations liées aux contraintes actuelles ont été identifiées :

1. **Jeu de données visuel & Plante inconnue** :  
   Gemma 4 VLM est un modèle multimodal généraliste qui n'a pas encore fait l'objet d'un **fine-tuning** ciblé sur les variétés de feuilles tropicales spécifiques à notre région (ex: cultivars locaux de manioc ou patate douce). Il peut donc arriver que Gemma qualifie certaines feuilles de *"Plante inconnue"* ou de culture générique. Un affinage (*fine-tuning*) sur un dataset spécialisé est prévu.
2. **Taille du contexte & Quantification sur mobile** :  
   Pour garantir une exécution fluide sur des smartphones Android abordables (4 à 8 Go de RAM), nous utilisons la version quantifiée `gemma-4-E2B-it.litertlm`. En raison de la mémoire limitée sur mobile, il n'a pas encore été possible d'utiliser un modèle à plus large fenêtre de contexte (ex: Gemma 9B), ce qui peut parfois conduire à des réponses synthétiques ou légèrement tronquées pour les requêtes complexes.
3. **Localisation multilingue (Swahili, Lingala, Anglais)** :  
   Par manque de temps durant le hackathon, le support natif complet de plusieurs langues (**Kiswahili**, **Lingala**, **Anglais**) au niveau de l'interface et des prompts n'a pas pu être totalement achevé (l'application fonctionne actuellement en Français principal avec termes swahili intégrés).
4. **Variabilité du temps de calcul CPU** :  
   Sur les appareils d'entrée de gamme dépourvus d'accélérateur NPU, l'analyse visuelle par le CPU prend environ 5 à 10 secondes.

---

## 🚀 Perspectives & Feuille de Route (Roadmap)

* **Fine-Tuning de Gemma 4 VLM sur les cultures tropicales** : Affinage du modèle VLM sur une base de données annotée de maladies des plantes d'Afrique de l'Est (Manioc, Maïs, Bananier, Haricot) via QLoRA.
* **Support Multilingue Intégral** : Prise en charge native du Kiswahili, du Lingala et de l'Anglais pour une adoption facile par tous les agriculteurs.
* **Partage Hors Ligne entre Coopératives (Mesh/Bluetooth)** : Synchronisation des rapports sanitaires entre agriculteurs et responsables de coopératives via Bluetooth ou Wi-Fi Direct sans internet.
* **Intégration de Capteurs IoT Bluetooth** : Connexion avec des capteurs d'humidité du sol et de pH pour déclencher des alertes d'irrigation autonomes via RAG.

---

## 🔒 Confidentialité & Souveraineté des Données

* **0% de requêtes réseau** : Aucune donnée utilisateur, aucune photo, aucun message de chat ne quitte le téléphone.
* **Respect total de la vie privée** : Traitement 100% sur l'appareil (*On-Device AI*).
* **Opérationnel en zone blanche** : Fonctionne parfaitement au milieu d'un champ sans couverture réseau.

---

### 📄 Writeup Officiel Kaggle
Un document de synthèse détaillé préparé pour le concours est disponible dans le fichier [`KAGGLE_WRITEUP.md`](KAGGLE_WRITEUP.md).

---

### 👤 À propos de l'Auteur

* **Développeur :** Georges Byona  
* **Rôle :** Software Engineer  
* **Localisation :** Bukavu, Sud-Kivu, République Démocratique du Congo  
* **Événement :** Concours *Build with Gemma 2026* (GDG on Campus UCB)  
* **Bio :** [https://linktr.ee/glosings0n](https://linktr.ee/glosings0n)  
* **Dépôt GitHub :** [https://github.com/glosings0n/gemmea](https://github.com/glosings0n/gemmea)
