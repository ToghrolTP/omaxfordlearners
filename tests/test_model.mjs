import fs from "node:fs";
import vm from "node:vm";
import assert from "node:assert/strict";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const modelPath = path.resolve(__dirname, "../Model.js");
const code = fs.readFileSync(modelPath, "utf-8").replace(/\.pragma library\s*/, "");

const context = {};
vm.createContext(context);
vm.runInContext(code, context);

const { cleanWord, isValidWord, isBinaryOrGarbage, formatPos } = context;

// Format POS tests
assert.equal(formatPos("noun"), "n.");
assert.equal(formatPos("phrasal verb"), "phrasal verb");

// Binary / garbage tests
assert.equal(isBinaryOrGarbage(""), true);
assert.equal(isBinaryOrGarbage(null), true);
assert.equal(isBinaryOrGarbage("\x89PNG\r\n\x1a\n"), true);
assert.equal(isBinaryOrGarbage("hello\x00world"), true);
assert.equal(isBinaryOrGarbage("serendipity"), false);

// HTML / XSS / Markup sanitization in cleanWord
assert.equal(cleanWord("<img src=\"http://attacker.com/leak\">"), "");
assert.equal(cleanWord("hello<img src=\"http://attacker.com/leak\">world"), "hello world");
assert.equal(cleanWord("<script>alert(1)</script>"), "alert 1");
assert.equal(cleanWord("<p>serendipity</p>"), "serendipity");
assert.equal(cleanWord("word<img src=\"x\">"), "word");
assert.equal(cleanWord("<img src=\"x\">word"), "word");
assert.equal(cleanWord("&lt;img src=&quot;x&quot;&gt;"), "");

// Valid dictionary word cleaning
assert.equal(cleanWord("  serendipity  "), "serendipity");
assert.equal(cleanWord('"serendipity"'), "serendipity");
assert.equal(cleanWord("'mother-in-law'"), "mother-in-law");
assert.equal(cleanWord("café"), "café");
assert.equal(cleanWord("ice cream"), "ice cream");
assert.equal(cleanWord("e.g."), "e.g");

// isValidWord validation
assert.equal(isValidWord("<img src=\"http://attacker.com/leak\">"), false);
assert.equal(isValidWord("word<img src=\"http://attacker.com/leak\">"), false);
assert.equal(isValidWord("<script>alert(1)</script>"), false);
assert.equal(isValidWord(""), false);
assert.equal(isValidWord("serendipity"), true);
assert.equal(isValidWord("mother-in-law"), true);
assert.equal(isValidWord("take off"), true);
assert.equal(isValidWord("café"), true);

console.log("All Model.js security and sanitization tests passed!");
