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

function cleanWord(text) {
  if (!text) return "";
  return String(text).trim();
}
