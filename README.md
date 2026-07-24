# 🌾 Gemmea : Agronome IA 100% hors ligne pour les agriculteurs de l'Est de la RDC et de l'Afrique de l'Est

**Gemmea** (contraction de *Gemma* et *Mmea* – "plante" en swahili) est *un assistant mobile minimaliste, conçu pour autonomiser les agriculteurs des communautés rurales à faible connectivité de l'Est de la République Démocratique du Congo (RDC) et de l'Afrique de l'Est (Rwanda, Burundi, Ouganda, Tanzanie).* Conçue entièrement selon les principes de la **Clean Architecture**, l'application s'exécute à **100% hors ligne** sur l'appareil — en utilisant le modèle de pointe de Google **Gemma 2B IT (LiteRT-LM)** comme moteur d'intelligence dynamique et **SQLite** pour une persistance des données d'une fiabilité maximale.

---

## 🎯 La mission et le défi Gemma

Plus de 60% des terres agricoles de l'Est de la RDC souffrent d'une connectivité internet limitée ou complètement inexistante. Les agriculteurs sont fréquemment confrontés à des maladies de cultures dévastatrices, à des cycles imprévisibles de pluies et sécheresses, ainsi qu'à la dégradation des sols, sans avoir accès à des conseils agronomiques en temps réel.

**Gemmea** résout cette fracture numérique en intégrant un modèle de langage (LLM) local et entièrement conversationnel dans un framework mobile ultra-léger.
Ce projet a été développé spécifiquement pour le défi **Build with Gemma**. Il se concentre sur l'optimisation extrême de l'**intelligence embarquée sur l'appareil (edge intelligence)** sur du matériel mobile aux ressources limitées — garantissant ainsi une expérience d'utilisation 100% sans réseau et sans fausses données (mock data).

---

## 🚀 Fichiers clés de l'architecture Gemma (Guide d'évaluation rapide)

Pour faciliter et accélérer l'évaluation et la vérification du code par les juges, nous avons cartographié les fichiers cruciaux de Gemma et de la logique métier directement ci-dessous. Vous n'avez pas besoin de chercher dans tout le dépôt :

* 🧠 **Intégration du Chat Gemma** : [chat_repository_impl.dart](lib/data/repositories/chat_repository_impl.dart)
  * *Rôle* : Gère l'initialisation native de `gemma.litertlm` via le package `flutter_gemma`. Implémente une architecture de secours intelligente (tente d'abord de charger le modèle via le **moteur GPU** avec accélération matérielle, puis bascule sur le **moteur CPU** si la mémoire RAM ou les liaisons OpenGLES sont limitées).
* 📷 **Scanner de culture multimodal hors ligne** : [diagnostic_repository_impl.dart](lib/data/repositories/diagnostic_repository_impl.dart)
  * *Rôle* : Implémente l'analyse d'images directement sur l'appareil à l'aide des liaisons du modèle multimodal **Gemma 4 E2B**. Convertit les images locales des feuilles en flux d'octets `Uint8List` bruts et exécute l'inférence hors ligne via l'API FFI `evaluateCropImage`. Respecte strictement la règle du **SANS FAUSSES DONNÉES** ; tous les résultats des diagnostics (détection de la mosaïque du manioc, de la rouille du maïs, etc.) représentent de véritables inférences du modèle hors ligne enregistrées instantanément dans notre base de données SQLite locale.
* ⚡ **Contrôleur de chat réactif** : [chat_cubit.dart](lib/presentation/bloc/chat_cubit.dart)
  * *Rôle* : Gère le flux de données de la base de données locale, décode dynamiquement les fragments de réponse du modèle reçus en continu (streaming) et coordonne l'état du chat.
* 📈 **Contrôleur des événements du tableau de bord** : [home_cubit.dart](lib/presentation/bloc/home_cubit.dart)
  * *Rôle* : Récupère l'historique agricole, gère les interrupteurs de pluie/irrigation et déclenche le cas d'utilisation d'analyse de feuilles hors ligne.
