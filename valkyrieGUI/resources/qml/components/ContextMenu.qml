import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0

// ContextMenu — right-click / long-press popup menu.
//
// Usage:
//   ContextMenu {
//       id: ctxMenu
//       items: [
//           { label: "Copy",   icon: "content-copy" },
//           { label: "Paste",  icon: "content-paste" },
//           { separator: true },
//           { label: "Delete", icon: "trash-can", danger: true }
//       ]
//       onItemSelected: function(idx, item) { console.log(item.label) }
//   }
//
//   // Open at cursor: ctxMenu.openAt(mouseX, mouseY)
//   MouseArea { acceptedButtons: Qt.RightButton; onClicked: ctxMenu.openAt(mouse.x, mouse.y) }
Popup {
    id: root

    property var items: []

    signal itemSelected(int index, var item)

    function openAt(x, y) {
        root.x = x; root.y = y; root.open()
    }

    width: 200
    padding: 4
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    enter:  Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 100 } }
    exit:   Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 80  } }

    background: Rectangle {
        radius: 8; color: ThemeManager.surfaceColor
        border.color: ThemeManager.borderColor; border.width: 1
        layer.enabled: true
        layer.effect: null
        // Simulated drop shadow via border opacity
    }

    contentItem: Column {
        spacing: 0

        Repeater {
            model: root.items
            delegate: Item {
                width: root.width - 8
                height: modelData.separator ? 9 : 34

                // Separator
                Rectangle {
                    visible: modelData.separator === true
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.right: parent.right; anchors.margins: 6
                    height: 1; color: ThemeManager.borderColor; opacity: 0.5
                }

                // Menu item
                Rectangle {
                    visible: !modelData.separator
                    anchors.fill: parent; radius: 5
                    color: itemMa.containsMouse
                           ? (modelData.danger ? Qt.rgba(ThemeManager.dangerColor.r, ThemeManager.dangerColor.g, ThemeManager.dangerColor.b, 0.12)
                                               : Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.10))
                           : "transparent"
                    Behavior on color { ColorAnimation { duration: 80 } }

                    Row {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
                        spacing: 8
                        anchors.verticalCenter: undefined

                        Text {
                            visible: modelData.icon !== undefined && modelData.icon !== ""
                            text: modelData.icon || ""; font.pixelSize: 14
                            color: modelData.danger ? ThemeManager.dangerColor : ThemeManager.textSecondaryColor
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: modelData.label || ""
                            font.pixelSize: 13
                            color: modelData.danger ? ThemeManager.dangerColor : ThemeManager.textColor
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Item { width: 1; height: 1 } // spacer

                        Text {
                            visible: modelData.shortcut !== undefined
                            text: modelData.shortcut || ""; font.pixelSize: 11
                            color: ThemeManager.textSecondaryColor; opacity: 0.7
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: itemMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.itemSelected(index, modelData)
                            root.close()
                        }
                    }
                }
            }
        }
    }
}
