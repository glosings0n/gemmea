# 🌿 Gemmea — Assistant agronomique et de gestion agricole 100% hors ligne avec Google Gemma 4

**Gemmea** est une application mobile d'aide à la décision agronomique conçue pour fonctionner **100% hors ligne, sans aucune connexion internet**. Son nom vient de la fusion de **"Mmea"** (*plante* ou *culture* en swahili, la langue parlée dans l'Est de la RDC et en Afrique de l'Est) et de **Gemma** (le modèle d'intelligence artificielle ouvert de Google).

L'application combine la vision multimodale et le traitement de texte de **Google Gemma 4** (`gemma-4-E2B-it.litertlm`) exécuté directement sur le téléphone avec une base de données agronomique locale (fiches officielles de la FAO et de l'IITA). Elle permet de diagnostiquer les maladies des cultures par photo, de proposer des remèdes biologiques gratuits et de générer des bilans sanitaires au format PDF.

---

## Pourquoi j'ai créé Gemmea

Habitant et développeur à Bukavu dans l'Est de la République Démocratique du Congo, je constate au quotidien la réalité du terrain : dans la majeure partie de notre région et des zones rurales environnantes, la connexion internet est soit inexistante, soit trop coûteuse pour les agriculteurs et les petites coopératives.

Pourtant, ce sont ces mêmes agriculteurs qui font face aux pires menaces sur leurs récoltes : la mosaïque du manioc, la rouille du maïs, les chenilles légionnaires et les maladies du bananier.

J'ai donc conçu **Gemmea** avec une idée fixe : **apporter la puissance de l'intelligence artificielle de Google Gemma 4 directement sur le téléphone de l'agriculteur, sans nécessiter la moindre connexion réseau.**

---

## Ce que fait l'application sur le terrain

1. **Diagnostic de la feuille par photo (100% hors ligne)**  
   L'utilisateur prend en photo une feuille de sa culture. L'application analyse directement l'image sur l'appareil à l'aide de Gemma 4 pour identifier la maladie.

2. **Conseils ancrés dans les guides officiels de la FAO**  
   Pour éviter que l'IA ne donne des conseils inexacts, j'ai intégré une base de données SQLite locale contenant les fiches de la FAO et de l'IITA. L'application recherche les informations pertinentes avant de répondre.

3. **Recettes biologiques et économiques**  
   L'application propose des remèdes naturels réalisables sans frais avec ce qu'on trouve au village : extrait de feuilles de neem, cendre de bois, ou compost local.

4. **Synthèse vocale pour la facilité d'écoute**  
   L'utilisateur peut poser sa question oralement et écouter la réponse lue par la synthèse vocale du téléphone.

5. **Rapports de suivi au format PDF**  
   L'application génère des fiches de bilan sanitaire en PDF directement sur le téléphone pour aider les chefs d'exploitations et responsables de coopératives à suivre leurs champs.

---

## Organisation du code et fichiers clés

Si vous évaluez mon projet, voici les fichiers principaux où j'ai implémenté la logique et l'architecture Flutter :

* 🧠 **Moteur et verrous Gemma 4 (LiteRT-LM)** : [`lib/core/services/gemma_engine_manager.dart`](lib/core/services/gemma_engine_manager.dart)  
  Gère l'initialisation du modèle et la sécurité d'exécution pour éviter les blocages de mémoire.
* 📚 **Base de données et recherche FAO (SQLite FTS5)** : [`lib/data/datasources/sqlite_helper.dart`](lib/data/datasources/sqlite_helper.dart)  
  Recherche plein texte dans les guides agronomiques stockés sur le téléphone.
* 💬 **Gestion du Chat et du RAG** : [`lib/data/repositories/chat_repository_impl.dart`](lib/data/repositories/chat_repository_impl.dart)  
  Injecte le contexte officiel de la FAO dans les consignes du modèle Gemma.
* 📷 **Analyse de la photo avec Gemma VLM** : [`lib/data/datasources/gemma_local_source.dart`](lib/data/datasources/gemma_local_source.dart)  
  Traite l'image capturée avec le modèle multimodal Gemma 4.
* 📄 **Génération de rapports PDF** : [`lib/core/services/pdf_report_service.dart`](lib/core/services/pdf_report_service.dart)  
  Compile le bilan sanitaire des champs en document PDF.

---

## Comment tester le projet sur votre téléphone

```bash
# 1. Cloner le dépôt
git clone https://github.com/glosings0n/gemmea.git
cd gemmea

# 2. Récupérer les dépendances Flutter
flutter pub get

# 3. Lancer l'application sur un téléphone Android connecté en USB
flutter run --release
```

---

## Liens de téléchargement direct des APK Android

* 📦 [APK Android Universel (Google Drive)](https://drive.google.com/file/d/1h5R35UbUHgjUTvW5NSF8fjWTjqj93JL-/view?usp=drive_link)
* ⚡ [APK Android 64-bit (arm64-v8a)](https://drive.google.com/file/d/1GEKgi6_bkNyXp6_-XEkmaYbzU12Yfjhw/view?usp=drive_link)

---

### À propos de l'auteur
* **Développeur :** Georges Byona  
* **Localisation :** Bukavu, Sud-Kivu, République Démocratique du Congo  
* **Événement :** Concours *Build with Gemma 2026* (GDG on Campus UCB)  
* **Dépôt GitHub :** [https://github.com/glosings0n/gemmea](https://github.com/glosings0n/gemmea)
