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

        // ── Gate status indicator ─────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 56; radius: 6
            color: {
                if(!behaviourObject) return "transparent"
                return behaviourObject.gateOpen
                    ? Qt.rgba(0, 0.78, 0.33, 0.1)
                    : Qt.rgba(1, 0.09, 0.27, 0.1)
            }
            border.width: 1
            border.color: behaviourObject && behaviourObject.gateOpen ? "#00C853" : "#FF1744"

            RowLayout {
                anchors.centerIn: parent; spacing: 10
                Qaterial.ColorIcon {
                    source: behaviourObject && behaviourObject.gateOpen
                            ? Qaterial.Icons.lockOpenVariant
                            : Qaterial.Icons.lock
                    width: 22; height: 22
                    color: behaviourObject && behaviourObject.gateOpen ? "#00C853" : "#FF1744"
                }
                Text {
                    text: behaviourObject && behaviourObject.gateOpen ? "OPEN" : "CLOSED"
                    font.pixelSize: 18; font.bold: true
                    color: behaviourObject && behaviourObject.gateOpen ? "#00C853" : "#FF1744"
                }
            }

            MouseArea {
                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                onClicked: behaviourObject.toggle()
            }
        }

        // ── Stats bar ─────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 4
            Rectangle {
                Layout.fillWidth: true; height: 28; radius: 3
                color: Qt.rgba(0, 0.78, 0.33, 0.08)
                Column {
                    anchors.centerIn: parent; spacing: 0
                    Text {
                        text: behaviourObject ? behaviourObject.passCount : "0"
                        font.pixelSize: 11; font.bold: true; color: "#00C853"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "passed"; font.pixelSize: 7; color: "#00C853"; opacity: 0.6
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
            Rectangle {
                Layout.fillWidth: true; height: 28; radius: 3
                color: Qt.rgba(1, 0.09, 0.27, 0.08)
                Column {
                    anchors.centerIn: parent; spacing: 0
                    Text {
                        text: behaviourObject ? behaviourObject.blockCount : "0"
                        font.pixelSize: 11; font.bold: true; color: "#FF1744"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: "blocked"; font.pixelSize: 7; color: "#FF1744"; opacity: 0.6
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }

        // ── Toggle button ─────────────────────────────────────────────────
        NewButton {
            Layout.fillWidth: true; Layout.preferredHeight: 32
            variant: "filled"
            text: behaviourObject && behaviourObject.gateOpen ? "Close Gate" : "Open Gate"
            backgroundColor: behaviourObject && behaviourObject.gateOpen ? ThemeManager.dangerColor : "#00C853"
            onClicked: behaviourObject.toggle()
        }
    }
}
