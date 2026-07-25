# 🌿 Gemmea — 100% On-Device Agronomic AI Assistant for East Africa
## Kaggle Writeup — Build with Gemma 2026 Challenge

---

### 📌 Project Summary
**Gemmea** ("Mmea" = *plant/crop* in Swahili + *Gemma*) is a 100% offline, on-device mobile decision-support application built with **Flutter**, **Google Gemma 4 (`gemma-4-E2B-it.litertlm`)**, and an offline **SQLite FTS5 RAG engine**. 

Designed specifically for smallholder farmers and agricultural cooperatives in internet-blind regions of Eastern DRC (Bukavu, Sud-Kivu) and East Africa, Gemmea diagnoses crop leaf diseases via offline multimodal VLM vision, delivers organic remedies grounded in official FAO/IITA guidelines, and manages farm irrigation calendars without transmitting a single byte to the cloud.

---

### 🎯 Problem Statement & Impact
In Eastern DRC and rural East Africa, cellular internet is either non-existent or financially prohibitive for local farmers. Yet, these farmers face devastating threats to staple crops:
* **Cassava Mosaic Disease (CMD)** & **Cassava Brown Streak Disease (CBSD)**
* **Maize Common Rust** & **Fall Armyworm**
* **Banana Xanthomonas Wilt (BXW)**

Gemmea eliminates the connectivity barrier by running Google Gemma 4 directly on Android devices, democratizing AI access for rural agriculture.

---

### 🏗️ Technical Architecture & Key Innovations

#### 1. On-Device Gemma 4 Multimodal VLM Integration
* **Runtime**: Integrated using `flutter_gemma` leveraging **Google LiteRT-LM**.
* **Memory & Execution Safety**: Features a thread-safe `GemmaEngineManager` with an execution lock (`_isEngineActive`) ensuring stability on budget Android hardware.
* **Scan VLM Evaluation (`maxTokens: 4096`)**: Performs 7-section structured agronomic diagnostic. Includes an **urgent short-circuit evaluator** that immediately stops generation when non-leaf images (faces, shoes, objects) are scanned.
* **Conversational Chat (`maxTokens: 2048`)**: Maintains a 5-message rolling history window with regional system prompts tailored to East African agro-climatic zones.

#### 2. Local SQLite FTS5 RAG Pipeline
To prevent AI hallucinations, Gemmea embeds an offline SQLite Full-Text Search database containing official FAO and IITA biological guides:
* Dynamically retrieves weighted keyword matches based on crop and user query.
* Injects grounded factual constraints and exact organic remedy dosages into Gemma's system prompt prior to inference.
* Embedded East African / Great Lakes Agricultural Calendar (Saisons A & B planting dates, spacing, companion planting).

---

### ⚠️ Current Limitations & Challenges

While Gemmea is fully functional offline, the following limitations have been identified and documented:

1. **Visual Dataset & Zero-Shot Classification Limits**:
   * Gemma 4 VLM is an open-weights general multimodal model. Because it has not yet been specifically fine-tuned on local tropical leaf cultivars (e.g., local DRC cassava or sweet potato varieties), it may occasionally identify certain indigenous leaves as *"Plante inconnue"* or generic crops.
2. **On-Device Quantization & Context Scale**:
   * To maintain real-time performance on budget mobile devices (4–8 GB RAM), we utilize quantized `gemma-4-E2B-it.litertlm`. Mobile memory constraints prevent deploying larger context windows or larger model variants (e.g. 9B), which can occasionally lead to concise or slightly truncated responses for highly complex multi-variable queries.
3. **Multilingual UI & Prompt Pipeline**:
   * Due to strict hackathon time constraints, full UI localization into local languages (**Kiswahili**, **Lingala**, **English**) was not completed for this submission (currently French-primary with embedded Swahili terminology). Native Kiswahili and Lingala prompt pipelines remain a top priority.
4. **Hardware Acceleration Variability**:
   * On low-end Android smartphones lacking dedicated NPU hardware, CPU fallback execution can take ~5–10 seconds for VLM image evaluation.

---

### 🚀 Future Roadmap & Next Steps

1. **Fine-Tuning Gemma 4 VLM on Tropical Agriculture**: Fine-tuning Gemma VLM on a curated dataset of East African crop diseases (PlantVillage + IITA local field images) using LoRA / QLoRA.
2. **Full Multilingual Localization (Kiswahili & Lingala)**: Implementing native Swahili and Lingala UI and model prompts for seamless adoption in rural communities.
3. **Peer-to-Peer Cooperative Sync**: Offline Bluetooth Mesh / Wi-Fi Direct sync allowing farmers to share diagnostic reports with local cooperative leaders without internet.
4. **Bluetooth IoT Sensor Integration**: Connecting low-cost Bluetooth soil moisture and pH sensors to trigger autonomous RAG irrigation advice in Gemmea.

---

### 👨‍💻 Developer & Event Details
* **Developer:** Georges Byona
* **Role:** Software Engineer
* **Location:** Bukavu, Sud-Kivu, Democratic Republic of the Congo
* **Event:** *Build with Gemma 2026 Challenge* (GDG on Campus UCB)
* **Bio / Linktree:** [https://linktr.ee/glosings0n](https://linktr.ee/glosings0n)
* **GitHub Repository:** [https://github.com/glosings0n/gemmea](https://github.com/glosings0n/gemmea)
