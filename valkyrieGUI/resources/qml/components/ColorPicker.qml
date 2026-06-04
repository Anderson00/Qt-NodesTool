import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
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
                onClicked: colorPopup.open()
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

    Popup {
        id: colorPopup
        width: 340
        height: 420
        modal: false
        focus: true
        padding: 0
        z: 10000

        background: Rectangle {
            color: ThemeManager.backgroundColor
            border.color: ThemeManager.borderColor
            border.width: 1
            radius: 8
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Hue Slider Bar
            Rectangle {
                id: hueBar
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                radius: 4
                clip: true

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.hsla(0.0, 1, 0.5, 1) }
                    GradientStop { position: 0.167; color: Qt.hsla(0.167, 1, 0.5, 1) }
                    GradientStop { position: 0.333; color: Qt.hsla(0.333, 1, 0.5, 1) }
                    GradientStop { position: 0.5; color: Qt.hsla(0.5, 1, 0.5, 1) }
                    GradientStop { position: 0.667; color: Qt.hsla(0.667, 1, 0.5, 1) }
                    GradientStop { position: 0.833; color: Qt.hsla(0.833, 1, 0.5, 1) }
                    GradientStop { position: 1.0; color: Qt.hsla(1.0, 1, 0.5, 1) }
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed:         colorPopup.currentHue = Math.max(0, Math.min(360, (mouse.x / width) * 360))
                    onPositionChanged: colorPopup.currentHue = Math.max(0, Math.min(360, (mouse.x / width) * 360))
                    onClicked:         colorPopup.currentHue = Math.max(0, Math.min(360, (mouse.x / width) * 360))
                }

                Rectangle {
                    id: hueIndicator
                    width: 3
                    height: parent.height
                    color: "#ffffff"
                    border.color: "#000000"
                    border.width: 1
                    x: (colorPopup.currentHue / 360) * parent.width - width / 2
                }
            }

            // Color Gradient Selector (HSV model)
            Rectangle {
                id: colorGradient
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 4
                clip: true
                // Base: pure hue at full saturation and full value
                color: Qt.hsva(colorPopup.currentHue / 360, 1, 1, 1)

                // White left → transparent right (reduces saturation)
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#ffffffff" }
                        GradientStop { position: 1.0; color: "#00ffffff" }
                    }
                }

                // Transparent top → black bottom (reduces value)
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: "#00000000" }
                        GradientStop { position: 1.0; color: "#ff000000" }
                    }
                }

                MouseArea {
                    anchors.fill: parent

                    function updateFromMouse(mx, my) {
                        var sat = Math.max(0, Math.min(1, mx / width))
                        var val = 1 - Math.max(0, Math.min(1, my / height))
                        colorPopup.selectorX = sat
                        colorPopup.selectorY = 1 - val
                        colorPopup.selectedColor = Qt.hsva(colorPopup.currentHue / 360, sat, val, 1)
                    }

                    onPressed:         updateFromMouse(mouse.x, mouse.y)
                    onPositionChanged: updateFromMouse(mouse.x, mouse.y)
                    onClicked:         updateFromMouse(mouse.x, mouse.y)
                }

                Rectangle {
                    id: colorSelector
                    width: 12
                    height: 12
                    radius: 6
                    color: "transparent"
                    border.color: "#ffffff"
                    border.width: 2
                    x: (colorGradient.width * colorPopup.selectorX) - width / 2
                    y: (colorGradient.height * colorPopup.selectorY) - height / 2
                }
            }

            // Preview and Hex Input
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    id: colorPreview
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 50
                    color: colorPopup.selectedColor
                    border.color: root.borderColor
                    border.width: 1
                    radius: 4
                }

                TextField {
                    id: hexInput
                    Layout.fillWidth: true
                    text: colorPopup.selectedColor.toString().toUpperCase()
                    font.pixelSize: 12
                    color: ThemeManager.textColor
                    background: Rectangle {
                        radius: 4
                        color: Qt.rgba(1, 1, 1, 0.06)
                        border.color: root.borderColor
                        border.width: 1
                    }
                    onEditingFinished: {
                        var t = text.startsWith("#") ? text : "#" + text
                        try {
                            colorPopup.selectedColor = t
                        } catch(e) {}
                    }
                }
            }

            // Buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                spacing: 8

                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    text: qsTr("CANCEL")
                    font.pixelSize: 12
                    font.bold: true
                    onClicked: colorPopup.close()

                    background: Rectangle {
                        color: parent.pressed ? Qt.rgba(1, 1, 1, 0.08) : (parent.hovered ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(1, 1, 1, 0.04))
                        border.color: root.borderColor
                        border.width: 1
                        radius: 4
                    }

                    contentItem: Text {
                        text: parent.text
                        color: ThemeManager.textColor
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    text: qsTr("OK")
                    font.pixelSize: 12
                    font.bold: true

                    background: Rectangle {
                        color: parent.pressed ? Qt.darker(ThemeManager.primaryColor, 1.2) : (parent.hovered ? Qt.lighter(ThemeManager.primaryColor, 1.1) : ThemeManager.primaryColor)
                        radius: 4
                    }

                    contentItem: Text {
                        text: parent.text
                        color: "#ffffff"
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        root.value = colorPopup.selectedColor
                        root.accepted(root.value)
                        hexField.text = root.value.toString().toUpperCase()
                        colorPopup.close()
                    }
                }
            }
        }

        property color selectedColor: root.value
        property real currentHue: 0
        property real selectorX: 0.5
        property real selectorY: 0.5

        onCurrentHueChanged: {
            selectedColor = Qt.hsva(currentHue / 360, selectorX, 1 - selectorY, 1)
        }

        onOpenedChanged: {
            if (opened) {
                var c = root.value
                // Initialize selector from the pre-selected color (HSV decomposition)
                selectorX = c.hsvSaturation
                selectorY = 1 - c.hsvValue
                currentHue = (c.hsvHue < 0 ? 0 : c.hsvHue) * 360
                selectedColor = c
            }
        }
    }
}

