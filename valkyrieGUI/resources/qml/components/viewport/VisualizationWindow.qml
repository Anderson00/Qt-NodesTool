import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import Qaterial 1.0 as Qaterial
import ".."

// Floating visualization panel — loads each node's qmlBodyUrl body as a clean
// independent instance. No node chrome (no header, sockets, handles, connections).
// The shared behaviourObject keeps C++ signals/slots live; buttons are interactive.
Rectangle {
    id: root

    property real cameraX:      5000
    property real cameraY:      5000
    property real cameraWidth:  800
    property real cameraHeight: 450
    property var  nodesModel:   null

    // Play toggles the fullscreen overlay (managed by ViewPortWindow)
    property bool isPlaying: false

    signal closeRequested()
    signal playToggled(bool playing)

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
                onClicked: { root.isPlaying = !root.isPlaying; root.playToggled(root.isPlaying) }
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
    Item {
        id: previewArea
        anchors {
            top:    titleBar.bottom; bottom: parent.bottom
            left:   parent.left;    right:  parent.right
            margins: 2
        }
        clip: true

        Rectangle { anchors.fill: parent; color: "#111111" }

        readonly property real s: root.cameraWidth > 0 ? width / root.cameraWidth : 1.0

        Item {
            id: worldContainer
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

                delegate: Loader {
                    property var obj: model ? model.object : null
                    source:  (obj && obj.qmlBodyUrl !== "") ? obj.qmlBodyUrl : ""
                    x:       obj ? obj.x      : 0
                    y:       obj ? obj.y      : 0
                    width:   obj ? obj.width  : 0
                    height:  obj ? obj.height : 0
                    visible: source !== "" && (root.isPlaying ? (!!model.isVisualization) : (!model.isVisualization))
                    onLoaded: {
                        if (item && item.hasOwnProperty("behaviourObject"))
                            item.behaviourObject = obj
                    }
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: "Camera não definida\nou nenhum nó tem corpo visual"
            horizontalAlignment: Text.AlignHCenter
            color: "#444444"; font.pixelSize: 10
            visible: {
                if (!root.nodesModel) return true
                for (var i = 0; i < root.nodesModel.count; i++) {
                    var o = root.nodesModel.get(i).object
                    if (o && o.qmlBodyUrl !== "") return false
                }
                return true
            }
        }
    }

    // ── Resize handle (BR) ────────────────────────────────────────────────────
    property real _rsPX: 0; property real _rsPY: 0
    property real _rsW:  0; property real _rsH:  0

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
