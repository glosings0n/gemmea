# Gemmea — 100% Offline Agronomic & Farm Management Assistant with Google Gemma 4

[![Flutter](https://img.shields.io/badge/Flutter-3.27+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Google Gemma 4](https://img.shields.io/badge/Google_Gemma_4-LiteRT--LM-4285F4?logo=google&logoColor=white)](https://ai.google.dev/gemma)
[![SQLite RAG](https://img.shields.io/badge/SQLite-FTS5_RAG-003B57?logo=sqlite&logoColor=white)](https://www.sqlite.org/fts5.html)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Gemmea** is an offline mobile application built to provide actionable agronomic guidance directly to farmers without requiring an internet connection. The name combines **"Mmea"** (*plant* or *crop* in Swahili, widely spoken across DRC and East Africa) with **Gemma** (Google's open AI model family).

The app pairs local multimodal vision and text generation from **Google Gemma 4** (`gemma-4-E2B-it.litertlm`) running directly on mobile hardware with an offline **SQLite FTS5 Retrieval-Augmented Generation (RAG)** engine stocked with official agronomic guidelines from the **FAO** and **IITA**.

---

## Origin & Real-World Impact

Living and working as a software developer in Bukavu, Eastern Democratic Republic of the Congo (South Kivu), I see a daily reality: throughout our region and surrounding rural farming communities, cellular internet is either non-existent, unreliable, or too expensive for smallholder farmers and local agricultural cooperatives.

At the same time, these farmers face critical threats to their daily harvests:
* **Cassava Mosaic Disease** (*Cassava Mosaic Virus*) & **Brown Streak Disease**
* **Maize Common Rust** (*Puccinia sorghi*) & **Fall Armyworm**
* **Banana Xanthomonas Wilt** (*BXW*)

**Gemmea** was built to solve this exact problem: bringing modern generative AI capabilities directly onto an agricultural producer's phone, **with zero reliance on cellular networks or cloud infrastructure.**

---

## Technical Architecture: Gemma 4 + SQLite RAG + Flutter

```
[ 📱 User / Farmer in the Field ]
        │
        ├── 1. Leaf Photo OR Chat Question
        ▼
┌─────────────────────────────────────────────────────────────┐
│ 🔎 1. LOCAL RAG ENGINE (SQLite FTS5)                       │
│ - Weighted full-text search across FAO / IITA guides        │
│ - Official snippets: symptoms, bio-remedies & calendar      │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼ 2. Fact Injection Context
┌─────────────────────────────────────────────────────────────┐
│ 🧠 2. LOCAL GEMMA 4 ENGINE (LiteRT-LM / CPU Thread)         │
│ - GemmaEngineManager (thread safety & session locking)      │
│ - Multimodal VLM (Leaf Image Analysis - 4096 tokens)        │
│ - Conversational Chat Assistant (Sequential - 2048 tokens) │
└──────────────────────────────┬──────────────────────────────┘
                               │
                               ▼ 3. Grounded & Direct Response
┌─────────────────────────────────────────────────────────────┐
│ 📊 3. FLUTTER UI & REPORTING                                │
│ - Structured visual diagnostic & Organic Remedies           │
│ - Text-to-Speech (TTS) & PDF Farm Health Reports            │
└──────────────────────────────┬──────────────────────────────┘
```

### 1. Local RAG Engine (SQLite FTS5)
To prevent model hallucinations and ensure scientifically sound advice:
* **FTS5 Knowledge Base**: Official FAO and IITA fact sheets indexed locally using weighted full-text search ([`sqlite_helper.dart`](lib/data/datasources/sqlite_helper.dart)).
* **Dynamic Grounding**: For technical questions or scans, relevant factual excerpts are retrieved and injected into Gemma's system prompt as strict factual constraints ([`chat_repository_impl.dart`](lib/data/repositories/chat_repository_impl.dart)).
* **Embedded Regional Calendar**: Native knowledge of East African and Great Lakes planting seasons (Seasons A & B, planting dates, crop spacing).

### 2. On-Device Gemma 4 Execution
* **Native Binding Package**: Powered by `flutter_gemma`, binding Google's **LiteRT-LM** mobile runtime.
* **Engine Resource Manager (`GemmaEngineManager`)**: Implements a thread-safe memory manager ([`gemma_engine_manager.dart`](lib/core/services/gemma_engine_manager.dart)) with an execution lock (`_isEngineActive`) to maintain RAM stability on budget Android phones.
* **Multimodal VLM Analysis (Leaf Scanning)**:
  * Processes captured images through [`gemma_local_source.dart`](lib/data/datasources/gemma_local_source.dart) configured to **`maxTokens: 4096`**.
  * **Urgent Fast Short-Circuit**: If a scanned image is not a plant leaf (e.g. faces, objects), Gemma immediately stops generation to return a short *"Leaf not detected"* alert.
  * Organizes diagnostic outputs into 7 official agronomic sections.
* **Conversational Assistant**:
  * Rolling 5-message history window for contextual dialogue.
  * Token stream capped at **`maxTokens: 2048`** for quick responses.
  * Direct response rules without generic disclaimers.

---

## Code Structure & Key Files

For those evaluating the implementation quality, here are the primary components in the repository:

* **Gemma 4 Engine & Concurrency Lock**: [`lib/core/services/gemma_engine_manager.dart`](lib/core/services/gemma_engine_manager.dart)  
  Central manager for the LiteRT-LM instance and inference session isolation.
* **Database & SQLite RAG Engine**: [`lib/data/datasources/sqlite_helper.dart`](lib/data/datasources/sqlite_helper.dart)  
  FTS5 indexing of FAO/IITA guides and contextual search queries.
* **Gemma VLM Multimodal Source**: [`lib/data/datasources/gemma_local_source.dart`](lib/data/datasources/gemma_local_source.dart)  
  On-device visual inference, leaf validation, and prompt engineering.
* **Chat Repository & RAG Pipeline**: [`lib/data/repositories/chat_repository_impl.dart`](lib/data/repositories/chat_repository_impl.dart)  
  RAG assembly, regional conversation rules, and streaming response management.
* **PDF Report Service**: [`lib/core/services/pdf_report_service.dart`](lib/core/services/pdf_report_service.dart)  
  Offline export of farm diagnostic summary reports.
* **Business Logic (BLoC/Cubit)**: [`lib/presentation/bloc/`](lib/presentation/bloc/)  
  Clean state management separation (`ScanCubit`, `ChatCubit`, `HomeCubit`).

---

## Running the Project Locally

### Prerequisites
1. **Flutter SDK** (v3.27.0 or higher) installed and configured.
2. **Android SDK** (Android 10 / API 29+ recommended; physical phone with at least 4 GB RAM recommended).
3. **Model Weights**: The Gemma 4 model asset (`gemma-4-E2B-it.litertlm`) is placed in the `assets/` directory or fetched on first initialization via LiteRT.

### Build Steps

```bash
# 1. Clone the repository
git clone https://github.com/glosings0n/gemmea.git
cd gemmea

# 2. Install Flutter dependencies
flutter pub get

# 3. Run unit tests to verify project integrity
flutter test

# 4. Run the app in release mode on a connected Android phone
flutter run --release
```

---

## Current Limitations & Technical Challenges

While **Gemmea** is fully operational offline, we transparently document the following current limitations:

1. **Visual Dataset & Zero-Shot Classification**:  
   Gemma 4 VLM is an open-weights general multimodal model. Because it has not yet been fine-tuned on local tropical leaf cultivars (such as indigenous cassava or sweet potato varieties), it can occasionally label certain leaves as *"Unknown plant"* or generic crops. Domain-specific fine-tuning is planned.
2. **Context Scale & Mobile Quantization**:  
   To ensure smooth execution on budget Android hardware (4–8 GB RAM), we use the quantized `gemma-4-E2B-it.litertlm` format. On-device RAM constraints prevent using larger context windows or larger model variants (such as Gemma 9B), which can sometimes yield concise responses for complex queries.
3. **Multilingual UI Support (Swahili, Lingala, English)**:  
   Due to time constraints during the hackathon build, complete native UI localization for multiple regional languages (**Kiswahili**, **Lingala**, **English**) was not finished (the current UI is French-primary with integrated Swahili terminology).
4. **CPU Inference Speed**:  
   On entry-level smartphones lacking dedicated NPU hardware, CPU fallback visual inference takes approximately 5 to 10 seconds.

---

## Future Roadmap

* **Fine-Tuning Gemma 4 VLM on Tropical Crops**: Training Gemma VLM on an annotated dataset of East African crop diseases (Cassava, Maize, Banana, Beans) via QLoRA.
* **Complete Multilingual Support**: Adding native Kiswahili, Lingala, and English UI toggles and prompt pipelines.
* **Offline Cooperative Sync (Mesh / Bluetooth)**: Sharing health diagnostic reports between farmers and cooperative leaders via Bluetooth or Wi-Fi Direct without cellular data.
* **Bluetooth IoT Sensor Integration**: Connecting low-cost Bluetooth soil moisture and pH sensors to trigger automated RAG irrigation schedules.

---

## Privacy & Data Sovereignty

* **0% Network Requests**: No user data, photos, or chat messages ever leave the device.
* **Complete Privacy**: 100% on-device processing (*On-Device AI*).
* **Field Ready**: Performs reliably in remote farming areas without cellular coverage.

---

### Official Kaggle Writeup
A detailed summary document prepared for competition evaluation is available in [`KAGGLE_WRITEUP.md`](KAGGLE_WRITEUP.md).

---

### About the Author

* **Developer:** Georges Byona  
* **Role:** Software Engineer  
* **Location:** Bukavu, South Kivu, Democratic Republic of the Congo  
* **Event:** *Build with Gemma 2026 Challenge* (GDG on Campus UCB)  
* **Bio:** [https://linktr.ee/glosings0n](https://linktr.ee/glosings0n)  
* **GitHub Repository:** [https://github.com/glosings0n/gemmea](https://github.com/glosings0n/gemmea)
