import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import App.Properties 1.0
import Qaterial 1.0 as Qaterial

// Full-viewport overlay (same QQuickWindow as ViewPortWindow).
// Loads only each node's qmlBodyUrl body — no header, no sockets, no handles,
// no connection lines. The same behaviourObject is shared so C++ signals/slots
// are always live and node buttons are fully interactive.
Window {
    id: root

    property real cameraX:      0
    property real cameraY:      0
    property real cameraWidth:  800
    property real cameraHeight: 450
    property var  nodesModel:   null

    signal closeRequested()

    width:  Screen.width
    height: Screen.height
    color:  "#111111"
    visible: true
    title:  "Valkyrie — Fullscreen Visualization"
    flags:  Qt.Window | Qt.FramelessWindowHint

    onVisibleChanged: {
        if (visible) {
            root.visibility = Window.FullScreen
        }
    }

    Component.onCompleted: {
        root.visibility = Window.FullScreen
    }

    onClosing: function(close) {
        close.accepted = false
        root.closeRequested()
    }

    Shortcut {
        sequence: "F11"
        onActivated: {
            if (root.visibility === Window.FullScreen)
                root.visibility = Window.Windowed
            else
                root.visibility = Window.FullScreen
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: root.closeRequested()
    }

    // ── Content ───────────────────────────────────────────────────────────────
    VisualizationPreview {
        id: previewArea
        anchors.fill: parent
        clip: true

        cameraX:      root.cameraX
        cameraY:      root.cameraY
        cameraWidth:  root.cameraWidth
        cameraHeight: root.cameraHeight
        nodesModel:   root.nodesModel
        isPlaying:    root.visible
    }

    // ── HUD — fades after 2.5 s of mouse inactivity ───────────────────────────
    // HoverHandler tracks mouse movement without consuming ANY mouse events,
    // so node body buttons (inside the Repeater below) remain fully interactive.
    HoverHandler {
        id: hoverDetector
        onPointChanged: {
            hud.active = true
            hudTimer.restart()
        }
    }

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

        // FPS Counter — top-left
        Text {
            anchors { top: parent.top; left: parent.left; margins: 20 }
            text: viewPort.fpsCount + " FPS"
            color: "#4caf50"
            font { pixelSize: 12; bold: true; family: "Consolas" }
            visible: GlobalProperties.showFps
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
