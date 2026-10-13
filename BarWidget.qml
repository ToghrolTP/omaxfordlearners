import QtQuick
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Bar widget for Oxford Learner's Dictionary
// Sits in the Omarchy bar, providing a one-click launcher and IPC target
BarWidget {
  id: root
  moduleName: "toghroltp.omaxfordlearners"

  readonly property color defaultForeground: bar ? bar.foreground : Color.foreground
  readonly property string preferredAccent: String(setting("preferredAccent", "uk"))
  readonly property bool autoPlayAudio: setting("autoPlayAudio", false) === true
  readonly property bool cacheEnabled: setting("cacheEnabled", true) === true

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
    if ("service" in target) target.service = dictionaryService
  }

  function togglePanel() {
    if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item && panelLoader.item.open) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item && panelLoader.item.close) panelLoader.item.close()
  }

  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function closeForPopoutSwitch() {
    if (panelLoader.item && panelLoader.item.closeForPopoutSwitch) panelLoader.item.closeForPopoutSwitch()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  DictionaryService {
    id: dictionaryService
    cacheEnabled: root.cacheEnabled
    preferredAccent: root.preferredAccent
    autoPlayAudio: root.autoPlayAudio
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  IpcHandler {
    target: "toghroltp.omaxfordlearners"

    function open(): string { root.open(); return "ok" }
    function close(): string { root.close(); return "ok" }
    function toggle(): string { root.togglePanel(); return "ok" }
    function lookup(word: string): string {
      root.open()
      if (panelLoader.item && panelLoader.item.searchWord) {
        panelLoader.item.searchWord(word)
      }
      return "ok"
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: Model.GLYPH_BOOK
    foreground: dictionaryService.loading ? Color.accent : root.defaultForeground
    slotSize: Style.bar.statusSlot
    tooltipText: "Oxford Learner's Dictionary"

    onPressed: function(b) {
      root.togglePanel()
    }
  }
}