* 💾 **Moteur de persistance** : [sqlite_helper.dart](lib/data/datasources/sqlite_helper.dart)
  * *Rôle* : Gère le schéma SQL sans réseau pour les conversations de chat s, les messages, les calendriers d'irrigation et l'historique des diagnostics.
* 🖥️ **Gestionnaire d'erreurs de scan** : [main_navigation_holder.dart](lib/presentation/pages/main_navigation_holder.dart)
  * *Rôle* : Intercepte les exceptions lors de la numérisation (comme "Diagnostic Visuel Hors Ligne" ou "Mémoire insuffisante") et affiche des boîtes de dialogue de dépannage professionnelles et hautement informatives.
* 💬 **Interface utilisateur du flux IA** : [chat_page.dart](lib/presentation/pages/chat_page.dart)
  * *Rôle* : Intègre `flutter_markdown_plus` pour un affichage riche en agronomie et intègre l'animation de chargement personnalisée `ThreeDotBounce` au sein des bulles de chat actives de l'IA.

---

## 🧠 Build with Gemma : Comment fonctionne l'exécution hors ligne

Une fois l'application lancée, elle se comporte comme un nœud local intelligent. Elle s'appuie sur un pipeline à trois couches pour alimenter le contexte directement à Gemma :

```
┌─────────────────────────┐      ┌─────────────────────────┐      ┌─────────────────────────┐
│   Base de données SQL   │ ───> │ Construction Dynamique  │ ───> │   Gemma LLM sur l'App   │
│ (Irrigation, Météo,     │      │   du Contexte (Injecte  │      │  (Génère des remèdes    │
│  Historique agricole)   │      │   les infos pour l'IA)  │      │  agronomiq. localisés)  │
└─────────────────────────┘      └─────────────────────────┘      └─────────────────────────┘
```

1. **Système d'injection de contexte enrichi** :
   Chaque fois qu'un agriculteur discute avec Gemmea, les cas d'utilisation interrogent automatiquement la base de données SQLite pour récupérer les derniers journaux de la ferme, les horaires d'irrigation récents et les statuts météo. Ces informations sont formatées de manière dynamique et injectées comme instructions système natives :
   ```yaml
   [Système d'Injection de Contexte]
   - Culture sélectionnée : Banane (Musa)
   - Météo récente : Interrupteur de pluie activé (Irrigation en pause)
   - Historique des diagnostics : 1 alerte active de mosaïque de manioc saine
   ```
   Gemma reçoit ce contexte de manière transparente, lui permettant de rédiger des conseils hautement localisés, pertinents et extrêmement précis en français ou en swahili.
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
  Le package `flutter_gemma` enregistrant les objets partagés natifs C/C++ de manière dynamique via FFI, tout premier lancement ou synchronisation de dépendances **nécessite une exécution complète à froid** (`flutter run` ou `flutter build apk`) plutôt qu'un simple Hot Reload. Le rechargement à chaud ne permet pas de lier de nouveaux segments de mémoire natifs et entraînera des erreurs de canal de communication.
* 📷 **Analyse de feuilles multimodale sur l'appareil** :
  Gemmea a dépassé les limites du texte pur. Il prend désormais entièrement en charge les **diagnostics de feuilles multimodaux 100% hors ligne** à l'aide de **Gemma 4 E2B**. Le module de scan convertit les images directement en tableaux d'octets (`Uint8List`) et les traite localement. Pour permettre aux évaluateurs et développeurs de tester instantanément cette intelligence multimodale embarquée sans avoir besoin d'un champ infecté en direct, nous avons intégré des **échantillons de test de feuilles à haute fidélité** (représentant la *mosaïque du manioc*, la *rouille du maïs* et une *feuille saine*) directement dans l'interface de scan, écrivant instantanément de vrais diagnostics générés hors ligne dans SQLite. Toute exception liée à un manque de RAM ou erreur de liaison native est gérée avec élégance grâce à des invites d'aide détaillées.

