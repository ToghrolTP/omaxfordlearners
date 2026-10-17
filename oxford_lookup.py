#!/usr/bin/env python3
"""
Oxford Learner's Dictionary Lookup Engine
Fetches, parses, and formats definitions, pronunciations, audio, and grammar
from Oxford Learner's Dictionaries into structured JSON.
"""

import sys
import os
import re
import html
import json
import argparse
import urllib.parse
import urllib.request
import urllib.error
import subprocess
import hashlib
from pathlib import Path


def clean_text(raw_html):
    """Strip HTML tags, unescape HTML entities, and collapse whitespace."""
    if not raw_html:
        return ""
    no_tags = re.sub(r"<[^>]+>", "", str(raw_html))
    unescaped = html.unescape(no_tags)
    return " ".join(unescaped.split()).strip()


def get_cache_dir(custom_dir=None):
    """Return cache directory path, ensuring it exists."""
    if custom_dir:
        base = Path(custom_dir)
    else:
        xdg_cache = os.environ.get("XDG_CACHE_HOME")
        if xdg_cache:
            base = Path(xdg_cache) / "omaxfordlearners"
        else:
            base = Path.home() / ".cache" / "omaxfordlearners"
    base.mkdir(parents=True, exist_ok=True)
    return base


def get_cache_path(term, cache_dir=None):
    """Return file path for a cached term."""
    clean_key = re.sub(r"[^\w\-]", "_", term.strip().lower())
    digest = hashlib.md5(term.strip().lower().encode("utf-8")).hexdigest()[:8]
    filename = f"{clean_key}_{digest}.json"
    return str(get_cache_dir(cache_dir) / filename)


