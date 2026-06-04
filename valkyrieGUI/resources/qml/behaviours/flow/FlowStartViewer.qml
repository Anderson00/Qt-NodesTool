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

    // Pulse animation on trigger
    SequentialAnimation on opacity {
        id: pulseAnim
        running: false; loops: 1
        NumberAnimation { to: 0.4; duration: 60 }
        NumberAnimation { to: 1.0; duration: 120 }
    }

    Connections {
        target: behaviourObject
        function onExecOut() { pulseAnim.restart() }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        // Auto-start toggle
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: qsTr("Auto Start")
                font.pixelSize: 11
                color: ThemeManager.textSecondaryColor
                Layout.fillWidth: true
            }
            CustomSwitch {
                checked: behaviourObject ? behaviourObject.autoStart : false
                onToggled: if (behaviourObject) behaviourObject.setAutoStart(checked)
            }
        }

        // Run count
        Rectangle {
            Layout.fillWidth: true; height: 36; radius: 6
            color: Qt.rgba(1, 0.6, 0, 0.08)
            border.width: 1; border.color: Qt.rgba(1, 0.6, 0, 0.3)
            RowLayout {
                anchors.fill: parent; anchors.margins: 8
                Text {
                    text: qsTr("Runs")
                    font.pixelSize: 11; color: ThemeManager.textSecondaryColor
                    Layout.fillWidth: true
                }
                Text {
                    text: behaviourObject ? behaviourObject.runCount : "0"
                    font.pixelSize: 16; font.bold: true; font.family: "Consolas"
                    color: "#FF9800"
                }
            }
        }

        // Trigger button
        Rectangle {
            Layout.fillWidth: true; height: 40; radius: 8
            color: runMa.containsMouse ? Qt.rgba(1, 0.6, 0, 0.25) : Qt.rgba(1, 0.6, 0, 0.15)
            border.width: 1; border.color: "#FF9800"
            Behavior on color { ColorAnimation { duration: 120 } }

            RowLayout {
                anchors.centerIn: parent; spacing: 6
                SvgIcon { width: 16; height: 16; source: Icons.play; color: "#FF9800" }
                Text { text: qsTr("Trigger"); font.pixelSize: 13; font.bold: true; color: "#FF9800" }
            }

            MouseArea {
                id: runMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: if (behaviourObject) behaviourObject.trigger()
            }
        }
    }
}
