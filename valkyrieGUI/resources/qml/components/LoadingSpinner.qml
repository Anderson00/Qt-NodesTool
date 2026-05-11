import QtQuick 2.15
import App.Theme 1.0

// LoadingSpinner — animated circular arc spinner.
//
// Usage:
//   LoadingSpinner { size: 32; color: ThemeManager.primaryColor }
//   LoadingSpinner { size: 20; running: myTask.active }
Item {
    id: root

    property int    size:      32
    property color  color:     ThemeManager.primaryColor
    property int    thickness: Math.max(2, size * 0.1)
    property real   speed:     1.0    // multiplier; 1.0 = ~800ms per rotation
    property bool   running:   true
    property color  trackColor: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.25)

    implicitWidth:  root.size
    implicitHeight: root.size

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        property real _angle: 0
        property real _arc:   0.65   // fraction of circle drawn

        on_AngleChanged: canvas.requestPaint()

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var cx = width / 2, cy = height / 2
            var r  = (Math.min(width, height) - root.thickness) / 2

            // Track
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.strokeStyle = root.trackColor.toString()
            ctx.lineWidth   = root.thickness
            ctx.lineCap     = "round"
            ctx.stroke()

            // Arc
            var start = _angle - Math.PI / 2
            var end   = start + Math.PI * 2 * _arc
            ctx.beginPath()
            ctx.arc(cx, cy, r, start, end)
            ctx.strokeStyle = root.color.toString()
            ctx.lineWidth   = root.thickness
            ctx.lineCap     = "round"
            ctx.stroke()
        }

        NumberAnimation on _angle {
            running: root.running
            from: 0; to: Math.PI * 2
            duration: Math.round(800 / root.speed)
            loops: Animation.Infinite
        }
    }

    onRunningChanged: canvas.requestPaint()
    onColorChanged:   canvas.requestPaint()
    onSizeChanged:    canvas.requestPaint()
}

