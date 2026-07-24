# Gemmea — Assistant agronomique IA 100% hors ligne

Développé par **Georges Byona** pour le challenge *Build with Gemma* (GDG on Campus UCB).

---

## Pourquoi j'ai créé Gemmea

Habitant et développeur en Afrique de l'Est, je constate au quotidien la réalité du terrain : dans la majeure partie de l'Est de la RDC et des zones rurales environnantes, la connexion internet est soit inexistante, soit trop coûteuse pour les petits agriculteurs. Pourtant, ce sont ces mêmes agriculteurs qui font face aux pires menaces sur leurs récoltes : la mosaïque du manioc, la rouille du maïs, les chenilles légionnaires et des saisons des pluies de plus en plus instables.

J'ai conçu **Gemmea** ("Mmea" signifie *plante* en swahili, combiné à *Gemma*) avec une idée fixe : **apporter la puissance d'une intelligence artificielle directement dans la poche de l'agriculteur, sans nécessiter la moindre connexion réseau.**

Tout tourne en local sur le téléphone : l'analyse d'image, le traitement du langage naturel, la recherche dans les guides de la FAO et la synthèse vocale.

---

## Ce que fait l'application sur le terrain

1. **Diagnostic visuel des feuilles (100% hors ligne)**
   L'agriculteur prend en photo une feuille de maïs ou de manioc. L'application identifie la maladie sur l'appareil à l'aide de Gemma 4 E2B et SQLite, sans envoyer aucune donnée sur un serveur distant.

2. **Conseils RAG ancrés dans les guides officiels de la FAO**
   Pour éviter que le modèle de langage n'invente des remèdes inutiles ou dangereux, j'ai intégré une base de connaissances locale contenant les fiches techniques officielles de la FAO et de l'IITA (Pour être proche de la réalité de la région). Chaque réponse fournie par Gemma est appuyée par des citations et des remèdes biologiques accessibles localement (ex: cendre de bois, eau de neem, variétés résistantes).

3. **Interactivité vocale pour l'accessibilité**
   Dans nos villages, tous les agriculteurs ne lisent pas facilement le français ou le swahili sur un écran. J'ai ajouté la possibilité de poser sa question à voix haute et d'écouter les réponses lues par la synthèse vocale du téléphone.

4. **Rapports PDF et suivi de l'exploitation**
   L'application génère des fiches de suivi au format PDF sans aucun accès réseau, permettant d'imprimer ou d'échanger des rapports de santé des cultures avec les agronomes de terrain ou les coopératives.

---

## Structure du code & Fichiers clés pour l'évaluation

Si vous évaluez mon projet pour le concours, voici les fichiers principaux où j'ai implémenté la logique Gemma et la Clean Architecture :

* 🧠 **Moteur Chat Gemma (LiteRT-LM)** : [`lib/data/repositories/chat_repository_impl.dart`](lib/data/repositories/chat_repository_impl.dart)
  Gère l'initialisation du modèle `gemma.litertlm`. J'ai mis en place un système de secours : le téléphone tente d'abord d'utiliser l'accélération GPU (shaders OpenGLES), et bascule sur le moteur CPU si le matériel est plus limité.

* 📚 **Ancrage RAG & Base FAO** : [`lib/data/repositories/fao_rag_repository_impl.dart`](lib/data/repositories/fao_rag_repository_impl.dart)
  Recherche les recommandations officielles dans la base SQLite locale et construit le prompt système injecté à Gemma pour éliminer les hallucinations.

* 📷 **Analyse Multimodale des Feuilles** : [`lib/data/repositories/diagnostic_repository_impl.dart`](lib/data/repositories/diagnostic_repository_impl.dart)
  Traite l'image de la feuille sous forme de flux d'octets `Uint8List` et exécute l'inférence avec Gemma 4 E2B.

* 🎙️ **Services Vocaux (STT / TTS)** : [`lib/core/services/voice_service.dart`](lib/core/services/voice_service.dart)
  Gère la reconnaissance vocale et la synthèse vocale hors ligne.

* 📄 **Génération de Rapports PDF** : [`lib/core/services/pdf_report_service.dart`](lib/core/services/pdf_report_service.dart)
  Compile l'état sanitaire des champs et le calendrier d'irrigation en document PDF.

* 💾 **Base de Données Locale SQLite** : [`lib/data/datasources/sqlite_helper.dart`](lib/data/datasources/sqlite_helper.dart)
  Schéma de la base locale pour les discussions, la recherche FTS RAG FAO et l'historique de santé des plantes.

---

## Remarques techniques & Test sur appareil

* **Plateforme de développement** : J'ai développé et compilé l'application sur Windows pour des appareils physiques Android (arm64 et armeabi). Je n'ai pas pu tester la version iOS faute de matériel Mac sous la main.
* **Mémoire RAM recommandée** : Pour exécuter Gemma 2B IT de façon fluide en local, un téléphone Android disposant de **4 Go de RAM** offre la meilleure expérience. Sur les téléphones ayant moins de RAM, il est conseillé de fermer les applications en arrière-plan.
* **Redémarrage à froid** : Les liaisons natives FFI de MediaPipe/LiteRT nécessitent une vraie première compilation (`flutter run --release` ou installation d'APK). Un simple Hot Reload ne réassocie pas les bibliothèques C++ partagées en mémoire.

---

## Comment tester le projet sur votre machine

```bash
# 1. Cloner mon dépôt
git clone https://github.com/glosings0n/gemmea.git
cd gemmea

# 2. Récupérer les dépendances Flutter
flutter pub get

# 3. Lancer l'application sur un téléphone Android connecté en USB
flutter run --release
```

---

## Liens de téléchargement APK (Builds Android)

Si vous souhaitez tester directement l'application sur votre smartphone Android :

* 📦 [APK Android Universel](https://drive.google.com/file/d/1h5R35UbUHgjUTvW5NSF8fjWTjqj93JL-/view?usp=drive_link)
* ⚡ [APK Android 64-bit (arm64-v8a)](https://drive.google.com/file/d/1GEKgi6_bkNyXp6_-XEkmaYbzU12Yfjhw/view?usp=drive_link)
* 💾 [APK Android 32-bit (armeabi-v7a)](https://drive.google.com/file/d/1ZOEEyyhfTf_Nykb1MguD9EGZ6ZjvU7jd/view?usp=drive_link)

---

*Projet conçu et développé par [Georges Byona](https://lintr.ee/glosings0n) — Bukavu, RDC.*
