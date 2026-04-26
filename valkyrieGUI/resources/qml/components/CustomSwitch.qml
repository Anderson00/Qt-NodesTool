import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0

Switch {
    id: control

    property color accentColor: ThemeManager.primaryColor
    property color trackOffColor: Qt.rgba(1, 1, 1, 0.18)
    property int trackWidth: 40
    property int trackHeight: 20

    font.pixelSize: 13

    indicator: Rectangle {
        implicitWidth: control.trackWidth
        implicitHeight: control.trackHeight
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        radius: height / 2
        color: control.checked ? control.accentColor : control.trackOffColor

        Behavior on color { ColorAnimation { duration: 150 } }

        Rectangle {
            id: handle
            width: parent.height - 4
            height: width
            radius: width / 2
            y: 2
            x: control.checked ? parent.width - width - 2 : 2
            color: "#ffffff"

            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }

            // Subtle shadow
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(0, 0, 0, 0.12)
            }
        }
    }

    contentItem: Text {
        text: control.text
        font: control.font
        color: ThemeManager.textColor
        verticalAlignment: Text.AlignVCenter
        leftPadding: control.indicator.width + 8
    }
}
