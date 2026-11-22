# Juamea — Assistant agronomique & gestion agricole 100% hors ligne (`SautiLM-Nuru-Agri` + SQLite FTS5 RAG)

[![Flutter](https://img.shields.io/badge/Flutter-3.27+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![SautiLM-Nuru](https://img.shields.io/badge/SautiLM--Nuru--Agri-TFLite_INT8_1.07MB-4285F4?logo=tensorflow&logoColor=white)](https://huggingface.co/sautilm/SautiLM-Nuru-Agri)
[![SQLite RAG](https://img.shields.io/badge/SQLite-FTS5_RAG-003B57?logo=sqlite&logoColor=white)](https://www.sqlite.org/fts5.html)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Juamea** (`com.musantek.juamea`, développé par **SautiLM Research**) est une application mobile d'aide à la décision agronomique conçue pour fonctionner **100% hors ligne, sans aucune connexion internet**. Son nom réunit **"Jua"** (*soleil / savoir* en kiswahili, gamme mobile `SautiLM-Jua`) et **"Mmea"** (*plante / culture* en kiswahili, parlée en RDC et en Afrique de l'Est).

L'application associe une architecture **collaborative à 2 passes** (**`SautiLM-Nuru-Agri`** `1.074 Mo` en LiteRT/TFLite INT8, mesuré à **`49.73 ms/image`** et **`110 ms`** E2E sur **Google Pixel 7**) exécutée localement sur le téléphone avec une **base de données SQLite FTS5/FTS4** ([`gemmea_eac_agri.sqlite`](assets/data/gemmea_eac_agri.sqlite), `2 369` fiches compilées depuis de vrais manuels terrain open-access CGIAR / IITA / CIMMYT / PABRA / TARI / KALRO / INERA / RAB / ISABU couvrant `CD, UG, RW, BI, KE, TZ`, zéro contenu Wikipedia). Par défaut en production, `evaluateCropImage()` rend la **fiche agronomique déterministe vérifiée** (`buildDeterministicAgronomyReport`) directement depuis SQLite afin d'éliminer toute hallucination de pesticide ou de maladie.

---

## Origine & Impact Terrain

Développée à Bukavu (Sud-Kivu, Est de la République Démocratique du Congo), **Juamea** répond au manque d'accès internet fiable en zone rurale face aux menaces phytosanitaires majeures d'Afrique de l'Est et des Grands Lacs :
* **Mosaïque du Manioc** (*CMD*) & **Strie Brune** (*CBSD*)
* **Rouille Commune du Maïs** (*Puccinia sorghi*) & **Chenille Légionnaire d'Automne** (*FAW*)
* **Cercosporiose Noire du Bananier** (*Black Sigatoka*) & **Flétrissement Bactérien du Bananier** (*BXW*)
* **Tache Angulaire du Haricot** (*Pseudocercospora griseola*) & **Mildiou de la Tomate** (*Phytophthora infestans*)

---

## Architecture Technique : `SautiLM-Nuru-Agri` + SQLite FTS5 RAG + Flutter

```
[ 📱 Utilisateur / Agriculteur au champ ]
        │
        ├── 1. Photo de Feuille (Triage Pass-1 SautiLM-Nuru-Agri TFLite INT8, 1.074 Mo)
        │      └─> Rejet immédiat si `non_plant` ou confiance < 55 %
        ▼
┌─────────────────────────────────────────────────────────────┐
│ 🔎 2. MOTEUR RAG LOCAL (SQLite FTS5 — gemmea_eac_agri)      │
│ - Recherche plein texte pondérée dans les manuels CGIAR /   │
│   IITA / CIMMYT / PABRA / TARI / KALRO / INERA / RAB / ISABU│
│ - Extraits vérifiés : symptômes, remèdes bio & calendrier   │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼ 3. Fiche Déterministe ou Synthèse Contrainte
┌─────────────────────────────────────────────────────────────┐
│ 🧠 3. SYNTHÈSE ANCRÉE & MOTEUR LOCAL (LiteRT-LM)            │
│ - `buildDeterministicAgronomyReport` (zéro hallucination)   │
│ - GemmaEngineManager (verrouillage mémoire & sessions)      │
│ - Assistant Chat Conversationnel (5 derniers messages)      │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼ 4. Réponse Ancrée & Directe
┌─────────────────────────────────────────────────────────────┐
│ 📊 4. INTERFACE FLUTTER & RAPPORTS                          │
│ - Diagnostic visuel structuré & Recettes Biologiques        │
│ - Synthèse Vocale (TTS) & Rapports de santé PDF             │
└─────────────────────────────────────────────────────────────┘
```

### 1. Le Moteur RAG Local (SQLite FTS5)
* **Base de connaissances FTS5** : Manuels agronomiques open-access CGIAR / IITA / CIMMYT / PABRA / NARS indexés localement ([`sqlite_helper.dart`](lib/data/datasources/sqlite_helper.dart)) dans [`gemmea_eac_agri.sqlite`](assets/data/gemmea_eac_agri.sqlite) (**zéro Wikipedia**).
* **Ancrage strict & repli déterministe** : Pour chaque scan ou question, les passages factuels vérifiés sont injectés dans le prompt ou rendus directement via `GemmaLocalSourceImpl.buildDeterministicAgronomyReport()` afin d'interdire toute invention de pesticide ou de maladie.
* **Calendrier Régional 6 Pays EAC/RDC** : `CD` (INERA), `UG` (NARO), `RW` (RAB), `BI` (ISABU), `KE` (KALRO), `TZ` (TARI).

### 2. Exécution Collaborative sur l'Appareil (`SautiLM-Nuru-Agri` + `LiteRT-LM`)
* **Pass-1 Vision TFLite Natif (`SautiLM-Nuru-Agri`)** : MobileNetV3-Small quantifié INT8 (`1.074 Mo`, pont natif Kotlin [`NuruVisionInterpreter.kt`](android/app/src/main/kotlin/com/musantek/juamea/NuruVisionInterpreter.kt)), entraîné sur `4 032` vraies photos agricoles (`0` image synthétique, `92.06 %` val acc, `92.31 %` Macro-F1, `87.5 %` précision quantifiée INT8 réelle).
* **Court-circuit immédiat (`non_plant` F1 = `1.000` en validation interne ; `59.1 %` brut / `82.0 %` sélectif en OOD sauvage)** : Rejet immédiat avant toute requête RAG/LLM si l'objet photographié n'est pas un végétal ou si la confiance est `< 0.55`.
* **Gestionnaire Mémoire (`GemmaEngineManager`)** : Verrou d'exécution thread-safe ([`gemma_engine_manager.dart`](lib/core/services/gemma_engine_manager.dart)) sur `flutter_edge_ai` (**LiteRT-LM**).

---

## Structure du Code & Fichiers Clés

* **Pont Natif Vision TFLite (`SautiLM-Nuru-Agri`)** : [`android/app/src/main/kotlin/com/musantek/juamea/NuruVisionInterpreter.kt`](android/app/src/main/kotlin/com/musantek/juamea/NuruVisionInterpreter.kt)
* **Moteur et Verrou d'Exécution LiteRT-LM** : [`lib/core/services/gemma_engine_manager.dart`](lib/core/services/gemma_engine_manager.dart)
* **Base de Données & Moteur RAG SQLite** : [`lib/data/datasources/sqlite_helper.dart`](lib/data/datasources/sqlite_helper.dart)
* **Pipeline Collaboratif Pass-1 -> RAG -> Pass-2** : [`lib/data/datasources/gemma_local_source.dart`](lib/data/datasources/gemma_local_source.dart)
* **Dépôt du Chat & Infiltration RAG** : [`lib/data/repositories/chat_repository_impl.dart`](lib/data/repositories/chat_repository_impl.dart)
* **Service de Génération de Rapports PDF** : [`lib/core/services/pdf_report_service.dart`](lib/core/services/pdf_report_service.dart)
* **Logique Métier BLoC/Cubit** : [`lib/presentation/bloc/`](lib/presentation/bloc/)

---

## Comment exécuter le projet localement

### Prérequis
1. **Flutter SDK** (v3.27.0 ou supérieure).
2. **Android SDK** (Android 10 / API 29+ recommandé, smartphone avec au moins 4 Go de RAM).
3. **Artefacts hors ligne** :
   * [`assets/models/sautilm-nuru-agri.tflite`](assets/models/sautilm-nuru-agri.tflite) (`1.074 Mo`) et [`assets/data/gemmea_eac_agri.sqlite`](assets/data/gemmea_eac_agri.sqlite) embarqués directement.
   * Modèle texte LiteRT-LM optionnel (`sautilm-jua-agri.litertlm` `283.48 Mo` en synthèse contrainte uniquement, ou tier `Kuu 1B` INT4 `<= 650 Mo`).

```bash
git clone https://github.com/musantekk/juamea.git
cd juamea
flutter pub get
flutter test
flutter run --release
```

---

## Limitations Scientifiques & Transparence (Audit Terrain v5.1)

1. **Benchmarks OOD *cross-dataset* (`467` photos terrain indépendantes)** : Si `SautiLM-Nuru-Agri v2` atteint `92.31 %` Macro-F1 sur sa validation multi-sources (`4 032` photos), l'évaluation aveugle hors-distribution sur `227` photos *PlantDoc test* + Wikimedia (`467` photos au total) mesure **`61.7 %`** brut et **`80.3 %`** sélectif (`conf >= 0.55`, `coverage 67.4 %`), avec un *domain shift* documenté sur `tomato_blight` (`14.1 %`), `banana_sigatoka` (`20.0 %`) et `non_plant` sauvage (`59.1 %`). Un ré-entraînement `v3` multi-domaines (`PlantDoc + FGVC + field crops`) et une campagne de validation terrain en RDC/EAC sont requis avant toute certification phytosanitaire officielle.
2. **Rôle strict des petits LLM `270M`** : Les modèles `270M` ne prescrivent jamais de traitements libres hors extraits vérifiés ; **Juamea** rend par défaut la fiche déterministe `buildDeterministicAgronomyReport()` ancrée sur `gemmea_eac_agri.sqlite` (CGIAR/IITA/NARS, indexation native FTS5/FTS4 Android).
3. **Confidentialité & Souveraineté** : **0 % de requêtes réseau** en usage terrain ; toutes les photos, analyses et bilans PDF restent localement sur le téléphone.

---

### À propos de l'Auteur

* **Développeur :** Georges Byona (SautiLM Research)
* **Bio :** [https://linktr.ee/glosings0n](https://linktr.ee/glosings0n)
* **Vidéo démo :** [https://youtu.be/dPMXgOpZFEc](https://youtu.be/dPMXgOpZFEc)
