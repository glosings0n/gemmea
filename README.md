# 🌾 Gemmea : Agronome IA 100% hors ligne pour les agriculteurs de l'Est de la RDC et de l'Afrique de l'Est

**Gemmea** (contraction de *Gemma* et *Mmea* – "plante" en swahili) est *un assistant mobile agronomique de pointe, conçu pour autonomiser les agriculteurs des communautés rurales à faible connectivité de l'Est de la République Démocratique du Congo (RDC) et de l'Afrique de l'Est (Rwanda, Burundi, Ouganda, Tanzanie).* Conçue entièrement selon les principes de la **Clean Architecture**, l'application s'exécute à **100% hors ligne** sur l'appareil — en utilisant le modèle de pointe de Google **Gemma 2B IT (LiteRT-LM)** comme moteur d'intelligence dynamique, la base de données de connaissances **FAO & IITA RAG** et **SQLite** pour une persistance des données d'une fiabilité maximale.

---

## 🎯 La mission et le défi Gemma

Plus de 60% des terres agricoles de l'Est de la RDC souffrent d'une connectivité internet limitée ou complètement inexistante. Les agriculteurs sont fréquemment confrontés à des maladies de cultures dévastatrices, à des cycles imprévisibles de pluies et sécheresses, ainsi qu'à la dégradation des sols, sans avoir accès à des conseils agronomiques en temps réel.

**Gemmea** résout cette fracture numérique en intégrant un modèle de langage (LLM) local et entièrement conversationnel dans un framework mobile ultra-léger.
Ce projet a été développé spécifiquement pour le défi **Build with Gemma**. Il se concentre sur l'optimisation extrême de l'**intelligence embarquée sur l'appareil (edge intelligence)** sur du matériel mobile aux ressources limitées — garantissant ainsi une expérience d'utilisation 100% sans réseau, ancrée dans la littérature scientifique officielle FAO et sans fausses données (mock data).

---

## 🚀 Fichiers clés de l'architecture Gemma (Guide d'évaluation rapide)

Pour faciliter et accélérer l'évaluation et la vérification du code par les juges du concours **Build with Gemma**, nous avons cartographié les fichiers cruciaux de Gemma et de la logique métier directement ci-dessous :

* 📚 **Ancrage RAG FAO & Modèle de Connaissances Hors Ligne** : [fao_rag_repository_impl.dart](lib/data/repositories/fao_rag_repository_impl.dart)
  * *Rôle* : Effectue des recherches par mots-clés/météo dans la base SQLite locale des guides officiels FAO/IITA (Mosaïque du Manioc, Rouille du Maïs, Flétrissement du Bananier) et injecte des citations officielles et des conseils de Chain-of-Thought directement dans le système prompt de Gemma pour éliminer toute hallucination.
* 📄 **Service de Génération et Exportation de Rapports PDF** : [pdf_report_service.dart](lib/core/services/pdf_report_service.dart)
  * *Rôle* : Compile l'historique des diagnostics sanitaires, les prédictions d'irrigation et les recommandations FAO en un document PDF professionnel généré 100% hors ligne, prêt à être imprimé ou partagé avec des coopératives agricoles et des bailleurs de fonds.
* 🎙️ **Accessibilité Vocale & Synthèse Vocale (ASR / TTS)** : [voice_service.dart](lib/core/services/voice_service.dart)
  * *Rôle* : Permet la dictée vocale des questions des agriculteurs (Speech-to-Text) et la lecture audio à voix haute des remèdes agronomiques de Gemma (Text-to-Speech), garantissant une accessibilité maximale aux agriculteurs peu alphabétisés.
* 🧠 **Moteur d'Inférence Chat Gemma** : [chat_repository_impl.dart](lib/data/repositories/chat_repository_impl.dart)
  * *Rôle* : Gère l'initialisation native de `gemma.litertlm` via le package `flutter_gemma`. Implémente une architecture de secours intelligente (tente d'abord de charger le modèle via le **moteur GPU** avec accélération matérielle, puis bascule sur le **moteur CPU** si la mémoire RAM ou les liaisons OpenGLES sont limitées).
