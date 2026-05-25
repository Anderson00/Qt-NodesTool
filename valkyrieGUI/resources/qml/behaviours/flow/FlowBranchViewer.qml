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

    SequentialAnimation on opacity {
        id: pulseAnim; running: false; loops: 1
        NumberAnimation { to: 0.4; duration: 60 }
        NumberAnimation { to: 1.0; duration: 120 }
    }
    Connections {
        target: behaviourObject
        function onExecTrue()  { pulseAnim.restart() }
        function onExecFalse() { pulseAnim.restart() }
    }

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 8; spacing: 6

        // Condition display
        Rectangle {
            Layout.fillWidth: true; height: 48; radius: 8
            color: {
                if (!behaviourObject) return "transparent"
                return behaviourObject.condition ? Qt.rgba(0, 0.78, 0.33, 0.1) : Qt.rgba(1, 0.09, 0.27, 0.1)
            }
            border.width: 1
            border.color: behaviourObject && behaviourObject.condition ? "#00C853" : "#FF1744"
            Behavior on color       { ColorAnimation { duration: 200 } }
            Behavior on border.color { ColorAnimation { duration: 200 } }

            RowLayout {
                anchors.centerIn: parent; spacing: 8
                Rectangle {
                    width: 12; height: 12; radius: 6
                    color: behaviourObject && behaviourObject.condition ? "#00C853" : "#FF1744"
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    text: behaviourObject && behaviourObject.condition ? "TRUE" : "FALSE"
                    font.pixelSize: 16; font.bold: true
                    color: behaviourObject && behaviourObject.condition ? "#00C853" : "#FF1744"
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        // Path indicator: true / false
        RowLayout {
            Layout.fillWidth: true; spacing: 4

            Rectangle {
                Layout.fillWidth: true; height: 32; radius: 6
                color: behaviourObject && behaviourObject.lastPath === 1 ? Qt.rgba(0, 0.78, 0.33, 0.2) : Qt.rgba(0, 0.78, 0.33, 0.05)
                border.width: 1; border.color: "#00C853"
                Behavior on color { ColorAnimation { duration: 150 } }
                RowLayout { anchors.centerIn: parent; spacing: 4
                    SvgIcon { width: 11; height: 11; source: Icons.play; color: "#00C853" }
                    Text { text: qsTr("TRUE"); font.pixelSize: 11; font.bold: true; color: "#00C853" }
                }
            }

            Rectangle {
                Layout.fillWidth: true; height: 32; radius: 6
                color: behaviourObject && behaviourObject.lastPath === 2 ? Qt.rgba(1, 0.09, 0.27, 0.2) : Qt.rgba(1, 0.09, 0.27, 0.05)
                border.width: 1; border.color: "#FF1744"
                Behavior on color { ColorAnimation { duration: 150 } }
                RowLayout { anchors.centerIn: parent; spacing: 4
                    SvgIcon { width: 11; height: 11; source: Icons.play; color: "#FF1744" }
                    Text { text: qsTr("FALSE"); font.pixelSize: 11; font.bold: true; color: "#FF1744" }
                }
            }
        }

        // Manual condition toggle
        RowLayout {
            Layout.fillWidth: true
            Text { text: qsTr("Condition"); font.pixelSize: 11; color: ThemeManager.textSecondaryColor; Layout.fillWidth: true }
            CustomSwitch {
                checked: behaviourObject ? behaviourObject.condition : false
                onToggled: if (behaviourObject) behaviourObject.setCondition(checked)
            }
        }
    }
}
