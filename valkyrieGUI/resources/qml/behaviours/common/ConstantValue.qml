import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import App.Icons 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    readonly property var modeNames: ["Number", "Text", "Bool"]
    readonly property var modeIcons: [
        Icons.numeric,
        Icons.formatText,
        Icons.toggleSwitch
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // ── Mode selector (pill tabs) ─────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 28; radius: 4
            color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.04)
            clip: true

            Row {
                anchors.fill: parent; spacing: 0
                Repeater {
                    model: root.modeNames
                    delegate: Rectangle {
                        width: parent.width / root.modeNames.length; height: 28; radius: 4
                        color: behaviourObject && behaviourObject.mode === index ? ThemeManager.primaryColor : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Column {
                            anchors.centerIn: parent; spacing: 1
                            ColorIcon {
                                source: root.modeIcons[index]; width: 12; height: 12
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: behaviourObject && behaviourObject.mode === index ? ThemeManager.backgroundColor : ThemeManager.textColor
                                opacity: behaviourObject && behaviourObject.mode === index ? 1.0 : 0.5
                            }
                            Text {
                                text: modelData; font.pixelSize: 8
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: behaviourObject && behaviourObject.mode === index ? ThemeManager.backgroundColor : ThemeManager.textColor
                                opacity: behaviourObject && behaviourObject.mode === index ? 1.0 : 0.4
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: behaviourObject.setMode(index)
                        }
                    }
                }
            }
        }

        // ── Value display ─────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            radius: 6
            color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.2)

            // Numeric
            TextInput {
                anchors.fill: parent; anchors.margins: 6
                visible: behaviourObject && behaviourObject.mode === 0
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                font.pixelSize: 20; font.family: "Consolas"; font.bold: true
                color: ThemeManager.primaryColor
                text: behaviourObject ? behaviourObject.numericValue : "0"
                selectByMouse: true
                onAccepted: { var v = parseFloat(text); if(!isNaN(v)) behaviourObject.setNumericValue(v) }
            }

            // Text
            TextInput {
                anchors.fill: parent; anchors.margins: 6
                visible: behaviourObject && behaviourObject.mode === 1
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                font.pixelSize: 14; font.family: "Consolas"
                color: ThemeManager.primaryColor
                text: behaviourObject ? behaviourObject.textValue : ""
                selectByMouse: true
                onAccepted: behaviourObject.setTextValue(text)
            }

            // Bool
            Row {
                anchors.centerIn: parent; spacing: 8
                visible: behaviourObject && behaviourObject.mode === 2
                Rectangle {
                    width: 18; height: 18; radius: 9
                    color: behaviourObject && behaviourObject.boolValue ? "#00C853" : "#FF1744"
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    text: behaviourObject && behaviourObject.boolValue ? "TRUE" : "FALSE"
                    font.pixelSize: 16; font.bold: true; anchors.verticalCenter: parent.verticalCenter
                    color: behaviourObject && behaviourObject.boolValue ? "#00C853" : "#FF1744"
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: behaviourObject.setBoolValue(!behaviourObject.boolValue)
                }
            }
        }

        // ── Send button ───────────────────────────────────────────────────
        NewButton {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            variant: "filled"
            text: "⚡ Send"
            backgroundColor: ThemeManager.primaryColor
            onClicked: behaviourObject.send()
        }
    }
}
