import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

Item {
  id: root

  property bool cacheEnabled: true
  property string preferredAccent: "uk"
  property bool autoPlayAudio: false

  property bool loading: false
  property var currentResult: null
  property string error: ""
  property var recentWords: []
  property int lookupSeq: 0

  readonly property string scriptPath: {
    var raw = String(Qt.resolvedUrl("oxford_lookup.py") || "")
    return decodeURIComponent(raw.replace(/^file:\/\//, ""))
  }

  signal lookupFinished(var result)

  function playAudio(url) {
    if (!url || String(url).trim() === "") return
    audioProcess.running = false
    audioProcess.command = ["mpv", "--no-video", "--really-quiet", String(url).trim()]
    audioProcess.running = true
  }

  function clearRecent() {
    root.recentWords = []
  }

  function lookup(term) {
    var cleanTerm = Model.cleanWord(term)
    if (!cleanTerm || !Model.isValidWord(cleanTerm)) {
      root.loading = false
      root.error = "Invalid search term (contains binary or unsupported characters)."
      root.currentResult = null
      return
    }

    lookupSeq++
    loading = true
    error = ""
    currentResult = null

    // Purge any invalid entries and add clean word to recentWords
    var list = root.recentWords.filter(function(w) { return Model.isValidWord(w) })
    var idx = list.indexOf(cleanTerm)
    if (idx !== -1) list.splice(idx, 1)
    list.unshift(cleanTerm)
    if (list.length > 8) list.pop()
    root.recentWords = list

    var args = ["python3", root.scriptPath, cleanTerm]
    if (!root.cacheEnabled) {
      args.push("--no-cache")
    }

    lookupProcess.running = false
    lookupProcess.seq = lookupSeq
    lookupProcess.command = args
    lookupProcess.running = true
  }

  Process {
    id: lookupProcess
    running: false
    command: []

    property int seq: 0

    stdout: StdioCollector {
      id: stdoutCollector
      waitForEnd: true
      onStreamFinished: {
        if (lookupProcess.seq !== root.lookupSeq) return
        root.loading = false
        var raw = String(stdoutCollector.text || "").trim()
        if (!raw) {
          root.error = "No response from lookup script"
          root.currentResult = null
          return
        }
        try {
          var parsed = JSON.parse(raw)
          root.currentResult = parsed
          if (!parsed.found) {
            root.error = parsed.error || "Word not found"
          } else {
            root.error = ""
            if (root.autoPlayAudio && parsed.pronunciation) {
              var accent = root.preferredAccent === "us" ? "us" : "uk"
              var audioUrl = parsed.pronunciation[accent] ? parsed.pronunciation[accent].audio : null
              if (audioUrl) root.playAudio(audioUrl)
            }
          }
          root.lookupFinished(parsed)
        } catch (e) {
          console.warn("[omaxfordlearners] JSON parse error: " + e + " text: " + raw)
          root.error = "Failed to parse dictionary response"
          root.currentResult = null
        }
      }
    }

    stderr: StdioCollector {
      id: stderrCollector
      waitForEnd: true
      onStreamFinished: {
        if (lookupProcess.seq !== root.lookupSeq) return
        var err = String(stderrCollector.text || "").trim()
        if (err !== "") {
          console.warn("[omaxfordlearners] Python error: " + err)
        }
      }
    }

    onRunningChanged: if (running) seq = root.lookupSeq

    onExited: function(exitCode, exitStatus) {
      if (seq !== root.lookupSeq) return
      root.loading = false
      if (exitCode !== 0 && !root.currentResult) {
        root.error = "Lookup process exited with error"
      }
    }
  }

  Process {
    id: audioProcess
    running: false
    command: []
  }
}
