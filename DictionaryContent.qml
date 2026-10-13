import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Shared Dictionary Content View
// Used by both the Bar popup (Panel.qml) and the Fullscreen Overlay (Overlay.qml)
Column {
  id: root

  property var service: null
  property color foreground: Color.foreground
  property color accentColor: Color.accent
  property string fontFamily: Style.font.family
  property real maxFlickHeight: Style.space(460)

  signal closeRequested()

  function searchWord(word) {
    var clean = Model.cleanWord(word)
    if (!clean) return
    searchInput.text = clean
    if (service) service.lookup(clean)
  }

  function focusSearch() {
    searchInput.forceActiveFocus()
    searchInput.selectAll()
  }

  spacing: Style.space(8)

  // ------------------------------------------------------------- Search Row
  RowLayout {
    width: parent.width
    spacing: Style.space(6)

    TextField {
      id: searchInput
      Layout.fillWidth: true
      placeholderText: "Search Oxford dictionary..."
      font.pixelSize: Style.font.body
      font.family: root.fontFamily

      onAccepted: {
        if (text.trim() !== "") {
          root.searchWord(text.trim())
        }
      }

      Keys.onEscapePressed: root.closeRequested()
    }

    Button {
      id: clearBtn
      visible: searchInput.text.length > 0
      iconText: Model.GLYPH_CLEAR
      tooltipText: "Clear"
      onClicked: {
        searchInput.text = ""
        searchInput.forceActiveFocus()
      }
    }

    Button {
      id: searchBtn
      iconText: Model.GLYPH_SEARCH
      text: ""
      tooltipText: "Search"
      accent: root.accentColor
      onClicked: {
        if (searchInput.text.trim() !== "") {
          root.searchWord(searchInput.text.trim())
        }
      }
    }
  }

  // ------------------------------------------------------------- Recent Searches
  Flow {
    width: parent.width
    spacing: Style.space(4)
    visible: service && service.recentWords && service.recentWords.length > 0 && (!service.currentResult || !service.currentResult.found)

    Text {
      text: "Recent:"
      color: Qt.darker(root.foreground, 1.4)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      anchors.verticalCenter: parent.verticalCenter
    }

    Repeater {
      model: service ? service.recentWords : []

      Button {
        text: modelData
        fontSize: Style.font.caption
        horizontalPadding: Style.space(6)
        verticalPadding: Style.space(2)
        onClicked: root.searchWord(modelData)
      }
    }
  }

  PanelSeparator {
    width: parent.width
  }

  // ------------------------------------------------------------- Scrollable Results
  Flickable {
    id: resultsFlick
    width: parent.width
    height: Math.min(root.maxFlickHeight, contentHeight)
    contentWidth: width
    contentHeight: resultsColumn.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick
    interactive: contentHeight > height
    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

    Column {
      id: resultsColumn
      width: parent.width
      spacing: Style.space(10)

      // --------------------------------- State 1: Loading
      Item {
        width: parent.width
        height: Style.space(80)
        visible: service && service.loading

        Row {
          anchors.centerIn: parent
          spacing: Style.space(8)

          Text {
            text: Model.GLYPH_SEARCH
            color: root.accentColor
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
            anchors.verticalCenter: parent.verticalCenter
          }

          Text {
            text: "Looking up definition..."
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }

      // --------------------------------- State 2: Not Found & Suggestions
      Column {
        width: parent.width
        spacing: Style.space(8)
        visible: service && !service.loading && service.currentResult && !service.currentResult.found

        Row {
          spacing: Style.space(6)
          Text {
            text: Model.GLYPH_LIGHTBULB
            color: Color.urgent
            font.family: root.fontFamily
            font.pixelSize: Style.font.title
          }
          Text {
            text: "No match for \"" + (service.currentResult ? service.currentResult.term : "") + "\""
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Style.font.body
            font.bold: true
          }
        }

        Text {
          visible: service.currentResult && service.currentResult.suggestions && service.currentResult.suggestions.length > 0
          text: "Did you mean:"
          color: Qt.darker(root.foreground, 1.3)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        Flow {
          width: parent.width
          spacing: Style.space(6)
          visible: service.currentResult && service.currentResult.suggestions && service.currentResult.suggestions.length > 0

          Repeater {
            model: (service.currentResult && service.currentResult.suggestions) ? service.currentResult.suggestions : []

            Button {
              text: modelData
              bordered: true
              fontSize: Style.font.body
              horizontalPadding: Style.space(8)
              verticalPadding: Style.space(4)
              onClicked: root.searchWord(modelData)
            }
          }
        }
      }

      // --------------------------------- State 3: Word Found
      Column {
        width: parent.width
        spacing: Style.space(8)
        visible: service && !service.loading && service.currentResult && service.currentResult.found

        // Headword & Part of Speech
        Row {
          width: parent.width
          spacing: Style.space(8)

          Text {
            text: (service.currentResult && service.currentResult.term) || ""
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Math.round(Style.font.body * 1.5)
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
          }

          Rectangle {
            visible: service.currentResult && service.currentResult.pos && service.currentResult.pos !== "unknown"
            height: Style.space(20)
            width: posText.implicitWidth + Style.space(12)
            radius: Style.cornerRadius
            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.18)
            anchors.verticalCenter: parent.verticalCenter

            Text {
              id: posText
              anchors.centerIn: parent
              text: Model.formatPos(service.currentResult ? service.currentResult.pos : "")
              color: root.accentColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              font.bold: true
            }
          }
        }

        // Pronunciation Audio & Phonetics
        Row {
          spacing: Style.space(10)
          visible: service.currentResult && service.currentResult.pronunciation

          // UK Pronunciation
          Row {
            spacing: Style.space(4)
            visible: service.currentResult && service.currentResult.pronunciation && service.currentResult.pronunciation.uk && (service.currentResult.pronunciation.uk.phonetic || service.currentResult.pronunciation.uk.audio)

            Button {
              iconText: Model.GLYPH_AUDIO
              text: "UK"
              fontSize: Style.font.caption
              horizontalPadding: Style.space(6)
              verticalPadding: Style.space(2)
              enabled: service.currentResult && service.currentResult.pronunciation.uk && !!service.currentResult.pronunciation.uk.audio
              onClicked: {
                if (service && service.currentResult.pronunciation.uk.audio) {
                  service.playAudio(service.currentResult.pronunciation.uk.audio)
                }
              }
            }

            Text {
              text: (service.currentResult && service.currentResult.pronunciation.uk && service.currentResult.pronunciation.uk.phonetic) || ""
              color: Qt.darker(root.foreground, 1.25)
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          // US Pronunciation
          Row {
            spacing: Style.space(4)
            visible: service.currentResult && service.currentResult.pronunciation && service.currentResult.pronunciation.us && (service.currentResult.pronunciation.us.phonetic || service.currentResult.pronunciation.us.audio)

            Button {
              iconText: Model.GLYPH_AUDIO
              text: "US"
              fontSize: Style.font.caption
              horizontalPadding: Style.space(6)
              verticalPadding: Style.space(2)
              enabled: service.currentResult && service.currentResult.pronunciation.us && !!service.currentResult.pronunciation.us.audio
              onClicked: {
                if (service && service.currentResult.pronunciation.us.audio) {
                  service.playAudio(service.currentResult.pronunciation.us.audio)
                }
              }
            }

            Text {
              text: (service.currentResult && service.currentResult.pronunciation.us && service.currentResult.pronunciation.us.phonetic) || ""
              color: Qt.darker(root.foreground, 1.25)
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }

        PanelSeparator {
          width: parent.width
        }

        // Senses List
        Column {
          width: parent.width
          spacing: Style.space(10)

          Repeater {
            model: (service.currentResult && service.currentResult.senses) ? service.currentResult.senses : []

            Column {
              width: parent.width
              spacing: Style.space(4)

              // Definition Header & Grammar
              Row {
                width: parent.width
                spacing: Style.space(6)

                Text {
                  text: (index + 1) + "."
                  color: root.accentColor
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  font.bold: true
                }

                Rectangle {
                  visible: !!modelData.grammar
                  height: Style.space(18)
                  width: gramText.implicitWidth + Style.space(8)
                  radius: Math.max(1, Style.cornerRadius / 2)
                  color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.08)
                  anchors.verticalCenter: parent.verticalCenter

                  Text {
                    id: gramText
                    anchors.centerIn: parent
                    text: modelData.grammar || ""
                    color: Qt.darker(root.foreground, 1.3)
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                  }
                }

                Text {
                  width: parent.width - Style.space(40)
                  text: modelData.definition || ""
                  color: root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                  wrapMode: Text.Wrap
                }
              }

              // Examples
              Column {
                width: parent.width
                spacing: Style.space(3)
                leftPadding: Style.space(16)
                visible: modelData.examples && modelData.examples.length > 0

                Repeater {
                  model: modelData.examples || []

                  Row {
                    width: parent.width
                    spacing: Style.space(6)

                    Rectangle {
                      width: 2
                      height: parent.height
                      color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.45)
                    }

                    Text {
                      width: parent.width - Style.space(12)
                      text: "\"" + modelData + "\""
                      color: Qt.darker(root.foreground, 1.2)
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                      font.italic: true
                      wrapMode: Text.Wrap
                    }
                  }
                }
              }
            }
          }
        }

        // Word Origin Card
        Column {
          width: parent.width
          spacing: Style.space(4)
          visible: service.currentResult && !!service.currentResult.word_origin

          PanelSeparator {
            width: parent.width
          }

          Row {
            spacing: Style.space(6)
            Text {
              text: Model.GLYPH_ORIGIN
              color: root.accentColor
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }
            Text {
              text: "Word Origin"
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              font.bold: true
            }
          }

          BorderSurface {
            width: parent.width
            horizontalPadding: Style.space(8)
            verticalPadding: Style.space(6)
            radius: Style.cornerRadius
            color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.05)

            Text {
              width: parent.width
              text: (service.currentResult && service.currentResult.word_origin) || ""
              color: Qt.darker(root.foreground, 1.2)
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              wrapMode: Text.Wrap
            }
          }
        }
      }

      // --------------------------------- State 4: Welcome / Idle Empty State
      Column {
        width: parent.width
        spacing: Style.space(10)
        visible: service && !service.loading && !service.currentResult

        Item { height: Style.space(20); width: 1 }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: Model.GLYPH_BOOK
          font.family: root.fontFamily
          font.pixelSize: Style.space(36)
          color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.7)
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "Oxford Learner's Dictionary"
          font.family: root.fontFamily
          font.pixelSize: Style.font.title
          font.bold: true
          color: root.foreground
        }

        Text {
          anchors.horizontalCenter: parent.horizontalCenter
          text: "Search definitions, British & American pronunciation, and examples."
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          color: Qt.darker(root.foreground, 1.4)
        }

        Row {
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: Style.space(12)

          Text {
            text: "↵ Enter to search"
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            color: Qt.darker(root.foreground, 1.5)
          }

          Text {
            text: "Esc to close"
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
            color: Qt.darker(root.foreground, 1.5)
          }
        }
      }
    }
  }
}