* 📷 **Scanner de culture multimodal hors ligne** : [diagnostic_repository_impl.dart](lib/data/repositories/diagnostic_repository_impl.dart)
  * *Rôle* : Implémente l'analyse d'images directement sur l'appareil à l'aide des liaisons du modèle multimodal **Gemma 4 E2B**. Convertit les images locales des feuilles en flux d'octets `Uint8List` bruts et exécute l'inférence hors ligne via l'API FFI `evaluateCropImage`.
* ⚡ **Contrôleur de chat réactif & Interface RAG** : [chat_cubit.dart](lib/presentation/bloc/chat_cubit.dart) & [chat_page.dart](lib/presentation/pages/chat_page.dart)
  * *Rôle* : Gère le flux de données de la base de données locale, intègre les boutons vocaux (Micro et Haut-Parleur), affiche les badges d'ancrage "Ancré FAO RAG" et décode dynamiquement les fragments de réponse du modèle reçus en continu.
* 📈 **Calculateur de ROI & Historique des Diagnostics** : [diagnostics_history_page.dart](lib/presentation/pages/diagnostics_history_page.dart)
  * *Rôle* : Présente les pertes financières estimées par hectare et les gains économiques éco-responsables générés par l'application des traitements FAO.
* 💾 **Moteur de persistance & SQLite RAG** : [sqlite_helper.dart](lib/data/datasources/sqlite_helper.dart)
  * *Rôle* : Gère le schéma SQL sans réseau pour les conversations de chat, le calendrier d'irrigation, la base de connaissances FAO et l'historique des diagnostics.

---

## 🧠 Build with Gemma : Comment fonctionne l'exécution hors ligne

Une fois l'application lancée, elle se comporte comme un nœud local intelligent. Elle s'appuie sur un pipeline à trois couches pour alimenter le contexte directement à Gemma :

```
┌─────────────────────────┐      ┌─────────────────────────┐      ┌─────────────────────────┐
│  Base SQLite & FAO RAG  │ ───> │ Construction Dynamique  │ ───> │   Gemma LLM sur l'App   │
│  (Extraits officiels,   │      │  du Prompt Ancré (RAG,  │      │  (Génère des remèdes    │
│  Météo & Irrigation)    │      │  Citations FAO, CoT)    │      │  agronomiq. localisés)  │
└─────────────────────────┘      └─────────────────────────┘      └─────────────────────────┘
```

1. **Système d'injection de contexte enrichi (RAG FAO)** :
   Chaque fois qu'un agriculteur discute avec Gemmea, les cas d'utilisation interrogent automatiquement la base de données SQLite pour récupérer les extraits agronomiques officiels de la FAO, les horaires d'irrigation récents et les statuts météo. Ces informations sont formatées de manière dynamique et injectées comme instructions système natives :
   ```yaml
   [RAG FAO & Contexte Agricole]
   - Extrait FAO : Mosaïque du Manioc (CMD), perte estimée de 40 à 70%
   - Source Officielle : Guide FAO de Protection des Cultures en Afrique de l'Est (2024)
   - Remède Écologique : Boutures résistantes TME 419, extrait d'eau de neem ou cendre de bois
   - Statut Météo : Irrigation ajustée selon le calendrier des pluies
   ```
   Gemma reçoit ce contexte de manière transparente, lui permettant de rédiger des conseils hautement localisés, pertinents et extrêmement précis avec citations.

2. **Architecture FFI à double moteur** :
   Pour éviter d'alourdir l'application, nous utilisons les liaisons FFI natives du moteur d'inférence LLM de LiteRT. Nous essayons d'abord de charger le modèle via le **moteur GPU** mobile (utilisant les shaders OpenGLES) pour accélérer le traitement initial. En cas d'incompatibilité matérielle ou de surcharge mémoire, l'application bascule automatiquement et de manière fluide sur le **moteur CPU**, garantissant un fonctionnement optimal sur tous les types d'appareils Android.

---

## ⚠️ Limites connues et conditions de test

En tant que projet soumis avec une totale honnêteté intellectuelle et rigueur technique, nous précisons explicitement les contraintes matérielles et logicielles sous lesquelles Gemmea a été développé :

