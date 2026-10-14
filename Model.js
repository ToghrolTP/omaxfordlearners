// Model.js - Helper functions and icon constants for omaxfordlearners

.pragma library

var GLYPH_BOOK = "󰏪";
var GLYPH_AUDIO = "󰕾";
var GLYPH_SEARCH = "󰍉";
var GLYPH_CLEAR = "󰅖";
var GLYPH_HISTORY = "󰋚";
var GLYPH_LIGHTBULB = "󰌵";
var GLYPH_ORIGIN = "󰦪";
var GLYPH_ARROW_RIGHT = "󰁔";
var GLYPH_CHECK = "󰄬";
var GLYPH_WARN = "󰀦";

function formatPos(pos) {
  if (!pos) return "";
  var p = String(pos).trim().toLowerCase();
  switch (p) {
    case "noun": return "n.";
    case "verb": return "v.";
    case "adjective": return "adj.";
    case "adverb": return "adv.";
    case "preposition": return "prep.";
    case "conjunction": return "conj.";
    case "pronoun": return "pron.";
    case "exclamation":
    case "interjection": return "excl.";
    default: return p;
  }
}

// Detect binary, control characters, or non-text garbage
function isBinaryOrGarbage(text) {
  if (!text) return true;
  var s = String(text);
  // Check for null bytes, unprintable control characters, or Unicode replacement char
  if (/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F\uFFFD]/.test(s)) return true;
  // Common binary file signatures (PNG, GIF, PDF, ELF, ZIP)
  if (/^(\x89PNG|GIF8|%PDF|\x7fELF|PK\x03\x04)/.test(s)) return true;
  // If exceptionally long without whitespace, or overall too long for any dictionary term
  if (s.length > 80) return true;
  return false;
}

function cleanWord(text) {
  if (!text) return "";
  var s = String(text);
  if (isBinaryOrGarbage(s)) return "";

  // Replace newlines and tabs with spaces
  s = s.replace(/[\r\n\t]+/g, " ");

  // Strip leading and trailing quotes, brackets, and punctuation
  s = s.replace(/^["'“‘\[\(\<]+|["'”’\]\)\>]+$/g, "");

  // Collapse multiple spaces and trim
  s = s.replace(/\s+/g, " ").trim();

  // If length exceeds 64 characters, reject
  if (s.length === 0 || s.length > 64) return "";

  // Must contain at least one alphanumeric or accented character
  if (!/[a-zA-Z0-9\u00C0-\u024F]/.test(s)) return "";

  return s;
}

function isValidWord(text) {
  var clean = cleanWord(text);
  return clean.length > 0 && clean.length <= 64;
}
