import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import App.Icons 1.0

// CommandPalette — VS Code-style ⌘P command search overlay.
//
// Usage:
//   CommandPalette {
//       id: palette
//       commands: [
//           { label: "Open File",         shortcut: "Ctrl+O" },
//           { label: "Toggle Dark Mode",  shortcut: "Ctrl+D" },
//           { label: "Save All",          shortcut: "Ctrl+Shift+S" }
//       ]
//       onCommandSelected: function(cmd) { console.log(cmd.label) }
//   }
//   // Open: palette.open()   Shortcut: bind Shortcut { sequence: "Ctrl+P"; onActivated: palette.open() }
Popup {
    id: root

    property var    commands:    []     // { label, shortcut?, group?, action? }
    property int    maxVisible:  8
    property color  accentColor: ThemeManager.primaryColor

    signal commandSelected(var command)

    function open() {
        _query.text = ""
        _query.forceActiveFocus()
        visible = true
    }

    modal: true
    anchors.centerIn: Overlay.overlay
    width: Math.min(560, Overlay.overlay ? Overlay.overlay.width * 0.8 : 560)
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    Overlay.modal: Rectangle { color: Qt.rgba(0, 0, 0, 0.35) }
    enter:  Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 120; easing.type: Easing.OutCubic } }
    exit:   Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 100 } }

    property var _filtered: {
        var q = _query.text.toLowerCase().trim()
        if (!q) return root.commands
        return root.commands.filter(function(c) { return c.label.toLowerCase().indexOf(q) !== -1 })
    }

    property int _highlightIndex: 0

    background: Rectangle {
        radius: 10; color: ThemeManager.surfaceColor
        border.color: ThemeManager.borderColor; border.width: 1
    }

    contentItem: Column {
        spacing: 0
        width: root.width

        // ── Search field ──────────────────────────────────────────────────────
        Rectangle {
            width: parent.width; height: 48
            color: "transparent"
            radius: 10
            // Only round top corners - clip bottom
            Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 10; color: parent.color }

            Row {
                anchors { fill: parent; leftMargin: 14; rightMargin: 14 } spacing: 10
                SvgIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20; height: 20
                    source: Icons.magnify
                    color: ThemeManager.textSecondaryColor
                }
                TextInput {
                    id: _query
                    width: parent.width - 40; height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 15; color: ThemeManager.textColor
                    selectionColor: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.3)
                    clip: true
                    onTextChanged: root._highlightIndex = 0

                    Keys.onUpPressed:   { root._highlightIndex = Math.max(0, root._highlightIndex - 1) }
                    Keys.onDownPressed: { root._highlightIndex = Math.min(root._filtered.length - 1, root._highlightIndex + 1) }
                    Keys.onReturnPressed: {
                        if (root._filtered.length > 0) {
                            var cmd = root._filtered[root._highlightIndex]
                            root.commandSelected(cmd)
                            if (typeof cmd.action === "function") cmd.action()
                            root.close()
                        }
                    }

                    Text {
                        visible: !parent.text
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Search commands…"); font.pixelSize: 15
                        color: ThemeManager.textSecondaryColor; opacity: 0.6
                    }
                }
            }

            Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: ThemeManager.borderColor }
        }

        // ── Results list ──────────────────────────────────────────────────────
        ListView {
            id: _list
            width: parent.width
            height: Math.min(root._filtered.length, root.maxVisible) * 42
            model: root._filtered
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                width: _list.width; height: 42
                color: index === root._highlightIndex
                       ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.12)
                       : (itemMa.containsMouse ? Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.05) : "transparent")
                Behavior on color { ColorAnimation { duration: 60 } }

                Rectangle {
                    visible: index === root._highlightIndex
                    anchors.left: parent.left; width: 3; height: parent.height
                    color: root.accentColor
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 14
                    spacing: 0
                    Text {
                        width: parent.width - (shortcutTxt.visible ? shortcutTxt.width + 8 : 0)
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label; font.pixelSize: 13; color: ThemeManager.textColor
                        elide: Text.ElideRight
                    }
                    Text {
                        id: shortcutTxt
                        visible: modelData.shortcut !== undefined
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.shortcut || ""; font.pixelSize: 11
                        color: ThemeManager.textSecondaryColor; opacity: 0.7
                    }
                }

                MouseArea {
                    id: itemMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onContainsMouseChanged: if (containsMouse) root._highlightIndex = index
                    onClicked: {
                        var cmd = modelData
                        root.commandSelected(cmd)
                        if (typeof cmd.action === "function") cmd.action()
                        root.close()
                    }
                }
            }
        }

        // Footer hint
        Rectangle {
            visible: root._filtered.length > 0
            width: parent.width; height: 28
            color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.04)
            radius: 10
            Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 10; color: parent.color }
            Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: ThemeManager.borderColor }
            Text {
                anchors.centerIn: parent
                text: qsTr("↑↓ navigate  ·  ↵ select  ·  Esc close")
                font.pixelSize: 10; color: ThemeManager.textSecondaryColor; opacity: 0.6
            }
        }
    }
}

