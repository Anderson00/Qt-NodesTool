import QtQuick 2.12
import App.Theme 1.0
import App.Widgets 1.0

// SGG-based drop-in replacement for ViewportGridCanvas.qml.
// Same public interface (panX, panY, zoom, minWgrid, pattern, canvasWidth,
// canvasHeight), same visual output. Tick labels and boundary glyphs are
// rendered as QML Text items on top of the C++ geometry layer.
Item {
    id: root

    property real   panX:         0
    property real   panY:         0
    property real   zoom:         1
    property real   canvasWidth:  10000
    property real   canvasHeight: 10000
    property int    minWgrid:     20
    property string pattern:      "dots"

    z: 0

    // ── C++ SGG renderer ─────────────────────────────────────────────────────
    ViewportGridItem {
        id: gridItem
        anchors.fill:  parent
        panX:          root.panX
        panY:          root.panY
        zoom:          root.zoom
        minWgrid:      root.minWgrid
        pattern:       root.pattern
        canvasWidth:   root.canvasWidth
        canvasHeight:  root.canvasHeight
        primaryColor:  ThemeManager.primaryColor
    }

    Connections {
        target: ThemeManager
        function onThemeChanged() { gridItem.primaryColor = ThemeManager.primaryColor }
    }

    // ── X-axis tick labels ────────────────────────────────────────────────────
    Repeater {
        model: gridItem.xAxisTicks
        Text {
            x: modelData.screenX - width / 2
            y: gridItem.axisXScreenY - 14
            text:  modelData.label
            color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
                           ThemeManager.primaryColor.b, 0.38)
            font { pixelSize: 9; family: "sans-serif" }
            visible: gridItem.axisXScreenY >= 0
        }
    }

    // ── Y-axis tick labels ────────────────────────────────────────────────────
    Repeater {
        model: gridItem.yAxisTicks
        Text {
            x: gridItem.axisYScreenX + 13
            y: modelData.screenY - height / 2
            text:  modelData.label
            color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
                           ThemeManager.primaryColor.b, 0.38)
            font { pixelSize: 9; family: "sans-serif" }
            visible: gridItem.axisYScreenX >= 0
        }
    }

    // ── Workspace boundary corner glyphs ──────────────────────────────────────
    Repeater {
        model: gridItem.boundaryCorners
        Text {
            x: modelData.x
            y: modelData.y
            text:  modelData.symbol
            color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
                           ThemeManager.primaryColor.b, 0.40)
            font { pixelSize: 10; family: "sans-serif" }
        }
    }
}

