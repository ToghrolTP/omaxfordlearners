# Oxford Learner's Dictionary (`omaxfordlearners`)

[![Omarchy Plugin](https://img.shields.io/badge/Omarchy-Quattro%20Plugin-blue)](https://github.com/ToghrolTP/omaxfordlearners)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Python 3](https://img.shields.io/badge/python-3.8+-blue.svg)](https://www.python.org/)

An authentic, native Oxford Advanced Learner's Dictionary (OALD) desktop plugin for the **Omarchy shell** (Quickshell / Hyprland).

Look up English words, grammatical forms, definitions, real-world examples, and word origins, and listen to authentic British (UK) and American (US) native pronunciations with a single click from your Omarchy bar or a global hotkey.

---

## Features

- **Authoritative Oxford Definitions**: Full definitions, grammatical classifications (e.g. `[uncountable]`, `[transitive]`, `[not usually before noun]`), and highlighted real-world usage examples.
- **Native Pronunciation Audio**: Direct, high-quality British (UK) and American (US) MP3 audio streams played seamlessly via `mpv`.
- **Phonetic IPA Transcriptions**: Clean International Phonetic Alphabet (IPA) transcriptions for both UK and US accents.
- **Word Origin & Etymology**: Historical origins and etymology cards.
- **Intelligent "Did You Mean" Suggestions**: When a word is misspelled or not found, provides interactive suggestion badges you can click to search instantly.
- **Ultra-Fast Local Caching**: Automatic persistent caching in `~/.cache/omaxfordlearners/` — repeated lookups resolve in milliseconds (~0ms latency) and are available offline.
- **60fps Fluid & Non-Blocking**: Network requests and audio streaming run out-of-process via Quickshell's asynchronous `Process` APIs, keeping the shell UI perfectly smooth.
- **Native Omarchy Design**: Built using Omarchy Quattro tokens (`qs.Commons.Style`, `qs.Commons.Color`, `qs.Ui.KeyboardPanel`) to automatically inherit any active Omarchy theme.
- **Desktop & CLI Friendly**: Includes full IPC support for global Hyprland keybindings, as well as a standalone CLI tool (`oxford_lookup.py`).

---

---

## Installation & Setup

### Automatic Installation (Recommended)

Run the included Omarchy installer script:

```bash
./install.sh
```

This automated wizard:
1. Verifies prerequisites (`python3`, `quickshell`, `omarchy`, `mpv`).
2. Validates plugin manifest schema.
3. Links the plugin into `~/.config/omarchy/plugins/toghroltp.omaxfordlearners`.
4. Enables the Oxford Dictionary widget on the right side of the Omarchy status bar.
5. Installs the desktop launcher entry (`omaxfordlearners.desktop`) and high-res vector icon so you can launch it from **Rofi, Walker, Fuzzel**, or the Omarchy application launcher.
6. Installs the CLI runner command `~/.local/bin/omaxfordlearners`.

To uninstall at any time:
```bash
./install.sh --uninstall
```

---

## Accessing the Dictionary

- **Application Launcher**: Search for **"Oxford Dictionary"** in your launcher (Rofi / Walker / Fuzzel).
- **Omarchy Bar Widget**: Click the book icon (**`󰏪`**) on your status bar.
- **Hyprland Keybindings**: Add to `~/.config/hypr/hyprland.conf`:
  ```ini
  # Super + D toggles dictionary overlay
  bind = $mainMod, D, exec, omaxfordlearners

  # Super + Shift + D looks up highlighted text (clipboard selection)
  bind = $mainMod SHIFT, D, exec, omaxfordlearners --clipboard
  ```
- **Terminal CLI**:
  ```bash
  # Launch overlay with a word query
  omaxfordlearners serendipity

  # Or print raw JSON directly in your terminal
  omaxfordlearners --cli serendipity
  ```

---

## Standalone CLI Usage

The backend engine can also be used directly from your terminal:

```bash
# Standard lookup (outputs structured JSON)
./oxford_lookup.py serendipity

# Play British pronunciation audio
./oxford_lookup.py serendipity --play-uk

# Play American pronunciation audio
./oxford_lookup.py serendipity --play-us

# Bypass local cache
./oxford_lookup.py serendipity --no-cache

# Clear cached entries
./oxford_lookup.py --clear-cache
```

### JSON Structure

```json
{
  "found": true,
  "term": "serendipity",
  "pos": "noun",
  "pronunciation": {
    "uk": {
      "phonetic": "/ˌserənˈdɪpəti/",
      "audio": "https://www.oxfordlearnersdictionaries.com/media/english/uk_pron/s/ser/seren/serendipity__gb_1.mp3"
    },
    "us": {
      "phonetic": "/ˌserənˈdɪpəti/",
      "audio": "https://www.oxfordlearnersdictionaries.com/media/english/us_pron/s/ser/seren/serendipity__us_2.mp3"
    }
  },
  "senses": [
    {
      "definition": "the fact of something interesting or pleasant happening by chance",
      "examples": [
        "Meeting her like that, and there of all places, was true serendipity!"
      ],
      "grammar": "[uncountable]"
    }
  ],
  "word_origin": "1754: coined by Horace Walpole, suggested by The Three Princes of Serendip"
}
```

---

## Testing & Quality Assurance

Run the Python unit test suite:

```bash
python3 -m unittest discover tests -v
```

Validate QML syntax and imports:

```bash
qmllint -I /usr/share/omarchy/shell BarWidget.qml DictionaryService.qml Panel.qml
```

Validate Omarchy plugin manifest:

```bash
omarchy plugin validate .
```

---

## License

MIT License. Designed and maintained by Toghrol.
