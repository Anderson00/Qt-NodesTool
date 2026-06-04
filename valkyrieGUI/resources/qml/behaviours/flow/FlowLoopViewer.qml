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

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 8; spacing: 6

        // Progress bar
        Rectangle {
            Layout.fillWidth: true; height: 36; radius: 8
            color: Qt.rgba(1, 0.6, 0, 0.06); border.width: 1; border.color: Qt.rgba(1,0.6,0,0.2)
            clip: true

            Rectangle {
                id: progressFill
                height: parent.height; radius: parent.radius
                color: Qt.rgba(1, 0.6, 0, 0.3)
                width: {
                    if (!behaviourObject || behaviourObject.iterations === 0) return 0
                    return parent.width * (behaviourObject.currentIteration / behaviourObject.iterations)
                }
                Behavior on width { NumberAnimation { duration: 80 } }
            }

            RowLayout {
                anchors.fill: parent; anchors.margins: 8
                Text {
                    text: behaviourObject ? (behaviourObject.currentIteration + " / " + behaviourObject.iterations) : "0 / 0"
                    font.pixelSize: 12; font.bold: true; font.family: "Consolas"; color: "#FF9800"
                    Layout.fillWidth: true
                }
                Rectangle {
                    width: 8; height: 8; radius: 4
                    color: behaviourObject && behaviourObject.isRunning ? "#FF9800" : "transparent"
                    border.width: 1; border.color: "#FF9800"
                    Behavior on color { ColorAnimation { duration: 150 } }
                    SequentialAnimation on opacity {
                        running: behaviourObject ? behaviourObject.isRunning : false
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.2; duration: 400 }
                        NumberAnimation { to: 1.0; duration: 400 }
                    }
                }
            }
        }

        // Iterations input
        NumericInputField {
            Layout.fillWidth: true; implicitHeight: 32
            label: qsTr("Iterations")
            value: behaviourObject ? behaviourObject.iterations : 3
            from: 1; to: 1000; stepSize: 1; decimals: 0; showBar: false
            accentColor: "#FF9800"
            onValueModified: function(v) { if (behaviourObject) behaviourObject.setIterations(v) }
        }

        // Controls
        RowLayout {
            Layout.fillWidth: true; spacing: 4

            Rectangle {
                Layout.fillWidth: true; height: 30; radius: 6
                color: runMa.containsMouse ? Qt.rgba(1,0.6,0,0.2) : Qt.rgba(1,0.6,0,0.1)
                border.width: 1; border.color: "#FF9800"
                Behavior on color { ColorAnimation { duration: 100 } }
                RowLayout { anchors.centerIn: parent; spacing: 4
                    SvgIcon { width: 11; height: 11; source: Icons.play; color: "#FF9800" }
                    Text { text: qsTr("Run"); font.pixelSize: 11; font.bold: true; color: "#FF9800" }
                }
                MouseArea { id: runMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: if (behaviourObject) behaviourObject.trigger() }
            }

            Rectangle {
                Layout.fillWidth: true; height: 30; radius: 6
                color: brkMa.containsMouse ? Qt.rgba(1,0.09,0.27,0.2) : Qt.rgba(1,0.09,0.27,0.08)
                border.width: 1; border.color: "#FF1744"
                Behavior on color { ColorAnimation { duration: 100 } }
                RowLayout { anchors.centerIn: parent; spacing: 4
                    SvgIcon { width: 11; height: 11; source: Icons.stop; color: "#FF1744" }
                    Text { text: qsTr("Break"); font.pixelSize: 11; font.bold: true; color: "#FF1744" }
                }
                MouseArea { id: brkMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: if (behaviourObject) behaviourObject.breakLoop() }
            }
        }
    }
}
