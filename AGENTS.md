# AGENTS.md | Strict Brand, UI & Engineering Guidelines (glosings0n / Gemmea)

These rules are mandatory across all code, UI, documentation, slides, and codelabs associated with this project. Follow them without exception.

---

## 1. Punctuation & Copy Rules
- **Zero Long Dashes (`—` or `–`):** NEVER use em-dashes (`—`, `&mdash;`) or en-dashes (`–`, `&ndash;`) anywhere in titles, headings, metadata, UI copy, tables, or comments.
  - In titles and headers: always use the pipe separator `|` (e.g., `On-Device AI with Flutter & Gemma | droidCon Uganda 2026`).
  - In sentences, lists, and ranges: use `:`, `;`, `,`, `to`, or a standard hyphen `-` (e.g., `3GB to 6GB RAM`, `180ms to 600ms`).
- **Zero Emojis:** NEVER use emojis anywhere in UI widgets, HTML, markdown, labels, or code comments. Always use crisp SVG or Material/Lucide icons instead.

---

## 2. Visual Design, Colors & Components
- **Zero Gradients & Zero Glows:** NEVER use `linear-gradient`, `radial-gradient`, `conic-gradient`, or neon glow shadows (`box-shadow` / `text-shadow` glows).
  - Always use **solid flat colors** or subtle semi-transparent solid fills and borders (`rgba(...)`).
- **Callout / Alert Boxes:**
  - Always use a uniform `1px solid` border on all four sides (same style from left to right).
  - NEVER use a thick colored left stripe (`border-left: 4px solid`).
- **SVG Icons:**
  - Always set `stroke-linecap="round"` and `stroke-linejoin="round"` on stroke SVGs.
  - For icons containing a dot (`info`, `warning`, `danger`), ALWAYS render the dot using an explicit filled `<circle>` instead of a zero-length `<line>` hack.

---

## 3. Brand Identity & Typography
- **Brand Name:** Always write `glosings0n` (strictly NO trailing dot: never write `glosings0n.`).
- **Author & Organization Identity:**
  - **Georges Byona** (`@glosings0n`), Software Engineer, Edge-AI Researcher, Founder @ **LosingTek**, Initiator of **FlutterFire Summer Camp**.
- **Typography System (Web & Codelabs):**
  - **UI & Body Text:** `'Figtree'`
  - **Code, Numbers/Digits (`0-9`, `+`), Technical Metrics & `@glosings0n` Handle:** `'JetBrains Mono'`
  - **LosingTek Brand Wordmark:** `'Urbanist'` (`<span class="losingtek-font"><span class="brand-bold">Losing</span>Tek</span>` with bold `Losing` and regular `Tek`).
