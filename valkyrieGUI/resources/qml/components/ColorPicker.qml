import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import App.Theme 1.0

Item {
    id: root

    property color value: "#ffffff"
    property string label: ""
    property bool showHex: true
    property color borderColor: Qt.rgba(1, 1, 1, 0.18)
    property int radius: 6

    signal accepted(color color)

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: 36

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 8

        Text {
            visible: root.label !== ""
            text: root.label
            color: ThemeManager.textColor
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
        }

        Rectangle {
            id: swatch
            Layout.preferredWidth: 36
            Layout.fillHeight: true
            radius: root.radius
            color: root.value
            border.width: 1
            border.color: root.borderColor

            // Checkered background to show transparency
            Item {
                anchors.fill: parent
                anchors.margins: 1
                clip: true
                Grid {
                    anchors.fill: parent
                    rows: 4; columns: 4
                    Repeater {
                        model: 16
                        Rectangle {
                            width: swatch.width / 4
                            height: swatch.height / 4
                            color: ((index + Math.floor(index / 4)) % 2 === 0)
                                   ? "#cccccc" : "#ffffff"
                        }
                    }
                }
                Rectangle { anchors.fill: parent; color: root.value }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: dialog.open()
            }
        }

        TextField {
            id: hexField
            visible: root.showHex
            Layout.preferredWidth: 110
            Layout.fillHeight: true
            text: root.value.toString().toUpperCase()
            font.pixelSize: 13
            color: ThemeManager.textColor
            selectionColor: ThemeManager.primaryColor
            selectedTextColor: "#ffffff"
            background: Rectangle {
                radius: root.radius
                color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1
                border.color: hexField.activeFocus
                              ? ThemeManager.primaryColor
                              : root.borderColor
            }
            validator: RegularExpressionValidator {
                regularExpression: /^#?[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$/
            }
            onEditingFinished: {
                var t = text.startsWith("#") ? text : "#" + text
                root.value = t
                root.accepted(root.value)
            }
        }
    }

    ColorDialog {
        id: dialog
        selectedColor: root.value
        onAccepted: {
            root.value = selectedColor
            root.accepted(root.value)
        }
    }
}
