import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import App.Theme 1.0
import App.Icons 1.0

// AutocompleteInput — TextField with a live-filtered suggestion dropdown.
//
// Usage:
//   AutocompleteInput {
//       suggestions: ["Apple", "Apricot", "Banana", "Blueberry"]
//       placeholder: "Search fruit…"
//       onAccepted: function(text) { console.log("Chosen:", text) }
//   }
Item {
    id: root

    property var    suggestions:     []
    property string text:            ""
    property string placeholder:     qsTr("Type to search…")
    property int    maxVisible:      8
    property color  accentColor:     ThemeManager.primaryColor
    property color  backgroundColor: Qt.rgba(1, 1, 1, 0.06)
    property color  borderColor:     Qt.rgba(1, 1, 1, 0.18)
    property int    radius:          6
    property bool   caseSensitive:   false
    property bool   showClearButton: true

    signal accepted(string text)

    implicitWidth:  220
    implicitHeight: 36

    // Filter
    readonly property var _filtered: {
        if (input.text.trim() === "") return root.suggestions
        var q = root.caseSensitive ? input.text : input.text.toLowerCase()
        return root.suggestions.filter(function(s) {
            return (root.caseSensitive ? s : s.toLowerCase()).indexOf(q) !== -1
        })
    }

    // ── Field ─────────────────────────────────────────────────────────────────
    Rectangle {
        id: field
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 36
        radius: root.radius
        color: root.backgroundColor
        border.width: 1
        border.color: input.activeFocus ? root.accentColor : root.borderColor
        Behavior on border.color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10; anchors.rightMargin: 8
            spacing: 6

            TextInput {
                id: input
                Layout.fillWidth: true
                font.pixelSize: 13
                color: ThemeManager.textColor
                selectionColor: root.accentColor
                selectedTextColor: "#ffffff"
                clip: true
                verticalAlignment: TextInput.AlignVCenter
                height: parent.height

                Text {
                    anchors.fill: parent
                    text: root.placeholder
                    color: Qt.rgba(ThemeManager.textColor.r,
                                   ThemeManager.textColor.g,
                                   ThemeManager.textColor.b, 0.4)
                    font.pixelSize: 13
                    visible: input.text.length === 0
                    verticalAlignment: Text.AlignVCenter
                }

                onTextChanged: {
                    root.text = text

                    if (text.length > 0) popup.open()
                    else popup.close()
                }

                Keys.onDownPressed:   { popup.open(); listView.currentIndex = Math.min(listView.currentIndex + 1, root._filtered.length - 1) }
                Keys.onUpPressed:     { listView.currentIndex = Math.max(listView.currentIndex - 1, 0) }
                Keys.onReturnPressed: {
                    if (listView.currentIndex >= 0 && listView.currentIndex < root._filtered.length) {
                        _selectItem(root._filtered[listView.currentIndex])
                    } else {
                        root.accepted(input.text)
                        popup.close()
                    }
                }
                Keys.onEscapePressed: popup.close()
            }

            // Clear button
            Rectangle {
                visible: root.showClearButton && input.text.length > 0
                width: 16; height: 16; radius: 8
                color: clearMa.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.08)
                SvgIcon {
                    anchors.centerIn: parent
                    width: 10; height: 10
                    source: Icons.close
                    color: ThemeManager.textSecondaryColor
                }
                MouseArea {
                    id: clearMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: { input.text = ""; popup.close() }
                }
            }
        }
    }

    function _selectItem(s) {
        input.text = s
        root.text  = s
        root.accepted(s)
        popup.close()
    }

    // ── Dropdown ──────────────────────────────────────────────────────────────
    Popup {
        id: popup
        y: field.height + 4
        width: root.width
        padding: 4
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            radius: root.radius
            color: ThemeManager.surfaceColor
            border.color: root.borderColor; border.width: 1
        }

        contentItem: ListView {
            id: listView
            model: root._filtered
            clip: true
            implicitHeight: Math.min(root.maxVisible * 36, contentHeight + 8)
            currentIndex: -1
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: ItemDelegate {
                width: popup.width - 8
                height: 36; padding: 0

                background: Rectangle {
                    radius: 4
                    color: (ListView.isCurrentItem || hovered) ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                }

                contentItem: Text {
                    leftPadding: 10
                    text: modelData; font.pixelSize: 13
                    color: ThemeManager.textColor; verticalAlignment: Text.AlignVCenter

                    // Highlight matched portion
                    TextMetrics { id: tm; text: modelData; font: parent.font }
                }

                onClicked: root._selectItem(modelData)
                onHoveredChanged: if (hovered) listView.currentIndex = index
            }
        }
    }
}

