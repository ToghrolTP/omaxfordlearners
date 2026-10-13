import QtQuick
import qs.Commons
import qs.Ui

// Interactive Dictionary Search and Definition Panel
// Provides search input, recent lookups, headword, UK/US audio, senses, and word origin
Panel {
  id: root
  moduleName: "toghroltp.omaxfordlearners"
  ipcTarget: "toghroltp.omaxfordlearners"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var service: null

  readonly property var barIdentity: hostWidget || root
  readonly property color fg: bar ? bar.foreground : Color.foreground
  readonly property color accentColor: Color.accent
  readonly property string family: bar ? bar.fontFamily : Style.font.family

  function searchWord(word) {
    if (content) content.searchWord(word)
  }

  function open() {
    root.controller.show()
    Qt.callLater(function() {
      if (content) content.focusSearch()
    })
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    root.opened ? close() : open()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: content
    contentWidth: panel.fittedContentWidth(Style.space(420))
    contentHeight: panel.fittedContentHeight(content.implicitHeight, Style.space(560))

    DictionaryContent {
      id: content
      width: parent.width
      service: root.service
      foreground: root.fg
      accentColor: root.accentColor
      fontFamily: root.family
      maxFlickHeight: Style.space(460)
      onCloseRequested: root.close()
    }
  }
}
