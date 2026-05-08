import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import Qaterial 1.0 as Qaterial
import App.Theme 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 6

        // ── Pulse indicator ────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            radius: 6
            color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.2)

            RowLayout {
                anchors.centerIn: parent; spacing: 8

                Rectangle {
                    id: pulseDot
                    width: 14; height: 14; radius: 7
                    color: behaviourObject && behaviourObject.running ? "#00C853" : "#666"
                    Behavior on color { ColorAnimation { duration: 200 } }

                    SequentialAnimation on opacity {
                        running: behaviourObject && behaviourObject.running
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 300 }
                        NumberAnimation { to: 1.0; duration: 300 }
                    }
                }

                Text {
                    text: behaviourObject ? behaviourObject.tickCount : "0"
                    font.pixelSize: 22; font.family: "Consolas"; font.bold: true
                    color: ThemeManager.primaryColor
                }

                Text {
                    text: "ticks"
                    font.pixelSize: 10; color: ThemeManager.textSecondaryColor
                    anchors.baseline: parent.children[1] ? parent.children[1].baseline : undefined
                }
            }
        }

        // ── Interval input ─────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Text {
                text: "⏱"
                font.pixelSize: 14
                Layout.alignment: Qt.AlignVCenter
            }
            NumericInputField {
                Layout.fillWidth: true; implicitHeight: 36
                value: behaviourObject ? behaviourObject.interval : 1000
                from: 1; to: 60000
                stepSize: 50; decimals: 0
                suffix: "ms"
                showBar: true
                accentColor: ThemeManager.primaryColor
                onValueModified: if (behaviourObject) behaviourObject.setInterval(Math.round(newValue))
            }
        }

        // ── Control buttons ────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 4

            NewButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                variant: "filled"
                text: behaviourObject && behaviourObject.running ? "■ Stop" : "▶ Start"
                backgroundColor: behaviourObject && behaviourObject.running
                                 ? ThemeManager.dangerColor : ThemeManager.primaryColor
                onClicked: {
                    if (behaviourObject.running) behaviourObject.stopTimer()
                    else behaviourObject.startTimer()
                }
            }

            NewButton {
                Layout.preferredWidth: 56
                Layout.preferredHeight: 32
                variant: "outlined"
                text: "Pulse"
                backgroundColor: ThemeManager.primaryColor
                onClicked: behaviourObject.trigger()
            }
        }
    }
}
