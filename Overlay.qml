import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// Fullscreen centered modal overlay surface
// Summoned via application launcher, Omarchy shell summon, or global keybinding
Item {
  id: root

  property var shell: null
  property var manifest: null

  property bool opened: false

  property string fontFamily: Style.font.family
  property color background: Color.menu.background
  property color foreground: Color.menu.text
  property color border: Color.menu.border
  property color scrim: Color.menu.scrim
  property var borderSpec: Border.surfaceSpec("menu", "border", border, Math.max(1, Style.space(2)))
  readonly property int cornerRadius: Style.cornerRadius
  readonly property int contentMargin: Math.max(Style.space(22), Style.spacing.panelPadding)

  readonly property string pluginId: (root.manifest && root.manifest.id) || "toghroltp.omaxfordlearners"
  readonly property int cardWidth: Math.min(Style.space(620), panelWindow.width - Style.gapsOut * 4)
  readonly property int cardHeight: Math.min(Style.space(680), panelWindow.height - Style.gapsOut * 4)

  function open(params) {
    root.opened = true
    var word = ""
    if (typeof params === "string" && params.trim() !== "" && params !== "{}") {
      try {
        var obj = JSON.parse(params)
        if (obj && obj.word) word = String(obj.word).trim()
      } catch (e) {
        word = params.trim()
      }
    } else if (params && typeof params === "object" && params.word) {
      word = String(params.word).trim()
    }
    Qt.callLater(function() {
      if (dictContent) {
        dictContent.focusSearch()
        if (word) dictContent.searchWord(word)
      }
    })
  }

  function close() {
    root.opened = false
  }

  function dismiss() {
    root.close()
    if (root.shell && typeof root.shell.hide === "function") {
      root.shell.hide(root.pluginId)
    }
  }

  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }

  function searchWord(word) {
    if (!root.opened) root.open("{}")
    if (dictContent) dictContent.searchWord(word)
  }

  DictionaryService {
    id: dictionaryService
    cacheEnabled: true
    preferredAccent: "uk"
    autoPlayAudio: false
  }

  IpcHandler {
    target: "toghroltp.omaxfordlearners.overlay"

    function open(): string { root.open("{}"); return "ok" }
    function close(): string { root.dismiss(); return "ok" }
    function toggle(): string { root.toggle(); return "ok" }
    function lookup(word: string): string {
      root.searchWord(word)
      return "ok"
    }
  }

  PanelWindow {
    id: panelWindow
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "toghroltp-omaxfordlearners"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    // Dimmed background backdrop
    Rectangle {
      anchors.fill: parent
      color: root.scrim
    }

    // Dismiss when clicking outside the card
    MouseArea {
      anchors.fill: parent
      onClicked: root.dismiss()
    }

    // Centered dictionary card
    BorderSurface {
      id: card
      width: root.cardWidth
      height: root.cardHeight
      radius: root.cornerRadius
      anchors.centerIn: parent
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin
      focus: true
      Keys.onEscapePressed: root.dismiss()

      // Prevent clicks inside card from propagating to backdrop
      MouseArea {
        anchors.fill: parent
        onClicked: {}
      }

      DictionaryContent {
        id: dictContent
        anchors.fill: parent
        anchors.topMargin: card.contentTopInset
        anchors.rightMargin: card.contentRightInset
        anchors.bottomMargin: card.contentBottomInset
        anchors.leftMargin: card.contentLeftInset
        service: dictionaryService
        foreground: root.foreground
        accentColor: Color.accent
        fontFamily: root.fontFamily
        maxFlickHeight: card.height - card.contentTopInset - card.contentBottomInset - Style.space(90)
        onCloseRequested: root.dismiss()
      }
    }
  }
}
