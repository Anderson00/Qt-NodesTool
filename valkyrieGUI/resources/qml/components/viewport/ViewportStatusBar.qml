import QtQuick 2.12
import QtQuick.Layouts 1.0
import App.Theme 1.0

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
            Layout.alignment: Qt.AlignVCenter
        }
        Item { Layout.preferredWidth: 4 }
        Text {
            font.pixelSize: 10
            color: ThemeManager.textColor
            opacity: 0.60
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 80
            text: {
                var cx = Math.round((containerWidth  / 2 - canvasPosX) / zoom) - 5000
                var cy = Math.round((containerHeight / 2 - canvasPosY) / zoom) - 5000
                return "X " + cx + "  Y " + cy
            }
        }
        Item { Layout.preferredWidth: 10 }
        Rectangle {
            Layout.preferredWidth: 1; Layout.preferredHeight: 12
            Layout.alignment: Qt.AlignVCenter
            color: ThemeManager.textColor; opacity: 0.18
        }
        Item { Layout.preferredWidth: 10 }

        // ── Mouse world position ─────────────────────────────────────────────
        Text {
            text: "\u2316"
            font.pixelSize: 11
            color: ThemeManager.primaryColor
            opacity: 0.80
            Layout.alignment: Qt.AlignVCenter
        }
        Item { Layout.preferredWidth: 4 }
        Text {
            font.pixelSize: 10
            color: ThemeManager.textColor
            opacity: 0.60
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 80
            text: {
                var mx = Math.round((hoverX - canvasPosX) / zoom) - 5000
                var my = Math.round((hoverY - canvasPosY) / zoom) - 5000
                return "X " + mx + "  Y " + my
            }
        }
        Item { Layout.preferredWidth: 10 }
        Rectangle {
            Layout.preferredWidth: 1; Layout.preferredHeight: 12
            Layout.alignment: Qt.AlignVCenter
            color: ThemeManager.textColor; opacity: 0.18
        }
        Item { Layout.preferredWidth: 10 }

        // ── Zoom level ───────────────────────────────────────────────────────
        Text {
            text: "\u2295"
            font.pixelSize: 11
            color: ThemeManager.primaryColor
            opacity: 0.80
            Layout.alignment: Qt.AlignVCenter
        }
        Item { Layout.preferredWidth: 4 }
        Text {
            font.pixelSize: 10
            color: ThemeManager.textColor
            opacity: 0.60
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 44
            text: Math.round(zoom * 100) + "%"
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

        Item { Layout.fillWidth: true }

        // ── Node count ───────────────────────────────────────────────────────
        Text {
            font.pixelSize: 10
            color: ThemeManager.textColor
            opacity: 0.40
            Layout.alignment: Qt.AlignVCenter
            text: nodeCount + (nodeCount === 1 ? " node" : " nodes")
        }
    }
}
