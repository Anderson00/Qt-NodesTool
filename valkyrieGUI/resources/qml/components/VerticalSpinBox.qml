import QtQuick 2.15
import QtQuick.Layouts 1.15
import App.Theme 1.0

Rectangle {
    id: root
    property int from: 0
    property int to: 999
    property int value: 0
    
    signal valueModified(int newValue)
    
    Layout.preferredWidth: 54
    Layout.preferredHeight: 70
    radius: 6
    color: Qt.rgba(1, 1, 1, 0.05)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.12)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Up
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 22; radius: 5
            color: upA.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
            Text { anchors.centerIn: parent; text: "▲"; font.pixelSize: 9; color: ThemeManager.textSecondaryColor }
            MouseArea {
                id: upA; anchors.fill: parent; hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.value < root.to) {
                        root.value++
                        root.valueModified(root.value)
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: String(root.value).padStart(2, "0")
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 20; font.bold: true; font.family: "Consolas"
            color: ThemeManager.textColor
        }

        // Down
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 22; radius: 5
            color: downA.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
            Text { anchors.centerIn: parent; text: "▼"; font.pixelSize: 9; color: ThemeManager.textSecondaryColor }
            MouseArea {
                id: downA; anchors.fill: parent; hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.value > root.from) {
                        root.value--
                        root.valueModified(root.value)
                    }
                }
            }
        }
    }
}
