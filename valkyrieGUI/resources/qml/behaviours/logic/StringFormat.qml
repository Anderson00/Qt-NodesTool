import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import App.Theme 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // ── Template input ─────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true; spacing: 2
            Text { text: "Template"; font.pixelSize: 9; color: ThemeManager.textSecondaryColor }
            Rectangle {
                Layout.fillWidth: true; height: 32; radius: 4
                color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.05)
                border.width: 1
                border.color: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.3)
                TextInput {
                    anchors.fill: parent; anchors.margins: 6
                    verticalAlignment: TextInput.AlignVCenter
                    font.pixelSize: 11; font.family: "Consolas"
                    color: ThemeManager.textColor
                    text: behaviourObject ? behaviourObject.templateStr : ""
                    selectByMouse: true
                    onAccepted:   behaviourObject.setTemplate(text)
                    onTextEdited: behaviourObject.setTemplate(text)
                }
            }
            Text {
                text: "Use {A}, {B}, {C} as placeholders"
                font.pixelSize: 8; color: ThemeManager.textSecondaryColor; opacity: 0.6
            }
        }

        // ── Result preview ─────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 46; radius: 6
            color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.2)

            Column {
                anchors.centerIn: parent; spacing: 2
                Text { text: "Result"; font.pixelSize: 8; color: ThemeManager.textSecondaryColor; anchors.horizontalCenter: parent.horizontalCenter }
                Text {
                    text: behaviourObject ? behaviourObject.resultStr : ""
                    font.pixelSize: 12; font.family: "Consolas"; font.bold: true
                    color: ThemeManager.primaryColor
                    anchors.horizontalCenter: parent.horizontalCenter
                    elide: Text.ElideRight; width: root.width - 24
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // ── Precision selector (pill buttons) ──────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 4

            Text {
                text: ".0"
                font.pixelSize: 9; color: ThemeManager.textSecondaryColor
                Layout.alignment: Qt.AlignVCenter
            }

            Rectangle {
                Layout.fillWidth: true; height: 28; radius: 4
                color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.04)
                clip: true

                Row {
                    anchors.fill: parent; spacing: 0
                    Repeater {
                        model: 9   // 0 .. 8 decimal places
                        delegate: Rectangle {
                            width: parent.width / 9; height: 28; radius: 4
                            property int dec: index
                            property bool active: behaviourObject && behaviourObject.precision === dec
                            color: active ? ThemeManager.primaryColor : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text {
                                anchors.centerIn: parent
                                text: dec; font.pixelSize: 9; font.bold: active
                                color: active ? ThemeManager.backgroundColor : ThemeManager.textColor
                                opacity: active ? 1.0 : 0.5
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: if (behaviourObject) behaviourObject.setPrecision(dec)
                            }
                        }
                    }
                }
            }
        }
    }
}

