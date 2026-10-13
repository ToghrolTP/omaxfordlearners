import QtQuick
import Quickshell
import Quickshell.Io

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

  readonly property string scriptPath: Qt.resolvedUrl("oxford_lookup.py").replace("file://", "")

  signal lookupFinished(var result)

  function playAudio(url) {
    if (!url || String(url).trim() === "") return
    audioProcess.running = false
    audioProcess.command = ["mpv", "--no-video", "--really-quiet", String(url).trim()]
    audioProcess.running = true
  }

  function lookup(term) {
    var cleanTerm = String(term || "").trim()
    if (!cleanTerm) return

    lookupSeq++
    loading = true
    error = ""

    // Add to recentWords if not already there
    var list = root.recentWords.slice()
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
    lookupProcess.command = args
    lookupProcess.running = true
  }

  Process {
    id: lookupProcess
    running: false
    command: []

    property int seq: 0

    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: function(text) {
        if (lookupProcess.seq !== root.lookupSeq) return
        root.loading = false
        try {
          var parsed = JSON.parse(text)
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
          root.error = "Failed to parse dictionary response"
          root.currentResult = null
        }
      }
    }

    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: function(text) {
        if (lookupProcess.seq !== root.lookupSeq) return
        if (text && text.trim() !== "") {
          console.warn("[omaxfordlearners] Python error: " + text.trim())
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
