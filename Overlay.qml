import QtQuick
import Quickshell
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
  readonly property int contentMargin: Style.spacing.panelPadding

  readonly property string pluginId: (root.manifest && root.manifest.id) || "toghroltp.omaxfordlearners"

  function open(params) {
    root.opened = true
    Qt.callLater(function() {
      if (dictContent) dictContent.focusSearch()
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
      width: Math.min(parent.width - Style.space(40), Style.space(480))
      height: Math.min(parent.height - Style.space(80), dictContent.implicitHeight + root.contentMargin * 2)
      radius: root.cornerRadius
      anchors.centerIn: parent
      color: root.background
      borderSpec: root.borderSpec
      padding: root.contentMargin

      // Prevent clicks inside card from propagating to backdrop
      MouseArea {
        anchors.fill: parent
        onClicked: {}
      }

      DictionaryContent {
        id: dictContent
        anchors.fill: parent
        service: dictionaryService
        foreground: root.foreground
        accentColor: Color.accent
        fontFamily: root.fontFamily
        maxFlickHeight: parent.height - Style.space(120)
        onCloseRequested: root.dismiss()
      }
    }
  }
}
