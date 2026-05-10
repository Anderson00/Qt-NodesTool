import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import Qaterial 1.0 as Qaterial

// Full-viewport overlay (same QQuickWindow as ViewPortWindow).
// Loads only each node's qmlBodyUrl body — no header, no sockets, no handles,
// no connection lines. The same behaviourObject is shared so C++ signals/slots
// are always live and node buttons are fully interactive.
Rectangle {
    id: root

    property real cameraX:      0
    property real cameraY:      0
    property real cameraWidth:  800
    property real cameraHeight: 450
    property var  nodesModel:   null

    signal closeRequested()

    color:   "#111111"
    visible: false

    // ── Content ───────────────────────────────────────────────────────────────
    Item {
        id: previewArea
        anchors.fill: parent
        clip: true

        // Uniform scale: camera width → preview width.
        readonly property real s: root.cameraWidth > 0 ? width / root.cameraWidth : 1.0

        // worldContainer maps world coords → screen:
        //   screenX = (worldX - cameraX) * s
        //   achieved by: x = -cameraX * s  +  Scale(s) applied to children
        Item {
            id: worldContainer
            // Width/height large enough to contain all nodes (canvas is 10000×10000).
            // Required so Qt's hit-test engine considers children for pointer events.
            width:  10000
            height: 10000
            x: -root.cameraX * previewArea.s
            y: -root.cameraY * previewArea.s

            transform: Scale {
                xScale: previewArea.s; yScale: previewArea.s
                origin.x: 0; origin.y: 0
            }

            Repeater {
                model: root.nodesModel

                delegate: Item {
                    property var obj: model ? model.object : null
                    x:      obj ? obj.x      : 0
                    y:      obj ? obj.y      : 0
                    width:  obj ? obj.width  : 0
                    height: obj ? obj.height : 0
                    visible: !!model.isVisualization

                    // Super Sampling: Força o nó a renderizar na resolução real da tela (escala aplicada)
                    antialiasing: true
                    // layer.enabled: true
                    // layer.smooth:  true
                    // layer.textureSize: Qt.size(width * previewArea.s, height * previewArea.s)

                    // Moldura para o nó na visualização (substitui o crome do editor)
                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(0.15, 0.15, 0.15, 0.4)
                        border.color: Qt.rgba(1, 1, 1, 0.15)
                        border.width: 1 / previewArea.s // Mantém a borda sempre fina na tela
                        radius: 4
                    }

                    Loader {
                        id: bodyLoader
                        anchors.fill: parent
                        property var behaviourObject: parent.obj
                        clip: true
                        // antialiasing: true
                        // layer.enabled: true
                        // layer.samples: 5
                        source: (parent.obj && parent.obj.qmlBodyUrl !== "") ? parent.obj.qmlBodyUrl : ""
                        
                        onLoaded: {
                            if (item && item.hasOwnProperty("behaviourObject"))
                                item.behaviourObject = parent.obj
                        }
                    }
                }
            }
        }
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

        // ESC hint — bottom-center
        Text {
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 16 }
            text: "ESC  ·  fechar"
            color: Qt.rgba(1, 1, 1, 0.18)
            font.pixelSize: 11; font.letterSpacing: 1.2
        }
    }
}
