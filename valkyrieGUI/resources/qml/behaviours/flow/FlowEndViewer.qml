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
        NumberAnimation { to: 0.3; duration: 80 }
        NumberAnimation { to: 1.0; duration: 150 }
    }
    Connections {
        target: behaviourObject
        function onTriggered() { pulseAnim.restart() }
    }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 8; spacing: 8

        // Hit counter
        Rectangle {
            Layout.fillWidth: true; height: 48; radius: 8
            color: Qt.rgba(1, 0.09, 0.27, 0.08)
            border.width: 1; border.color: Qt.rgba(1, 0.09, 0.27, 0.3)

            ColumnLayout {
                anchors.centerIn: parent; spacing: 2
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: behaviourObject ? behaviourObject.hitCount : "0"
                    font.pixelSize: 22; font.bold: true; font.family: "Consolas"
                    color: "#FF1744"
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: qsTr("times reached")
                    font.pixelSize: 9; color: ThemeManager.textSecondaryColor
                }
            }
        }

        // Reset button
        Rectangle {
            Layout.fillWidth: true; height: 28; radius: 6
            color: rstMa.containsMouse ? Qt.rgba(0.5,0.5,0.5,0.15) : Qt.rgba(0.5,0.5,0.5,0.06)
            border.width: 1; border.color: Qt.rgba(0.5,0.5,0.5,0.3)
            Behavior on color { ColorAnimation { duration: 100 } }
            Text { anchors.centerIn: parent; text: qsTr("Reset counter"); font.pixelSize: 10; color: ThemeManager.textSecondaryColor }
            MouseArea { id: rstMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: if (behaviourObject) behaviourObject.reset() }
        }
    }
}
