import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import App.Icons 1.0

SpinBox {
    id: control

    property color accentColor: ThemeManager.primaryColor
    property color backgroundColor: Qt.rgba(1, 1, 1, 0.06)
    property color borderColor: Qt.rgba(1, 1, 1, 0.18)
    property string suffixText: ""
    property int radius: 6

    from: 0
    to: 100
    stepSize: 1
    editable: true
    font.pixelSize: 13
    implicitHeight: 36

    background: Rectangle {
        radius: control.radius
        color: control.backgroundColor
        border.width: 1
        border.color: control.activeFocus || control.hovered
                      ? control.accentColor
                      : control.borderColor
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    contentItem: TextInput {
        text: control.displayText + (control.suffixText ? " " + control.suffixText : "")
        font: control.font
        color: ThemeManager.textColor
        selectionColor: control.accentColor
        selectedTextColor: "#ffffff"
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter
        readOnly: !control.editable
        validator: control.validator
        inputMethodHints: Qt.ImhFormattedNumbersOnly
    }

    up.indicator: Rectangle {
        x: control.width - width
        height: control.height / 2
        width: 28
        color: control.up.pressed ? Qt.rgba(1, 1, 1, 0.12)
                                  : control.up.hovered ? Qt.rgba(1, 1, 1, 0.06)
                                                       : "transparent"
        radius: control.radius
        SvgIcon {
            anchors.centerIn: parent
            width: 14; height: 14
            source: Icons.plus
            color: ThemeManager.textColor
        }
    }

    down.indicator: Rectangle {
        x: control.width - width
        y: control.height / 2
        height: control.height / 2
        width: 28
        color: control.down.pressed ? Qt.rgba(1, 1, 1, 0.12)
                                    : control.down.hovered ? Qt.rgba(1, 1, 1, 0.06)
                                                           : "transparent"
        radius: control.radius
        SvgIcon {
            anchors.centerIn: parent
            width: 14; height: 14
            source: Icons.minus
            color: ThemeManager.textColor
        }
    }
}

