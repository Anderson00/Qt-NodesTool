import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0

// ProgressCircle — circular progress ring with label.
//
// Usage:
//   ProgressCircle { value: 0.72; size: 80; showLabel: true }
Item {
    id: root

    property real   value:        0.0         // 0.0 to 1.0
    property int    size:         64
    property int    strokeWidth:  6
    property bool   showLabel:    true
    property string label:        ""          // empty = percentage
    property string sublabel:     ""
    property color  progressColor: ThemeManager.primaryColor
    property color  trackColor:   Qt.rgba(ThemeManager.textColor.r,
                                          ThemeManager.textColor.g,
                                          ThemeManager.textColor.b, 0.1)
    property bool   animated:     true
    property int    animDuration: 500

    implicitWidth:  root.size
    implicitHeight: root.size

    property real _displayValue: 0
    Behavior on _displayValue { enabled: root.animated; NumberAnimation { duration: root.animDuration; easing.type: Easing.OutCubic } }
    onValueChanged: _displayValue = value
    Component.onCompleted: _displayValue = value

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var cx = width / 2, cy = height / 2
            var r  = (Math.min(width, height) / 2) - root.strokeWidth / 2
            var startAngle = -Math.PI / 2
            var endAngle   = startAngle + 2 * Math.PI * root._displayValue

            // Track
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, 2 * Math.PI)
            ctx.strokeStyle = root.trackColor.toString()
            ctx.lineWidth = root.strokeWidth
            ctx.lineCap  = "round"
            ctx.stroke()

            // Progress arc
            if (root._displayValue > 0) {
                ctx.beginPath()
                ctx.arc(cx, cy, r, startAngle, endAngle)
                ctx.strokeStyle = root.progressColor.toString()
                ctx.lineWidth   = root.strokeWidth
                ctx.lineCap     = "round"
                ctx.stroke()
            }
        }

        Connections {
            target: root
            function on_DisplayValueChanged() { canvas.requestPaint() }
        }
        Connections {
            target: ThemeManager
            function onThemeChanged() { canvas.requestPaint() }
        }
    }

    // Center labels
    Column {
        anchors.centerIn: parent
        spacing: 1

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.showLabel
            text: root.label !== "" ? root.label : Math.round(root._displayValue * 100) + "%"
            font.pixelSize: root.size * 0.22; font.bold: true
            color: ThemeManager.textColor
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.sublabel !== ""
            text: root.sublabel
            font.pixelSize: root.size * 0.13
            color: ThemeManager.textSecondaryColor
        }
    }
}

