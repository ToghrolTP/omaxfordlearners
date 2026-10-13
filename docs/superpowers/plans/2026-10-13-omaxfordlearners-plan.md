# Oxford Learner's Dictionary Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete, native Oxford Learner's Dictionary desktop plugin for Omarchy, featuring accurate definitions, UK/US audio playback, grammar flags, etymological origin, spellcheck suggestions, and instant local caching.

**Architecture:** Python backend (`oxford_lookup.py`) parses HTML from Oxford Learner's Dictionaries into a structured JSON payload conforming to the developer's schema with disk caching in `~/.cache/omaxfordlearners/`. The Omarchy shell loads `manifest.json`, providing a `BarWidget.qml` indicator in the bar and an interactive `Panel.qml` popup supporting real-time search, pronunciation playback via `mpv`, and full keyboard navigation.

**Tech Stack:** Python 3 (standard library: urllib, re, json, pathlib), Quickshell (Qt6 / QML), Omarchy Quattro Framework (`qs.Commons`, `qs.Ui`), mpv (audio player).

**Spec:** `docs/superpowers/specs/2026-10-13-omaxfordlearners-design.md`

## Global Constraints

- Backend must use Python 3 standard library with zero external pip dependencies.
- Output JSON must strictly follow `.developer-note/json-structure-prefrence.md`.
- Plugin manifest must pass `omarchy-plugin-validate .` with zero errors.
- QML code must follow Omarchy UI tokens (`Style`, `Color`, `BorderSurface`, `KeyboardPanel`).
- Every network operation must be asynchronous and non-blocking to keep UI responsive at 60fps.

---

### Task 1: Comprehensive Python Engine & Unit Tests

**Files:**
- Modify: `oxford_lookup.py`
- Create: `tests/test_oxford_lookup.py`

**Interfaces:**
- Consumes: CLI args (`sys.argv`), Oxford Learner's Dictionary HTTP endpoint.
- Produces: JSON payload on stdout containing `found`, `term`, `pos`, `pronunciation` (uk/us phonetics & audio), `senses` (grammar, definition, examples), `word_origin`, and `suggestions` (for not-found/misspelled words).

- [ ] **Step 1: Write the failing unit tests for `oxford_lookup.py`**

Write `tests/test_oxford_lookup.py` testing:
1. `clean_text` helper cleans HTML entities and tags.
2. `parse_dictionary_html` extracts headword, POS, UK/US phonetics and audio URLs.
3. Grammar parsing: entry-level and sense-level grammar (e.g. `[uncountable]`).
4. Word origin extraction from `<span class="unbox" unboxtype="wordorigin">` or equivalent.
5. Suggestions extraction for misspelled terms from `dym-link`.
6. Caching layer: caching to file and cache retrieval.

- [ ] **Step 2: Run tests to verify they fail**

Run: `python3 -m unittest tests/test_oxford_lookup.py`
Expected: FAIL because `parse_dictionary_html` and caching functions are not yet implemented in `oxford_lookup.py`.

- [ ] **Step 3: Implement minimal code in `oxford_lookup.py`**

Refactor `oxford_lookup.py` into testable functions:
- `clean_text(raw_html)`
- `parse_dictionary_html(html_content, term)`
- `lookup_word(term, use_cache=True, cache_dir=None)`
- `play_audio(url)` using `mpv --no-video --really-quiet`
- CLI argument parsing (`--no-cache`, `--play-uk`, `--play-us`, `--clear-cache`, `--json`)

- [ ] **Step 4: Run tests to verify they pass**

Run: `python3 -m unittest tests/test_oxford_lookup.py`
Expected: PASS all tests.

- [ ] **Step 5: Commit**

```bash
git add oxford_lookup.py tests/test_oxford_lookup.py
git commit -m "feat(backend): upgrade oxford_lookup with full schema, suggestions, caching, and tests"
```

---

### Task 2: Omarchy Plugin Manifest (`manifest.json`)

**Files:**
- Create: `manifest.json`

**Interfaces:**
- Consumes: Omarchy plugin schema specifications.
- Produces: `manifest.json` validated by `omarchy-plugin-validate .`.

- [ ] **Step 1: Create `manifest.json`**

Write `manifest.json`:
```json
{
  "schemaVersion": 1,
  "id": "toghroltp.omaxfordlearners",
  "name": "Oxford Dictionary",
  "version": "1.0.0",
  "author": "Toghrol",
  "license": "MIT",
  "description": "Oxford Advanced Learner's Dictionary search, definitions, and native pronunciation in your Omarchy bar.",
  "kinds": [
    "bar-widget"
  ],
  "entryPoints": {
    "barWidget": "BarWidget.qml"
  },
  "barWidget": {
    "displayName": "Oxford Dictionary",
    "description": "Instant Oxford dictionary lookups with UK/US audio and examples",
    "category": "Education",
    "allowMultiple": false,
    "defaultSection": "right",
    "defaults": {
      "autoPlayAudio": false,
      "preferredAccent": "uk",
      "cacheEnabled": true
    },
    "schema": [
      {
        "key": "preferredAccent",
        "type": "enum",
        "label": "Preferred Accent",
        "options": ["uk", "us"],
        "defaultValue": "uk",
        "description": "Which accent to play by default."
      },
      {
        "key": "autoPlayAudio",
        "type": "boolean",
        "label": "Auto-play Audio",
        "defaultValue": false,
        "description": "Automatically play pronunciation audio when a word is looked up."
      },
      {
        "key": "cacheEnabled",
        "type": "boolean",
        "label": "Enable Cache",
        "defaultValue": true,
        "description": "Store results in ~/.cache/omaxfordlearners/ for instant recall."
      }
    ]
  }
}
```

