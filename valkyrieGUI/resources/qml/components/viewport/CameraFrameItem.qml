import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0

import ".."

// Camera frame — a moveable/resizable rectangle on the canvas that defines
// the region rendered by VisualizationWindow. Position (x, y) and size are
// in world (canvas) coordinates because this item lives inside mycanvas.
Rectangle {
    id: root

    // Emitted on every position/size change (world coords)
    signal cameraRectChanged(real wx, real wy, real ww, real wh)
    signal closeRequested()

    // Aspect ratio lock: "16:9" | "4:3" | "1:1" | "Screen" | "" (free)
    property string aspectRatio: "Screen"
    readonly property real screenRatioValue: Screen.width / Screen.height

    // Minimum dimensions in world units
    readonly property real minW: 200
    readonly property real minH: 112

    readonly property color camColor: "#FF9800"

    color:        Qt.rgba(camColor.r, camColor.g, camColor.b, 0.04)
    border.color: camColor
    border.width: 2
    radius: 4

    // Inner dashed highlight
    Rectangle {
        anchors { fill: parent; margins: 4 }
        color: "transparent"
        border.color: Qt.rgba(root.camColor.r, root.camColor.g, root.camColor.b, 0.18)
        border.width: 1
        radius: root.radius
    }

    // ── Drag state ────────────────────────────────────────────────────────────
    property real _dragPX: 0; property real _dragPY: 0
    property real _dragFX: 0; property real _dragFY: 0

    // ── Header ────────────────────────────────────────────────────────────────
    Rectangle {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 24
        color: Qt.rgba(root.camColor.r, root.camColor.g, root.camColor.b, 0.28)
        radius: root.radius

        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: root.radius; color: parent.color
        }

        Row {
            anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
            spacing: 5

            Rectangle {
                width: 8; height: 8; radius: 1
                color: root.camColor
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "Camera"
                color: root.camColor; font.pixelSize: 10; font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            anchors { right: parent.right; rightMargin: 4; verticalCenter: parent.verticalCenter }
            spacing: 0

            // Aspect ratio cycle button
            ToolButton {
                width: 32; height: 20; padding: 0
                contentItem: Text {
                    text: root.aspectRatio !== "" ? root.aspectRatio : "free"
                    color: root.camColor; font.pixelSize: 8; font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment:   Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 3
                    color: parent.pressed ? Qt.rgba(0,0,0,0.15) : parent.hovered ? Qt.rgba(0,0,0,0.08) : "transparent"
                }
                onClicked: {
                    if      (root.aspectRatio === "Screen") root.aspectRatio = "16:9"
                    else if (root.aspectRatio === "16:9")   root.aspectRatio = "4:3"
                    else if (root.aspectRatio === "4:3")    root.aspectRatio = "1:1"
                    else if (root.aspectRatio === "1:1")    root.aspectRatio = ""
                    else                                    root.aspectRatio = "Screen"
                    _applyAspect()
                }
                AppToolTip { text: "Cycle aspect ratio"; visible: parent.hovered }
            }

            AppBarButton {
                width: 20; height: 20; padding: 0
                icon.source: 'qrc:/icons/close.svg'
                icon.color:  root.camColor; icon.width: 10; icon.height: 10
                onClicked: root.closeRequested()
            }
        }

        // Drag handle (above buttons thanks to z:1 on buttons row, this fills behind)
        MouseArea {
            anchors.fill: parent; z: -1
            preventStealing: true
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.SizeAllCursor
            onPressed: function(m) {
                var pt = mapToItem(root.parent, m.x, m.y)
                root._dragPX = pt.x; root._dragPY = pt.y
                root._dragFX = root.x; root._dragFY = root.y
            }
            onPositionChanged: function(m) {
                var pt = mapToItem(root.parent, m.x, m.y)
                root.x = root._dragFX + (pt.x - root._dragPX)
                root.y = root._dragFY + (pt.y - root._dragPY)
                root.cameraRectChanged(root.x, root.y, root.width, root.height)
            }
            onReleased: root.cameraRectChanged(root.x, root.y, root.width, root.height)
        }
    }

    // ── Resize state ──────────────────────────────────────────────────────────
    property real _rsPX: 0; property real _rsPY: 0
    property real _rsW:  0; property real _rsH:  0

    function _applyAspect() {
        if      (aspectRatio === "Screen") height = width / screenRatioValue
        else if (aspectRatio === "16:9")   height = width * 9 / 16
        else if (aspectRatio === "4:3")    height = width * 3 / 4
        else if (aspectRatio === "1:1")    height = width
        cameraRectChanged(x, y, width, height)
    }

    function _constrainHeight(newW, newH) {
        if      (aspectRatio === "Screen") return newW / screenRatioValue
        else if (aspectRatio === "16:9")   return newW * 9 / 16
        else if (aspectRatio === "4:3")    return newW * 3 / 4
        else if (aspectRatio === "1:1")    return newW
        return newH
    }

    // ── Bottom-right resize handle ────────────────────────────────────────────
    Rectangle {
        id: brHandle
        width: 14; height: 14; radius: 2
        anchors { right: parent.right; bottom: parent.bottom; margins: 1 }
        color: Qt.rgba(root.camColor.r, root.camColor.g, root.camColor.b, 0.7)

        MouseArea {
            anchors.fill: parent; preventStealing: true
            cursorShape: Qt.SizeFDiagCursor
            onPressed: function(m) {
                var pt = mapToItem(root.parent, m.x, m.y)
                root._rsPX = pt.x; root._rsPY = pt.y
                root._rsW  = root.width; root._rsH = root.height
            }
            onPositionChanged: function(m) {
                var pt   = mapToItem(root.parent, m.x, m.y)
                var newW = Math.max(root.minW, root._rsW + (pt.x - root._rsPX))
                var newH = root._constrainHeight(newW,
                               Math.max(root.minH, root._rsH + (pt.y - root._rsPY)))
                root.width  = newW
                root.height = newH
                root.cameraRectChanged(root.x, root.y, root.width, root.height)
            }
            onReleased: root.cameraRectChanged(root.x, root.y, root.width, root.height)
        }
    }

    // ── Corner rule lines ─────────────────────────────────────────────────────
    // Four L-shaped corner marks that reinforce the "camera viewfinder" look.
    readonly property int _cornerLen: 14
    readonly property int _cornerThk: 2

    // top-left
    Rectangle { x: 0; y: 0; width: _cornerLen; height: _cornerThk; color: camColor }
    Rectangle { x: 0; y: 0; width: _cornerThk; height: _cornerLen; color: camColor }
    // top-right
    Rectangle { x: parent.width - _cornerLen; y: 0; width: _cornerLen; height: _cornerThk; color: camColor }
    Rectangle { x: parent.width - _cornerThk; y: 0; width: _cornerThk; height: _cornerLen; color: camColor }
    // bottom-left
    Rectangle { x: 0; y: parent.height - _cornerThk; width: _cornerLen; height: _cornerThk; color: camColor }
    Rectangle { x: 0; y: parent.height - _cornerLen; width: _cornerThk; height: _cornerLen; color: camColor }
}