def save_to_cache(payload, path):
    """Persist payload as JSON to cache path."""
    try:
        with open(path, "w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False, indent=2)
    except Exception as e:
        sys.stderr.write(f"Warning: Failed to write to cache: {e}\n")


def load_from_cache(path):
    """Load JSON from cache path, returning None on failure."""
    if not os.path.exists(path):
        return None
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as e:
        sys.stderr.write(f"Warning: Failed to read from cache: {e}\n")
        return None


def clear_cache(cache_dir=None):
    """Clear all cached lookups."""
    cdir = get_cache_dir(cache_dir)
    count = 0
    for p in cdir.glob("*.json"):
        try:
            p.unlink()
            count += 1
        except Exception:
            pass
    return count


def parse_dictionary_html(html_content, term):
    """Parse Oxford Learner's Dictionary HTML into structured payload."""
    hw_match = re.search(r'<h1 class="headword"[^>]*>(.*?)</h1>', html_content, re.DOTALL)

    if not hw_match:
        # Check for Did You Mean suggestions
        dym_matches = re.findall(r'<a[^>]*class="dym-link"[^>]*>([^<]+)</a>', html_content)
        if not dym_matches:
            # Fallback for search result items
            dym_matches = re.findall(r'<li[^>]*><a[^>]*href="[^"]*/definition/english/[^"]*"[^>]*>([^<]+)</a>', html_content)

        clean_suggestions = []
        for s in dym_matches:
            c = clean_text(s)
            if c and c.lower() != "english" and c not in clean_suggestions:
                clean_suggestions.append(c)

        return {
            "found": False,
            "term": clean_text(term).replace("<", "").replace(">", ""),
            "error": "Word not found",
            "suggestions": clean_suggestions
        }

    headword = clean_text(hw_match.group(1))

    # Part of Speech
    pos_match = re.search(r'<span class="pos"[^>]*>(.*?)</span>', html_content, re.DOTALL)
    pos = clean_text(pos_match.group(1)) if pos_match else "unknown"

    # British Pronunciation (UK)
    uk_phon_match = re.search(r'<div class="phons_br"[^>]*>.*?<span class="phon">(.*?)</span>', html_content, re.DOTALL)
    uk_audio_match = re.search(r'<div class="phons_br"[^>]*>.*?data-src-mp3="([^"]+)"', html_content, re.DOTALL)
    uk_phon = clean_text(uk_phon_match.group(1)) if uk_phon_match else None
    uk_audio = uk_audio_match.group(1) if uk_audio_match else None

    # North American Pronunciation (US)
    nam_phon_match = re.search(r'<div class="phons_n_am"[^>]*>.*?<span class="phon">(.*?)</span>', html_content, re.DOTALL)
    nam_audio_match = re.search(r'<div class="phons_n_am"[^>]*>.*?data-src-mp3="([^"]+)"', html_content, re.DOTALL)
    nam_phon = clean_text(nam_phon_match.group(1)) if nam_phon_match else None
    nam_audio = nam_audio_match.group(1) if nam_audio_match else None

    # Top-level Grammar (e.g. [uncountable])
    top_grammar_match = re.search(r'<span class="grammar"[^>]*>(.*?)</span>', html_content, re.DOTALL)
    top_grammar = clean_text(top_grammar_match.group(1)) if top_grammar_match else None

    # Word Origin (Etymology)
    origin_text = None
    origin_match = re.search(r'<span class="unbox"[^>]*unboxtype="wordorigin"[^>]*>.*?<span class="body">(.*?)</span>\s*</span>', html_content, re.DOTALL)
    if not origin_match:
        origin_match = re.search(r'Word Origin.*?<span class="body">(.*?)</span>', html_content, re.DOTALL)
    if not origin_match:
        origin_match = re.search(r'<div[^>]*class="[^"]*wordorigin[^"]*"[^>]*>(.*?)</div>', html_content, re.DOTALL)
    if origin_match:
        origin_text = clean_text(origin_match.group(1))

    # Senses & Definitions
    senses = []
    sense_blocks = re.findall(r'<li[^>]*class="[^"]*sense[^"]*"[^>]*>(.*?)</li>', html_content, re.DOTALL)

    for block in sense_blocks:
        def_match = re.search(r'<span class="def"[^>]*>(.*?)</span>', block, re.DOTALL)
        if not def_match:
            continue
        definition = clean_text(def_match.group(1))

        # Check grammar specific to this sense
        sense_gram_match = re.search(r'<span class="grammar"[^>]*>(.*?)</span>', block, re.DOTALL)
        if sense_gram_match:
            sense_grammar = clean_text(sense_gram_match.group(1))
        else:
            sense_grammar = top_grammar

        example_matches = re.findall(r'<span class="x"[^>]*>(.*?)</span>', block, re.DOTALL)
        clean_examples = [clean_text(ex) for ex in example_matches if clean_text(ex)]

        sense_obj = {
            "definition": definition,
            "examples": clean_examples
        }
        if sense_grammar:
            sense_obj["grammar"] = sense_grammar

        senses.append(sense_obj)

    return {
        "found": True,
        "term": headword,
        "pos": pos,
        "pronunciation": {
            "uk": {
                "phonetic": uk_phon,
                "audio": uk_audio
            },
            "us": {
                "phonetic": nam_phon,
                "audio": nam_audio
            }
        },
        "senses": senses,
        "word_origin": origin_text
    }


def fetch_oxford_html(term):
    """Fetch raw HTML from Oxford Learner's Dictionary."""
    encoded_word = urllib.parse.quote(term.strip())
    url = f"https://www.oxfordlearnersdictionaries.com/search/english/?q={encoded_word}"
    headers = {
        "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.5"
    }
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=12) as response:
            return response.read().decode("utf-8", errors="ignore")
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return ""
        raise
    except Exception as e:
        raise RuntimeError(f"Network error: {e}")


