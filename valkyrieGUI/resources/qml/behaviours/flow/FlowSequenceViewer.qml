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

        Text {
            text: "Fires steps 1 → 2 → 3 in order"
            font.pixelSize: 10; color: ThemeManager.textSecondaryColor
            Layout.fillWidth: true; wrapMode: Text.WordWrap
        }

        // Step indicators
        Repeater {
            model: 3
            delegate: Rectangle {
                Layout.fillWidth: true; height: 28; radius: 6
                property bool isActive: behaviourObject && behaviourObject.isRunning
                                        && behaviourObject.currentStep === (index + 1)
                color: isActive ? Qt.rgba(1, 0.6, 0, 0.25) : Qt.rgba(1, 0.6, 0, 0.06)
                border.width: 1
                border.color: isActive ? "#FF9800" : Qt.rgba(1, 0.6, 0, 0.2)
                Behavior on color       { ColorAnimation { duration: 100 } }
                Behavior on border.color { ColorAnimation { duration: 100 } }
                RowLayout {
                    anchors.fill: parent; anchors.margins: 8; spacing: 6
                    SvgIcon {
                        width: 11; height: 11; source: Icons.play; color: "#FF9800"
                        opacity: parent.parent.isActive ? 1.0 : 0.5
                    }
                    Text {
                        text: "Step " + (index + 1)
                        font.pixelSize: 11; font.bold: parent.parent.isActive; color: "#FF9800"
                        opacity: parent.parent.isActive ? 1.0 : 0.5
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: parent.parent.isActive ? "#FF9800" : "transparent"
                        border.width: 1; border.color: "#FF9800"; opacity: 0.7
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        Rectangle {
            Layout.fillWidth: true; height: 32; radius: 6
            color: trigMa.containsMouse ? Qt.rgba(1,0.6,0,0.2) : Qt.rgba(1,0.6,0,0.1)
            border.width: 1; border.color: "#FF9800"
            Behavior on color { ColorAnimation { duration: 100 } }
            RowLayout { anchors.centerIn: parent; spacing: 4
                SvgIcon { width: 11; height: 11; source: Icons.play; color: "#FF9800" }
                Text { text: "Run Sequence"; font.pixelSize: 11; font.bold: true; color: "#FF9800" }
            }
            MouseArea { id: trigMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: if (behaviourObject) behaviourObject.trigger() }
        }
    }
}