- [ ] **Step 2: Create placeholder `BarWidget.qml` to allow manifest validation**

Create minimal `BarWidget.qml` so `omarchy-plugin-validate` finds the entry point.

- [ ] **Step 3: Run `omarchy-plugin-validate .`**

Run: `omarchy-plugin-validate .`
Expected: Exits with code 0.

- [ ] **Step 4: Commit**

```bash
git add manifest.json BarWidget.qml
git commit -m "feat(plugin): add Omarchy plugin manifest and entry point"
```

---

### Task 3: QML Bar Widget & IPC Interface (`BarWidget.qml`)

**Files:**
- Modify: `BarWidget.qml`

**Interfaces:**
- Consumes: `qs.Commons`, `qs.Ui`, Omarchy bar state (`root.bar`), `settings`.
- Produces: Bar button with book icon, tooltip, click-to-open, and `IpcHandler` exposing `open()`, `close()`, `toggle()`, and `lookup(word: string)`.

- [ ] **Step 1: Implement `BarWidget.qml`**

Implement `BarWidget.qml` according to Omarchy standards:
- Inherits `BarWidget` from `qs.Ui`.
- Declares `moduleName: "toghroltp.omaxfordlearners"`.
- Uses `BarIconButton` or `WidgetButton` with dictionary icon (`󰉿` / `󰏪` or book glyph).
- Hosts `Loader` for `Panel.qml` with `injectPanel()` forwarding bar, settings, anchorItem.
- Implements `IpcHandler` with `target: "toghroltp.omaxfordlearners"`.

- [ ] **Step 2: Verify `BarWidget.qml` syntax and validation**

Run: `omarchy-plugin-validate .`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add BarWidget.qml
git commit -m "feat(ui): implement BarWidget with Omarchy bar integration and IPC handler"
```

---

### Task 4: Dictionary Service & Controller (`DictionaryService.qml` or `DictionaryModel.js`)

**Files:**
- Create: `DictionaryService.qml`

**Interfaces:**
- Consumes: Python script `oxford_lookup.py` via `Quickshell.Io` `Process`.
- Produces: Asynchronous lookup method `search(word)`, `playAudio(url)`, properties `currentResult`, `loading`, `error`, `recentWords`.

- [ ] **Step 1: Implement `DictionaryService.qml`**

- Manages `Process` running `python3 oxford_lookup.py <word>`.
- Collects stdout chunks, parses JSON on exit.
- Manages `audioProcess` running `mpv --no-video --really-quiet <audio_url>`.
- Maintains `recentWords` list (stored in memory and saved to local settings/cache).

- [ ] **Step 2: Commit**

```bash
git add DictionaryService.qml
git commit -m "feat(service): implement asynchronous dictionary lookup and audio playback service"
```

---

### Task 5: Interactive Dictionary Panel (`Panel.qml`)

**Files:**
- Create: `Panel.qml`

**Interfaces:**
- Consumes: `DictionaryService.qml`, `qs.Commons`, `qs.Ui`.
- Produces: Complete dictionary interface with search bar, headword, phonetics, audio buttons, definitions, examples, word origin, and suggestions.

- [ ] **Step 1: Implement `Panel.qml`**

- Uses `KeyboardPanel` with `anchorItem: root.anchorItem` and `bar: root.bar`.
- Search Bar: `TextField` from `qs.Ui` with clear button, auto-focus on open, search trigger on Enter.
- Recent Searches: horizontal chip row of recently looked up terms.
- Content Area: `Flickable` containing:
  - Header: Headword, POS pill, audio buttons for UK and US with IPA text.
  - Grammar banner (e.g. `[uncountable]`).
  - Senses: Loop over senses showing definition and examples with accent styling.
  - Word Origin card.
  - If not found: Display "No exact match found" and clickable suggestion badges.
  - Loading spinner / animated pulse when searching.
- Keyboard bindings: Esc closes panel, Enter in search executes query.

- [ ] **Step 2: Verify QML files syntax**

Run: `omarchy-plugin-validate .`
Expected: PASS.

- [ ] **Step 3: Commit**

```bash
git add Panel.qml
git commit -m "feat(ui): implement rich dictionary lookup panel with audio, senses, and suggestions"
```

---

### Task 6: End-to-End Verification, Documentation & Release Cleanup

**Files:**
- Create: `README.md`
- Create: `preview.png` (or SVG asset/preview diagram)
- Modify: `.gitignore`

**Interfaces:**
- Consumes: Complete project files.
- Produces: Clean, tested, well-documented repository ready for daily use and Omarchy plugin marketplace.

- [ ] **Step 1: Run complete test suite and end-to-end lookup verification**

Run `python3 -m unittest discover tests` and test lookup for multiple words (e.g., "serendipity", "flabbergasted", "misspelledword").

- [ ] **Step 2: Run `omarchy-plugin-validate .`**

Verify plugin passes all validation rules.

- [ ] **Step 3: Write comprehensive `README.md`**

Document features, installation via `omarchy plugin add`, keybindings configuration in Hyprland, CLI usage, settings schema, and architecture.

- [ ] **Step 4: Commit**

```bash
git add README.md .gitignore
git commit -m "docs: add comprehensive README and finalize plugin packaging"
```
