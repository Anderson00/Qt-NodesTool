import QtQuick 2.15
import App.Theme 1.0

// Kbd — keyboard shortcut badge renderer.
//
// Renders one or more keys as styled badges (like HTML <kbd>).
//
// Usage:
//   Kbd { keys: "Ctrl+S" }               // auto-splits on + and Space
//   Kbd { keys: ["Ctrl", "Shift", "P"] } // explicit array
//   Kbd { keys: "↵ Enter" }
Item {
    id: root

    property var   keys:        []    // string or string array
    property int   fontSize:    11
    property color bgColor:     Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.08)
    property color borderColor: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.7)
    property color textColor:   ThemeManager.textColor
    property int   spacing:     4

    readonly property var _keyList: {
        if (typeof root.keys === "string") {
            // split "Ctrl+Shift+P" → ["Ctrl","Shift","P"]
            return root.keys.split("+").map(function(k) { return k.trim() }).filter(function(k) { return k.length > 0 })
        }
        return root.keys
    }

    implicitWidth:  krow.implicitWidth
    implicitHeight: krow.implicitHeight

    Row {
        id: krow
        spacing: root.spacing

        Repeater {
            model: root._keyList
            delegate: Row {
                spacing: root.spacing

                // "+" separator between keys
                Text {
                    visible: index > 0
                    text: "+"; font.pixelSize: root.fontSize
                    color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.4)
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    height: root.fontSize + 10
                    width: keyLabel.implicitWidth + 12
                    radius: 4
                    color: root.bgColor
                    border.color: root.borderColor; border.width: 1

                    // Bottom shadow line (classic kbd look)
                    Rectangle {
                        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                        height: 2; radius: 2
                        color: Qt.rgba(root.borderColor.r, root.borderColor.g, root.borderColor.b, 0.5)
                    }

                    Text {
                        id: keyLabel
                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: root.fontSize; font.family: "Consolas, monospace"
                        color: root.textColor
                    }
                }
            }
        }
    }
}