def is_valid_term(term):
    """Check if term is a plausible dictionary word and not binary, markup, or garbage."""
    if not term or len(term) > 80:
        return False
    # Check for surrogates (e.g. invalid bytes decoded by surrogateescape)
    if any(0xD800 <= ord(c) <= 0xDFFF for c in term):
        return False
    # Check for unprintable control characters, null bytes, or replacement chars
    if any(ord(c) < 32 and c not in " \t" for c in term):
        return False
    if "\ufffd" in term or "\x00" in term:
        return False
    # Reject HTML angle brackets or tag-like structures
    if "<" in term or ">" in term:
        return False
    # Check common binary file signatures
    if term.startswith(("\x89PNG", "GIF8", "%PDF", "\x7fELF", "PK\x03\x04")):
        return False
    # Must contain at least one alphanumeric or word character
    if not re.search(r"\w", term):
        return False
    return True


def lookup_word(term, use_cache=True, cache_dir=None):
    """Main lookup coordinator: checks cache, fetches HTML, parses, and saves cache."""
    term = term.strip()
    if not term:
        return {"found": False, "term": "", "error": "No word provided."}

    if not is_valid_term(term):
        preview = clean_text(term)
        preview = re.sub(r"[<>]", "", preview)
        preview = preview[:24] + ("…" if len(preview) > 24 else "")
        safe_preview = "".join(
            c if (32 <= ord(c) < 0xD800 or 0xDFFF < ord(c) <= 0x10FFFF) else "?"
            for c in preview
        )
        return {
            "found": False,
            "term": safe_preview,
            "error": "Invalid search term (contains binary or unsupported characters).",
            "suggestions": []
        }

    cache_file = get_cache_path(term, cache_dir)
    if use_cache:
        cached = load_from_cache(cache_file)
        if cached:
            return cached

    try:
        html_content = fetch_oxford_html(term)
        if not html_content:
            return {"found": False, "term": term, "error": "Word not found", "suggestions": []}
        result = parse_dictionary_html(html_content, term)
        if result.get("found") and use_cache:
            save_to_cache(result, cache_file)
        return result
    except Exception as e:
        return {"found": False, "term": term, "error": str(e), "suggestions": []}


def play_audio(url):
    """Play audio URL using system mpv."""
    if not url:
        return False
    try:
        cmd = ["mpv", "--no-video", "--really-quiet", url]
        subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except Exception as e:
        sys.stderr.write(f"Audio playback error: {e}\n")
        return False


def main():
    parser = argparse.ArgumentParser(description="Oxford Learner's Dictionary CLI & Backend Engine")
    parser.add_argument("word", nargs="?", default="", help="Word to look up")
    parser.add_argument("--no-cache", action="store_true", help="Bypass local cache")
    parser.add_argument("--clear-cache", action="store_true", help="Clear cached words")
    parser.add_argument("--play-uk", action="store_true", help="Play UK pronunciation after lookup")
    parser.add_argument("--play-us", action="store_true", help="Play US pronunciation after lookup")
    parser.add_argument("--cache-dir", default=None, help="Custom cache directory")
    parser.add_argument("--audio-url", default=None, help="Directly play an audio URL")

    args = parser.parse_args()

    if args.audio_url:
        success = play_audio(args.audio_url)
        sys.exit(0 if success else 1)

    if args.clear_cache:
        cleared = clear_cache(args.cache_dir)
        print(json.dumps({"cleared": cleared, "message": f"Cleared {cleared} cached entries."}))
        sys.exit(0)

    if not args.word:
        sys.stderr.write("Error: No word provided.\n")
        parser.print_help(sys.stderr)
        sys.exit(1)

    payload = lookup_word(args.word, use_cache=not args.no_cache, cache_dir=args.cache_dir)

    # Print JSON output to stdout
    try:
        print(json.dumps(payload, ensure_ascii=False, indent=2))
    except Exception:
        print(json.dumps(payload, ensure_ascii=True, indent=2))

    # Optional audio playback
    if payload.get("found"):
        pron = payload.get("pronunciation", {})
        if args.play_uk and pron.get("uk", {}).get("audio"):
            play_audio(pron["uk"]["audio"])
        elif args.play_us and pron.get("us", {}).get("audio"):
            play_audio(pron["us"]["audio"])


if __name__ == "__main__":
    main()