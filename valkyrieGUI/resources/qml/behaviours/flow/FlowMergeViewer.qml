import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    SequentialAnimation on opacity {
        id: pulseAnim; running: false; loops: 1
        NumberAnimation { to: 0.4; duration: 60 }
        NumberAnimation { to: 1.0; duration: 120 }
    }
    Connections {
        target: behaviourObject
        function onExecOut() { pulseAnim.restart() }
    }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 8; spacing: 6

        // Source indicators
        Repeater {
            model: ["A", "B", "C"]
            delegate: Rectangle {
                Layout.fillWidth: true; height: 28; radius: 6
                property bool isLast: behaviourObject && behaviourObject.lastSource === modelData
                color: isLast ? Qt.rgba(1, 0.6, 0, 0.2) : Qt.rgba(1, 0.6, 0, 0.05)
                border.width: 1; border.color: isLast ? "#FF9800" : Qt.rgba(1,0.6,0,0.2)
                Behavior on color       { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }
                Text {
                    anchors.centerIn: parent
                    text: "Trigger " + modelData + (parent.isLast ? "  ◀ last" : "")
                    font.pixelSize: 11; font.bold: parent.isLast; color: "#FF9800"
                    opacity: parent.isLast ? 1.0 : 0.45
                }
            }
        }

        // Total count
        Rectangle {
            Layout.fillWidth: true; height: 32; radius: 6
            color: Qt.rgba(1, 0.6, 0, 0.06); border.width: 1; border.color: Qt.rgba(1,0.6,0,0.2)
            RowLayout {
                anchors.fill: parent; anchors.margins: 8
                Text { text: "Total merges"; font.pixelSize: 11; color: ThemeManager.textSecondaryColor; Layout.fillWidth: true }
                Text {
                    text: behaviourObject ? behaviourObject.mergeCount : "0"
                    font.pixelSize: 14; font.bold: true; font.family: "Consolas"; color: "#FF9800"
                }
            }
        }
    }
}
