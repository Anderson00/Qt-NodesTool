import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import Qaterial 1.0 as Qaterial

// Full-viewport overlay shown when Play is pressed in VisualizationWindow.
// Lives as a direct child of ViewPortWindow (same scene graph as mycanvasBody),
// which is required for ShaderEffectSource to capture cross-item pixels.
// A separate OS Window cannot be used because ShaderEffectSource is limited
// to items within the same QQuickWindow / scene graph.
Rectangle {
    id: root

    property real cameraX:      0
    property real cameraY:      0
    property real cameraWidth:  800
    property real cameraHeight: 450
    property var  canvasBody:   null

    signal closeRequested()

    color:   "#000000"
    visible: false

    // ── Preview ───────────────────────────────────────────────────────────────
    ShaderEffectSource {
        anchors.fill: parent
        // null when overlay is hidden — prevents FBO interference with the
        // main viewport render (two simultaneous ShaderEffectSources on the
        // same sourceItem suppress its direct-to-screen render).
        sourceItem:  (root.visible && root.canvasBody !== null) ? root.canvasBody : null
        sourceRect:  Qt.rect(root.cameraX, root.cameraY,
                             root.cameraWidth, root.cameraHeight)
        live:        true
        hideSource:  false
    }

    // ── HUD — fades after 2.5 s of mouse inactivity ───────────────────────────
    Item {
        id: hud
        anchors.fill: parent

        property bool active: true
        opacity: active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 400 } }

        Timer {
            id: hudTimer; interval: 2500
            onTriggered: hud.active = false
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            onPositionChanged: function(mouse) {
                hud.active = true
                hudTimer.restart()
                mouse.accepted = false
            }
            onClicked: function(mouse) { mouse.accepted = false }
        }

        // Close button — top-right
        Rectangle {
            anchors { top: parent.top; right: parent.right; margins: 16 }
            width: 36; height: 36; radius: 18
            color: closeBtn.containsMouse ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.08)
            Behavior on color { ColorAnimation { duration: 150 } }

            Qaterial.ColorIcon {
                anchors.centerIn: parent
                source: Qaterial.Icons.close
                color:  Qt.rgba(1, 1, 1, 0.75)
                width: 16; height: 16
            }

            MouseArea {
                id: closeBtn
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onClicked: root.closeRequested()
            }
        }

        // ESC hint — bottom-center
        Text {
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 16 }
            text: "ESC  ·  fechar"
            color: Qt.rgba(1, 1, 1, 0.18)
            font.pixelSize: 11; font.letterSpacing: 1.2
        }
    }
}
