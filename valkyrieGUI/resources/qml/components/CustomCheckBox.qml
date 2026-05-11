import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0

CheckBox {
    id: control

    property color accentColor: ThemeManager.primaryColor
    property color borderColor: Qt.rgba(1, 1, 1, 0.4)
    property int boxSize: 18
    property int boxRadius: 4

    font.pixelSize: 13

    indicator: Rectangle {
        implicitWidth: control.boxSize
        implicitHeight: control.boxSize
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        radius: control.boxRadius
        border.width: 2
        border.color: control.checked || control.hovered
                      ? control.accentColor
                      : control.borderColor
        color: control.checked ? control.accentColor : "transparent"

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        // Check mark
        Canvas {
            anchors.fill: parent
            anchors.margins: 3
            visible: control.checkState === Qt.Checked
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.strokeStyle = "#ffffff"
                ctx.lineWidth = 2
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                ctx.beginPath()
                ctx.moveTo(width * 0.15, height * 0.55)
                ctx.lineTo(width * 0.42, height * 0.80)
                ctx.lineTo(width * 0.88, height * 0.22)
                ctx.stroke()
            }
        }

        // Tri-state indicator
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.55
            height: 2
            radius: 1
            color: "#ffffff"
            visible: control.checkState === Qt.PartiallyChecked
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