* 💻 **Compilé strictement sur Windows (Android uniquement)** :
  Notre environnement de développement était limité à **Windows**. La compilation native d'iOS nécessitant macOS et Xcode pour lier les frameworks binaires statiques de MediaPipe, **Gemmea n'a pas été compilé ni testé sur iOS**. L'ensemble de la base de code, des liaisons FFI et des bases de données locales a été compilé, profilé et vérifié exclusivement sur du **matériel physique Android**.
* 🧠 **Consommation de mémoire RAM locale** :
  L'exécution locale d'un modèle complet Gemma 2B de 2 Go optimisé pour les instructions nécessite une quantité de mémoire système significative.
  * Les appareils avec **4 Go de RAM ou plus** exécutent le modèle de manière extrêmement fluide.
  * Les appareils bas de gamme avec **moins de 4 Go de RAM** peuvent rencontrer des arrêts de processus dus à une insuffisance de mémoire (OOM). Nous recommandons de fermer les applications en arrière-plan avant de démarrer le modèle.
* 🔄 **Liaison des bibliothèques natives (Besoin d'un redémarrage à froid)** :
  Le package `flutter_gemma` enregistrant les objets partagés natifs C/C++ de manière dynamique via FFI, tout premier lancement ou synchronisation de dépendances **nécessite une exécution complète à froid** (`flutter run` ou `flutter build apk`) plutôt qu'un simple Hot Reload.

---

## ⚙️ Configuration étape par étape (Exécution locale)

Suivez ces étapes précises pour exécuter Gemmea sur votre machine locale et le connecter à un appareil Android physique :

### 1. Prérequis
* **SDK Flutter** : `3.12.0` ou version supérieure installée et configurée dans votre `PATH`.
* **SDK Android** : Correctement configuré avec les outils de ligne de commande et les plateformes requises.
* **Appareil Android Physique** : Connecté via USB avec le **Débogage USB** activé dans les Options pour les développeurs.

### 2. Configuration du projet et synchronisation des dépendances
Clonez le dépôt et récupérez les packages enregistrés :
```bash
git clone https://github.com/glosings0n/gemmea.git
cd gemmea
flutter pub get
```

### 3. Exécution et Test
```bash
flutter run --release
```

---

## 🎨 Palette de couleurs et esthétique d'Afrique de l'Est

Le design visuel de l'application s'inspire du patrimoine agricole de la RDC et de l'Afrique de l'Est, combiné aux tendances de design moderne :
* **Vert Forêt Primaire (`#1B4324`) :** Inspiré des parcelles agricole verdoyantes de l'Est de la RDC.
* **Vert Menthe Secondaire (`#2E7D32`) :** Exprime l'abondance naturelle et la vitalité des cultures.
* **Fond Blanc Cassé Organique (`#F6F8F5`) :** Procure une sensation d'épuration propre et de sérénité.
* **Jaune Accent (`#FBC02D`) :** Symbolise le rayonnement du soleil et la prospérité des récoltes.
* **Typographie** : Liée aux polices premium **Fredoka-Bold** et **Fredoka-Regular** pour garantir un texte d'interface utilisateur arrondi, accueillant et extrêmement lisible.

---

## 📲 Téléchargement de l'APK Android

Téléchargez Gemmea directement sur votre appareil Android pour bénéficier d'une protection par IA 100% hors ligne et locale :

* 📦 **APK Générique** : [Lien de Téléchargement](https://drive.google.com/file/d/1h5R35UbUHgjUTvW5NSF8fjWTjqj93JL-/view?usp=drive_link) — Version complète compatible avec toutes les architectures d'appareils.
* ⚡ **Version Récente (64-bit)** : [Lien de Téléchargement](https://drive.google.com/file/d/1GEKgi6_bkNyXp6_-XEkmaYbzU12Yfjhw/view?usp=drive_link) — Optimisée pour les plateformes Android modernes 64-bit (`arm64-v8a`).
* 💾 **Ancienne Version (32-bit)** : [Lien de Téléchargement](https://drive.google.com/file/d/1ZOEEyyhfTf_Nykb1MguD9EGZ6ZjvU7jd/view?usp=drive_link) — Compatible avec les anciens appareils hérités 32-bit (`armeabi-v7a`).
