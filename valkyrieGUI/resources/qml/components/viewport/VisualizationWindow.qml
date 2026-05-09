import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import Qaterial 1.0 as Qaterial
import ".."

// Floating visualization window — renders only the qmlBodyUrl of nodes that
// fall inside the camera rect, scaled and translated to fill the preview area.
// Lives inside ViewPortWindow as a z:300 overlay (not a separate OS window).
Rectangle {
    id: root

    // Camera rect in world (canvas) coordinates — bind to CameraFrameItem's x/y/w/h
    property real cameraX:      5000
    property real cameraY:      5000
    property real cameraWidth:  800
    property real cameraHeight: 450

    // Reference to mycanvasBody in ViewPortWindow — ShaderEffectSource captures it directly.
    // This gives true 1:1 sync: same rendered pixels, same state, no QML recreation.
    property var canvasBody: null

    // Play/Stop: Play opens the fullscreen window, Stop closes it
    property bool isPlaying: false

    signal closeRequested()
    signal playToggled(bool playing)

    // Window defaults: appears at top-right of the canvas area
    width:  460
    height: 300

    color:  Qt.darker(ThemeManager.backgroundColor, 1.5)
    border.color: isPlaying ? "#4caf50" : "#FF9800"
    border.width: 1.5
    radius: 6

    Behavior on border.color { ColorAnimation { duration: 250 } }

    // ── Drag state ────────────────────────────────────────────────────────────
    property real _dragPX: 0; property real _dragPY: 0
    property real _dragOX: 0; property real _dragOY: 0

    // ── Title bar ─────────────────────────────────────────────────────────────
    Rectangle {
        id: titleBar
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 30
        color: Qt.darker(ThemeManager.backgroundColor, 1.9)
        radius: root.radius

        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: root.radius; color: parent.color
        }

        Row {
            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
            spacing: 6

            Rectangle {
                width: 10; height: 10; radius: 2
                color: root.isPlaying ? "#4caf50" : "#FF9800"
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: 250 } }
            }
            Text {
                text: root.isPlaying ? "Visualization — Playing" : "Visualization"
                font.pixelSize: 11; font.bold: true
                color: root.isPlaying ? "#4caf50" : "#FF9800"
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: 250 } }
            }
        }

        Row {
            anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
            spacing: 0

            Qaterial.ToolButton {
                width: 26; height: 26; padding: 0
                icon.source: root.isPlaying ? Qaterial.Icons.stop : Qaterial.Icons.play
                icon.color:  root.isPlaying ? "#f44336" : "#4caf50"
                icon.width: 14; icon.height: 14
                onClicked: {
                    root.isPlaying = !root.isPlaying
                    root.playToggled(root.isPlaying)
                }
                AppToolTip { text: root.isPlaying ? "Stop (fechar fullscreen)" : "Play (abrir fullscreen)"; visible: parent.hovered }
            }

            Qaterial.ToolButton {
                width: 26; height: 26; padding: 0
                icon.source: Qaterial.Icons.close
                icon.color:  ThemeManager.textColor; icon.width: 12; icon.height: 12
                onClicked: root.closeRequested()
                AppToolTip { text: "Fechar"; visible: parent.hovered }
            }
        }

        MouseArea {
            anchors.fill: parent; z: -1
            preventStealing: true
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.SizeAllCursor
            onPressed: function(m) {
                var pt = mapToItem(root.parent, m.x, m.y)
                root._dragPX = pt.x; root._dragPY = pt.y
                root._dragOX = root.x; root._dragOY = root.y
            }
            onPositionChanged: function(m) {
                var pt = mapToItem(root.parent, m.x, m.y)
                root.x = root._dragOX + (pt.x - root._dragPX)
                root.y = root._dragOY + (pt.y - root._dragPY)
            }
        }
    }

    // ── Preview area ──────────────────────────────────────────────────────────
    // ShaderEffectSource captures the actual rendered pixels of mycanvasBody.
    // sourceRect is in mycanvasBody's world coordinate space (0–10000).
    // Scaling to fill previewArea is handled automatically by Qt's scene graph.
    // Result: true 1:1 mirror — any state change in the editor (clear, chart
    // updates, button presses) is immediately reflected here.
    Item {
        id: previewArea
        anchors {
            top:    titleBar.bottom; bottom: parent.bottom
            left:   parent.left;    right:  parent.right
            margins: 2
        }
        clip: true

        Rectangle { anchors.fill: parent; color: "#0d0d0d" }

        ShaderEffectSource {
            id: canvasCapture
            anchors.fill: parent
            // sourceItem is null when this panel is hidden OR when fullscreen is
            // playing (fullscreen has its own ShaderEffectSource). Two simultaneous
            // ShaderEffectSources on the same item suppress its direct-to-screen render.
            sourceItem: (root.visible && !root.isPlaying && root.canvasBody !== null)
                        ? root.canvasBody : null
            sourceRect: Qt.rect(root.cameraX, root.cameraY,
                                root.cameraWidth, root.cameraHeight)
            live: true
            hideSource: false
        }

        Text {
            anchors.centerIn: parent
            text: "Camera não definida"
            color: "#444444"; font.pixelSize: 10
            visible: root.canvasBody === null
        }
    }

    // ── Resize state ──────────────────────────────────────────────────────────
    property real _rsPX: 0; property real _rsPY: 0
    property real _rsW:  0; property real _rsH:  0

    // ── Bottom-right resize handle ────────────────────────────────────────────
    Rectangle {
        width: 10; height: 10; radius: 2
        anchors { right: parent.right; bottom: parent.bottom; margins: 2 }
        color: Qt.rgba(1, 0.6, 0, 0.5)

        MouseArea {
            anchors.fill: parent; preventStealing: true; cursorShape: Qt.SizeFDiagCursor
            onPressed: function(m) {
                var pt = mapToItem(root.parent, m.x, m.y)
                root._rsPX = pt.x; root._rsPY = pt.y
                root._rsW = root.width; root._rsH = root.height
            }
            onPositionChanged: function(m) {
                var pt = mapToItem(root.parent, m.x, m.y)
                root.width  = Math.max(220, root._rsW + (pt.x - root._rsPX))
                root.height = Math.max(160, root._rsH + (pt.y - root._rsPY))
            }
        }
    }
}
