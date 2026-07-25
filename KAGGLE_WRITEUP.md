# Gemmea — Assistant agronomique IA 100% hors ligne pour l'Afrique de l'Est
## Synthèse Kaggle — Concours Build with Gemma 2026

---

### Résumé du Projet
**Gemmea** ("Mmea" = *plante/culture* en swahili + *Gemma*) est une application mobile d'aide à la décision agronomique fonctionnant **100% hors ligne**, construite avec **Flutter**, **Google Gemma 4 (`gemma-4-E2B-it.litertlm`)** et un moteur **RAG SQLite FTS5**.

Conçue spécifiquement pour les petits producteurs et coopératives agricoles des zones sans couverture réseau de l'Est de la RDC (Bukavu, Sud-Kivu) et d'Afrique de l'Est, Gemmea diagnostique les maladies des feuilles via une vision multimodale hors ligne, propose des remèdes biologiques ancrés dans les guides officiels FAO/IITA et gère le calendrier d'irrigation sans transmettre la moindre donnée vers le cloud.

---

### Problématique & Impact Terrain
Dans l'Est de la RDC et les zones rurales d'Afrique de l'Est, l'internet mobile est soit inexistant, soit trop onéreux pour les agriculteurs. Pourtant, leurs cultures vivrières sont menacées par des maladies dévastatrices :
* **Mosaïque du Manioc** & **Strie Brune du Manioc**
* **Rouille du Maïs** & **Chenille Légionnaire d'Automne**
* **Flétrissement Bactérien du Bananier (BXW)**

Gemmea élimine la barrière de la connectivité en exécutant Google Gemma 4 directement sur téléphone Android, rendant l'IA accessible au cœur du champ.

---

### Architecture Technique & Innovations Clés

#### 1. Intégration Multimodale VLM Gemma 4 sur Mobile
* **Runtime** : Intégration via `flutter_gemma` s'appuyant sur **Google LiteRT-LM**.
* **Sécurité Mémoire & Thread** : Utilisation de `GemmaEngineManager` avec un verrou d'exécution (`_isEngineActive`) pour garantir la stabilité sur les smartphones abordables.
* **Évaluation VLM (`maxTokens: 4096`)** : Génère un diagnostic agronomique structuré en 7 sections. Intègre un **court-circuit rapide** qui stoppe immédiatement la génération si une photo non végétale (visage, objet) est soumise.
* **Assistant Chat (`maxTokens: 2048`)** : Maintient une fenêtre glissante de 5 messages avec un prompt système ancré dans le contexte agricole d'Afrique de l'Est.

#### 2. Moteur RAG Local SQLite FTS5
Pour prévenir les hallucinations, Gemmea embarque une base de données plein texte (FTS5) contenant les guides biologiques de la FAO et de l'IITA :
* Extraction dynamique des passages factuels selon la culture et la question posée.
* Injection des remèdes bio et des dosages exacts dans le prompt système avant l'inférence.
* Calendrier agricole régional intégré (Saisons A & B, dates de semis, écartements).

---

### Limitations Actuelles & Défis Techniques

Bien que Gemmea soit totalement opérationnelle hors ligne, nous documentons en toute transparence les limitations suivantes :

1. **Dataset Visuel & Classification** :
   Gemma 4 VLM est un modèle généraliste non affiné sur les variétés de feuilles tropicales spécifiques à notre région (ex: cultivars locaux de manioc ou patate douce). Il peut donc parfois classifier certaines feuilles en *"Plante inconnue"* ou culture générique. Un fine-tuning spécialisé est prévu.
2. **Quantification Mobile & Taille du Contexte** :
   Pour garantir la fluidité sur des smartphones de 4 à 8 Go de RAM, nous utilisons la version quantifiée `gemma-4-E2B-it.litertlm`. La mémoire limitée empêche d'utiliser de plus larges fenêtres de contexte ou des modèles plus grands (ex: Gemma 9B).
3. **Localisation Multilingue (Swahili, Lingala, Anglais)** :
   Par manque de temps durant le hackathon, le support natif complet de plusieurs langues (**Kiswahili**, **Lingala**, **Anglais**) n'a pas pu être totalement achevé (interface en Français avec terminologie swahili).
4. **Temps de Calcul CPU** :
   Sur les téléphones d'entrée de gamme sans NPU, l'analyse visuelle par le CPU prend environ 5 à 10 secondes.

---

### Perspectives & Feuille de Route

1. **Fine-Tuning de Gemma 4 VLM sur les cultures tropicales** : Affinage du modèle VLM sur une base de données annotée de maladies des plantes d'Afrique de l'Est via QLoRA.
2. **Support Multilingue Intégral (Kiswahili & Lingala)** : Prise en charge native des langues locales pour l'interface et le modèle.
3. **Partage Hors Ligne entre Coopératives (Mesh/Bluetooth)** : Synchronisation des rapports sanitaires entre agriculteurs et responsables de coopératives via Bluetooth ou Wi-Fi Direct.
4. **Intégration de Capteurs IoT Bluetooth** : Connexion avec des capteurs d'humidité du sol et de pH pour déclencher des alertes d'irrigation autonomes via RAG.

---

### À propos de l'Auteur & Détails
* **Développeur :** Georges Byona
* **Rôle :** Software Engineer
* **Localisation :** Bukavu, Sud-Kivu, République Démocratique du Congo
* **Événement :** Concours *Build with Gemma 2026* (GDG on Campus UCB)
* **Bio / Linktree :** [https://linktr.ee/glosings0n](https://linktr.ee/glosings0n)
* **Dépôt GitHub :** [https://github.com/glosings0n/gemmea](https://github.com/glosings0n/gemmea)
