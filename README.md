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

## Installation

### Method 1: Local Plugin Directory (Recommended)

Link or clone this repository into your Omarchy plugins directory:

```bash
mkdir -p ~/.config/omarchy/plugins
ln -s ~/Documents/qml/omaxfordlearners ~/.config/omarchy/plugins/toghroltp.omaxfordlearners
```

Validate the plugin:

```bash
omarchy plugin validate ~/.config/omarchy/plugins/toghroltp.omaxfordlearners
```

Enable the widget in Omarchy:

```bash
omarchy plugin enable toghroltp.omaxfordlearners right
```

---

## Hyprland Hotkeys

Add convenient shortcut bindings to your `~/.config/hypr/hyprland.conf`:

```ini
# Toggle Oxford Dictionary popup
bind = $mainMod, D, exec, omarchy shell msg toghroltp.omaxfordlearners toggle

# Look up selected text directly from primary selection (mouse highlight)
bind = $mainMod SHIFT, D, exec, omarchy shell msg toghroltp.omaxfordlearners lookup "$(wl-paste --primary)"
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
