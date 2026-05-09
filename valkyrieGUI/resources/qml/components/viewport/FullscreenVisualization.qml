import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import Qaterial 1.0 as Qaterial

// Fullscreen OS window opened when the user presses Play in VisualizationWindow.
// Renders node qmlBodyUrl bodies transformed to fill the screen based on cameraRect.
Window {
    id: root

    property real cameraX:      0
    property real cameraY:      0
    property real cameraWidth:  800
    property real cameraHeight: 450
    property var  nodesModel:   null

    color: "#000000"
    title: "Visualization — Valkyrie"
    visible: false

    // Close on Escape
    Shortcut {
        sequence: "Escape"
        context:  Qt.WindowShortcut
        onActivated: root.close()
    }

    // ── Preview content ───────────────────────────────────────────────────────
    Item {
        id: previewArea
        anchors.fill: parent
        clip: true

        // Uniform scale: fit camera width into screen width.
        // If aspect ratios differ, content is letterboxed horizontally (clipped by clip:true).
        readonly property real s: root.cameraWidth > 0 ? width / root.cameraWidth : 1.0

        // worldContainer maps world coords → screen:
        //   screenX = (worldX - cameraX) * s
        Item {
            id: worldContainer
            x: -root.cameraX * previewArea.s
            y: -root.cameraY * previewArea.s

            transform: Scale {
                xScale: previewArea.s
                yScale: previewArea.s
                origin.x: 0; origin.y: 0
            }

            Repeater {
                model: root.nodesModel

                delegate: Loader {
                    property var obj: model ? model.object : null
                    source: (obj && obj.qmlBodyUrl !== "") ? obj.qmlBodyUrl : ""
                    x:      obj ? obj.x      : 0
                    y:      obj ? obj.y      : 0
                    width:  obj ? obj.width  : 0
                    height: obj ? obj.height : 0
                    onLoaded: {
                        if (item && item.hasOwnProperty("behaviourObject"))
                            item.behaviourObject = obj
                    }
                }
            }
        }

        // ── HUD overlay ───────────────────────────────────────────────────────
        // Appears on hover; fades out after inactivity.
        Rectangle {
            id: hud
            anchors.fill: parent
            color: "transparent"

            property bool _hudVisible: true
            opacity: _hudVisible ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 400 } }

            Timer {
                id: hudTimer
                interval: 2500
                onTriggered: hud._hudVisible = false
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                propagateComposedEvents: true
                onPositionChanged: {
                    hud._hudVisible = true
                    hudTimer.restart()
                    mouse.accepted = false
                }
                onClicked: mouse.accepted = false
            }

            // Close button — top-right
            Rectangle {
                anchors.top:    parent.top
                anchors.right:  parent.right
                anchors.margins: 16
                width: 36; height: 36; radius: 18
                color: closeHover.containsMouse ? Qt.rgba(1,1,1,0.15) : Qt.rgba(1,1,1,0.07)
                Behavior on color { ColorAnimation { duration: 150 } }

                Qaterial.ColorIcon {
                    anchors.centerIn: parent
                    source: Qaterial.Icons.close
                    color:  Qt.rgba(1, 1, 1, 0.7)
                    width: 16; height: 16
                }

                MouseArea {
                    id: closeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }

            // ESC hint — bottom-center
            Text {
                anchors.bottom:           parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 16
                text: "ESC  ·  fechar"
                color: Qt.rgba(1, 1, 1, 0.18)
                font.pixelSize: 11
                font.letterSpacing: 1.2
            }
        }
    }
}
