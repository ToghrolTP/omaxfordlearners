#!/usr/bin/env python3
import unittest
import tempfile
import os
import shutil
import json
import sys
from pathlib import Path

# Ensure repo root is on sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

# Import from oxford_lookup
import oxford_lookup


class TestOxfordLookup(unittest.TestCase):
    def setUp(self):
        self.test_dir = tempfile.mkdtemp()

    def tearDown(self):
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_clean_text(self):
        raw = "<span>Hello &amp; <b>World!</b>&#39;s</span>\n  test  "
        expected = "Hello & World!'s test"
        self.assertEqual(oxford_lookup.clean_text(raw), expected)
        self.assertEqual(oxford_lookup.clean_text(""), "")
        self.assertEqual(oxford_lookup.clean_text(None), "")

    def test_parse_found_word(self):
        sample_html = """
        <html>
        <body>
          <h1 class="headword">serendipity</h1>
          <span class="pos">noun</span>
          <div class="phons_br">
            <span class="phon">/ˌserənˈdɪpəti/</span>
            <div class="sound audio_play_button icon-audio" data-src-mp3="https://audio.example.com/uk.mp3"></div>
          </div>
          <div class="phons_n_am">
            <span class="phon">/ˌserənˈdɪpəti/</span>
            <div class="sound audio_play_button icon-audio" data-src-mp3="https://audio.example.com/us.mp3"></div>
          </div>
          <span class="grammar">[uncountable]</span>
          <ol class="senses_multiple">
            <li class="sense">
              <span class="def">the fact of something pleasant happening by chance</span>
              <ul class="examples">
                <li class="example"><span class="x">Meeting her was true serendipity!</span></li>
              </ul>
            </li>
          </ol>
          <span class="unbox" unboxtype="wordorigin">
            <span class="box_title">Word Origin</span>
            <span class="body"><span class="p">Coined by Horace Walpole in 1754.</span></span>
          </span>
        </body>
        </html>
        """
        result = oxford_lookup.parse_dictionary_html(sample_html, "serendipity")
        self.assertTrue(result["found"])
        self.assertEqual(result["term"], "serendipity")
        self.assertEqual(result["pos"], "noun")
        self.assertEqual(result["pronunciation"]["uk"]["phonetic"], "/ˌserənˈdɪpəti/")
        self.assertEqual(result["pronunciation"]["uk"]["audio"], "https://audio.example.com/uk.mp3")
        self.assertEqual(result["pronunciation"]["us"]["phonetic"], "/ˌserənˈdɪpəti/")
        self.assertEqual(result["pronunciation"]["us"]["audio"], "https://audio.example.com/us.mp3")
        self.assertEqual(len(result["senses"]), 1)
        self.assertEqual(result["senses"][0]["grammar"], "[uncountable]")
        self.assertEqual(result["senses"][0]["definition"], "the fact of something pleasant happening by chance")
        self.assertEqual(result["senses"][0]["examples"], ["Meeting her was true serendipity!"])
        self.assertIn("1754", result["word_origin"])

    def test_parse_spellcheck_suggestions(self):
        sample_html = """
        <html>
        <body>
          <div id="didyoumean">Did you mean:</div>
          <ul class="result-list">
            <li><a href="..." class="dym-link">serendipity</a></li>
            <li><a href="..." class="dym-link">serendipities</a></li>
          </ul>
        </body>
        </html>
        """
        result = oxford_lookup.parse_dictionary_html(sample_html, "serendipiti")
        self.assertFalse(result["found"])
        self.assertEqual(result["term"], "serendipiti")
        self.assertEqual(result["suggestions"], ["serendipity", "serendipities"])

    def test_cache_save_and_load(self):
        payload = {
            "found": True,
            "term": "test",
            "pos": "noun",
            "pronunciation": {"uk": {"phonetic": "/t/", "audio": None}, "us": {"phonetic": "/t/", "audio": None}},
            "senses": [{"grammar": "[c]", "definition": "a trial", "examples": []}],
            "word_origin": None
        }
        cache_path = oxford_lookup.get_cache_path("test", cache_dir=self.test_dir)
        oxford_lookup.save_to_cache(payload, cache_path)
        self.assertTrue(os.path.exists(cache_path))

        loaded = oxford_lookup.load_from_cache(cache_path)
        self.assertIsNotNone(loaded)
        self.assertEqual(loaded["term"], "test")
        self.assertTrue(loaded["found"])


if __name__ == "__main__":
    unittest.main()
