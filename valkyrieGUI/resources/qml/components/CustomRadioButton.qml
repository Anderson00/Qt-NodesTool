import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0

RadioButton {
    id: control

    property color accentColor: ThemeManager.primaryColor
    property color borderColor: Qt.rgba(1, 1, 1, 0.4)
    property int circleSize: 18

    font.pixelSize: 13

    indicator: Rectangle {
        implicitWidth: control.circleSize
        implicitHeight: control.circleSize
        anchors.left: parent.left
        anchors.leftMargin: control.leftPadding
        anchors.verticalCenter: parent.verticalCenter
        radius: width / 2
        border.width: 2
        border.color: control.checked || control.hovered
                      ? control.accentColor
                      : control.borderColor
        color: "transparent"

        Behavior on border.color { ColorAnimation { duration: 120 } }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.55
            height: width
            radius: width / 2
            color: control.accentColor
            scale: control.checked ? 1.0 : 0.0
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
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