---

## ⚙️ Configuration étape par étape (Exécution locale)

Suivez ces étapes précises pour exécuter Gemmea sur votre machine locale et le connecter à un appareil Android physique s :

### 1. Prérequis
* **SDK Flutter** : `3.12.0` ou version supérieure installée et configurée dans votre `PATH`.
* **SDK Android** : Correctement configuré avec les outils de ligne de commande et les plateformes requises.
* **Appareil Android Physique** : Connecté via USB avec le **Débogage USB** activé dans les Options pour les développeurs. (Les émulateurs ne sont pas recommandés à moins qu'ils ne prennent pleinement en charge l'accélération matérielle OpenGL ES 3.0+).

### 2. Configuration du projet et synchronisation des dépendances
Clonez le dépôt et récupérez les packages enregistrés :
```bash
git clone https://github.com/glosings0n/gemmea.git
cd gemmea
flutter pub get
```

### 3. Génération des icônes adaptatives Android
Exécutez le constructeur d'actifs pour configurer nos magnifiques icônes adaptatives :
```bash
flutter pub run flutter_launcher_icons
```

### 4. Connexion de l'appareil et redémarrage à froid
Pour vous assurer que les bibliothèques natives MediaPipe et LiteRT-LM FFI sont correctement liées en mémoire, déclenchez une compilation complète sur votre appareil Android connecté :
```bash
# Vérifiez si votre appareil Android physique est bien détecté
flutter devices

# Déclenchez une compilation à froid (Ne pas utiliser le hot reload lors de la première exécution !)
flutter run --release
```
*(L'exécution en mode `--release` ou `--profile` est vivement recommandée, car le débogage JIT en mode `--debug` ajoute une lourde surcharge de mémoire pour le LLM local).*

---

## 🎨 Palette de couleurs et esthétique d'Afrique de l'Est

Le design visuel de l'application s'inspire du patrimoine agricole de la RDC et de l'Afrique de l'Est, combiné aux tendances de design moderne :
* **Vert Forêt Primaire (`#1B4324`) :** Inspiré des parcelles agricoles verdoyantes de l'Est de la RDC.
* **Vert Menthe Secondaire (`#2E7D32`) :** Exprime l'abondance naturelle et la vitalité des cultures.
* **Fond Blanc Cassé Organique (`#F6F8F5`) :** Procure une sensation d'épuration propre et de sérénité.
* **Jaune Accent (`#FBC02D`) :** Symbolise le rayonnement du soleil et la prospérité des récoltes.
* **Typographie s** : Liée aux polices premium **Fredoka-Bold** et **Fredoka-Regular** pour garantir un texte d'interface utilisateur arrondi, accueillant et extrêmement lisible.

---

## 📲 Téléchargement de l'APK Android

Téléchargez Gemmea directement sur votre appareil Android pour bénéficier d'une protection par IA 100% hors ligne et locale :

* 📦 **APK Générique** : [Lien de Téléchargement](https://drive.google.com/file/d/1h5R35UbUHgjUTvW5NSF8fjWTjqj93JL-/view?usp=drive_link) — Version complète compatible avec toutes les architectures d'appareils.
* ⚡ **Version Récente (64-bit)** : [Lien de Téléchargement](https://drive.google.com/file/d/1GEKgi6_bkNyXp6_-XEkmaYbzU12Yfjhw/view?usp=drive_link) — Optimisée pour les plateformes Android modernes 64-bit (`arm64-v8a`).
* 💾 **Ancienne Version (32-bit)** : [Lien de Téléchargement](https://drive.google.com/file/d/1ZOEEyyhfTf_Nykb1MguD9EGZ6ZjvU7jd/view?usp=drive_link) — Compatible avec les anciens appareils hérités 32-bit (`armeabi-v7a`).
