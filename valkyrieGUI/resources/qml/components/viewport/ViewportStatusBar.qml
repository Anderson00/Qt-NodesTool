import QtQuick 2.12
import QtQuick.Layouts 1.0
import App.Theme 1.0
import App.Log 1.0

// Slim status bar showing view center, mouse world position, zoom,
// selected node name and total node count.
Rectangle {
    id: root

    // mycanvas position in viewport coordinates
    property real canvasPosX: 0
    property real canvasPosY: 0

    // containerCanvas dimensions
    property real containerWidth:  0
    property real containerHeight: 0

    // Current zoom factor
    property real zoom: 1

    // Mouse position in viewport coordinates (from HoverHandler.point.position)
    property real hoverX: 0
    property real hoverY: 0

    // Currently focused node (may be null)
    property var nodeOnFocus: null

    // Total number of nodes on the canvas
    property int nodeCount: 0

    // FPS Counter
    property int fpsCount: 0
    property bool showFps: false

    height: 22
    color: Qt.darker(ThemeManager.backgroundColor, 1.55)

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: ThemeManager.primaryColor
        opacity: 0.22
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 0

        // ── View center ──────────────────────────────────────────────────────
        Text {
            text: "\u25ef"
            font.pixelSize: 9
            color: ThemeManager.primaryColor
            opacity: 0.80
            Layout.alignment: Qt.AlignCenter
        }
        RowLayout {
            Layout.preferredWidth: 100
            Text {
                font.pixelSize: 10
                color: ThemeManager.textColor
                opacity: 0.60
                Layout.alignment: Qt.AlignCenter
                text: {
                    var cx = Math.round((containerWidth  / 2 - canvasPosX) / zoom) - 5000
                    var cy = Math.round((containerHeight / 2 - canvasPosY) / zoom) - 5000
                    return "X " + cx + "  Y " + cy
                }
            }
        }
        Rectangle {
            Layout.preferredWidth: 1; Layout.preferredHeight: 12
            Layout.alignment: Qt.AlignVCenter
            color: ThemeManager.textColor; opacity: 0.18
        }

        // ── Mouse world position ─────────────────────────────────────────────
        Item { Layout.preferredWidth: 4 }
        Text {
            text: "\u2316"
            font.pixelSize: 11
            color: ThemeManager.primaryColor
            opacity: 0.80
            Layout.alignment: Qt.AlignCenter
        }
        RowLayout {
            Layout.preferredWidth: 100
            Text {
                font.pixelSize: 10
                color: ThemeManager.textColor
                opacity: 0.60
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 80
                text: {
                    var mx = Math.round((hoverX - canvasPosX) / zoom) - 5000
                    var my = Math.round((hoverY - canvasPosY) / zoom) - 5000
                    return "X " + mx + "  Y " + my
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 1; Layout.preferredHeight: 12
            Layout.alignment: Qt.AlignVCenter
            color: ThemeManager.textColor; opacity: 0.18
        }

        // ── Zoom level ───────────────────────────────────────────────────────
        Item { Layout.preferredWidth: 4 }
        Text {
            text: "\u2295"
            font.pixelSize: 11
            color: ThemeManager.primaryColor
            opacity: 0.80
            Layout.alignment: Qt.AlignVCenter
        }
        RowLayout {
            Layout.preferredWidth: 100
            Text {
                font.pixelSize: 10
                color: ThemeManager.textColor
                opacity: 0.60
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: 44
                text: Math.round(zoom * 100) + "%"
            }
        }

        // ── Selected node (optional) ─────────────────────────────────────────
        Item { Layout.preferredWidth: 10; visible: nodeOnFocus !== undefined && nodeOnFocus !== null }
        Rectangle {
            Layout.preferredWidth: 1; Layout.preferredHeight: 12
            Layout.alignment: Qt.AlignVCenter
            color: ThemeManager.textColor; opacity: 0.18
            visible: nodeOnFocus !== undefined && nodeOnFocus !== null
        }
        Item { Layout.preferredWidth: 10; visible: nodeOnFocus !== undefined && nodeOnFocus !== null }
        Text {
            text: "\u25c8"
            font.pixelSize: 10
            color: ThemeManager.primaryColor
            opacity: 0.85
            Layout.alignment: Qt.AlignVCenter
            visible: nodeOnFocus !== undefined && nodeOnFocus !== null
        }
        Item { Layout.preferredWidth: 5; visible: nodeOnFocus !== undefined && nodeOnFocus !== null }
        Text {
            font.pixelSize: 10
            color: ThemeManager.textColor
            opacity: 0.65
            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: 160
            visible: nodeOnFocus !== undefined && nodeOnFocus !== null
            text: nodeOnFocus ? (nodeOnFocus.behaviourObject ? nodeOnFocus.behaviourObject.title : "Node") : ""
            elide: Text.ElideRight
        }

        // ── Log output (fills center) ────────────────────────────────────────
        Item { Layout.preferredWidth: 8 }

        Rectangle {
            Layout.preferredWidth: 1; Layout.preferredHeight: 12
            Layout.alignment: Qt.AlignVCenter
            color: ThemeManager.textColor; opacity: 0.18
            visible: LogManager.lastMessage !== ""
        }

        Item { Layout.preferredWidth: 6; visible: LogManager.lastMessage !== "" }

        Text {
            text: {
                if (LogManager.lastType === "warning") return "⚠"
                if (LogManager.lastType === "error" || LogManager.lastType === "fatal") return "✕"
                return "ℹ"
            }
            font.pixelSize: 9
            color: {
                if (LogManager.lastType === "warning") return ThemeManager.warningColor
                if (LogManager.lastType === "error" || LogManager.lastType === "fatal") return ThemeManager.dangerColor
                return ThemeManager.primaryColor
            }
            opacity: 0.85
            Layout.alignment: Qt.AlignVCenter
            visible: LogManager.lastMessage !== ""
        }

        Item { Layout.preferredWidth: 4; visible: LogManager.lastMessage !== "" }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            font.pixelSize: 10
            color: {
                if (LogManager.lastType === "warning") return ThemeManager.warningColor
                if (LogManager.lastType === "error" || LogManager.lastType === "fatal") return ThemeManager.dangerColor
                return ThemeManager.textColor
            }
            opacity: 0.72
            text: LogManager.lastMessage
            elide: Text.ElideRight
        }

        Item { Layout.preferredWidth: 8; visible: LogManager.lastMessage !== "" }

        Text {
            text: LogManager.lastTime
            font.pixelSize: 9
            color: ThemeManager.textColor
            opacity: 0.30
            Layout.alignment: Qt.AlignVCenter
            visible: LogManager.lastMessage !== ""
        }

        Item { Layout.preferredWidth: 8 }

        // ── Node count ───────────────────────────────────────────────────────
        Text {
            font.pixelSize: 10
            color: ThemeManager.textColor
            opacity: 0.40
            Layout.alignment: Qt.AlignVCenter
            text: nodeCount + (nodeCount === 1 ? " node" : " nodes")
        }

        Item { Layout.preferredWidth: 8; visible: showFps }

        // ── FPS Display ──────────────────────────────────────────────────────
        Rectangle {
            Layout.preferredWidth: 1; Layout.preferredHeight: 12
            Layout.alignment: Qt.AlignVCenter
            color: ThemeManager.textColor; opacity: 0.18
            visible: showFps
        }
        Item { Layout.preferredWidth: 8; visible: showFps }
        Text {
            font.pixelSize: 10
            color: ThemeManager.successColor
            opacity: 0.8
            Layout.alignment: Qt.AlignVCenter
            text: fpsCount + " FPS (" + (fpsCount > 0 ? (1000/fpsCount).toFixed(1) : "0.0") + " ms)"
            visible: showFps
        }
        Item { Layout.preferredWidth: 4; visible: showFps }
    }
}
