import QtQuick 2.15
import App.Properties 1.0

// Generic resize handle for the 4 corners and 4 edges of a parent Rectangle.
// Encapsulates its own state, uses global coordinates to avoid drift while
// the target moves during resize.
Rectangle {
    id: handle

    // -- Public API --
    // Direction: "top-left", "top-right", "bottom-left", "bottom-right",
    //            "top", "bottom", "left", "right"
    property string direction: "right"

    // Item that will be resized. Defaults to the parent (the rect being decorated).
    property Item target: parent

    property int handleSize: 8
    property int hitMargin: 10           // extra invisible hit area
    property real minWidth: 50
    property real minHeight: 50
    property color highlightColor: "white"

    // Read-only: true while the user is dragging this handle
    readonly property bool active: dragArea.pressed

    signal resizeStarted()
    signal resizeFinished()

    z: 20
    color: (GlobalProperties.debugMode && (dragArea.containsMouse || active))
           ? handle.highlightColor
           : Qt.rgba(0, 0, 0, 0)
    border.width: GlobalProperties.debugMode ? 1 : 0
    border.color: GlobalProperties.debugMode ? handle.highlightColor : "transparent"

    // ---- Geometry per direction ----
    states: [
        State {
            name: "top-left"
            when: handle.direction === "top-left"
            AnchorChanges { target: handle; anchors.left: target.left; anchors.top: target.top }
            PropertyChanges { target: handle
                anchors.leftMargin: -handle.handleSize / 2
                anchors.topMargin: -handle.handleSize / 2
                width: handle.handleSize; height: handle.handleSize
                radius: handle.handleSize / 2
            }
        },
        State {
            name: "top-right"
            when: handle.direction === "top-right"
            AnchorChanges { target: handle; anchors.right: target.right; anchors.top: target.top }
            PropertyChanges { target: handle
                anchors.rightMargin: -handle.handleSize / 2
                anchors.topMargin: -handle.handleSize / 2
                width: handle.handleSize; height: handle.handleSize
                radius: handle.handleSize / 2
            }
        },
        State {
            name: "bottom-left"
            when: handle.direction === "bottom-left"
            AnchorChanges { target: handle; anchors.left: target.left; anchors.bottom: target.bottom }
            PropertyChanges { target: handle
                anchors.leftMargin: -handle.handleSize / 2
                anchors.bottomMargin: -handle.handleSize / 2
                width: handle.handleSize; height: handle.handleSize
                radius: handle.handleSize / 2
            }
        },
        State {
            name: "bottom-right"
            when: handle.direction === "bottom-right"
            AnchorChanges { target: handle; anchors.right: target.right; anchors.bottom: target.bottom }
            PropertyChanges { target: handle
                anchors.rightMargin: -handle.handleSize / 2
                anchors.bottomMargin: -handle.handleSize / 2
                width: handle.handleSize; height: handle.handleSize
                radius: handle.handleSize / 2
            }
        },
        State {
            name: "top"
            when: handle.direction === "top"
            AnchorChanges {
                target: handle
                anchors.left: target.left; anchors.right: target.right; anchors.top: target.top
            }
            PropertyChanges { target: handle
                anchors.leftMargin: handle.handleSize
                anchors.rightMargin: handle.handleSize
                anchors.topMargin: -handle.handleSize / 2
                height: handle.handleSize
            }
        },
        State {
            name: "bottom"
            when: handle.direction === "bottom"
            AnchorChanges {
                target: handle
                anchors.left: target.left; anchors.right: target.right; anchors.bottom: target.bottom
            }
            PropertyChanges { target: handle
                anchors.leftMargin: handle.handleSize
                anchors.rightMargin: handle.handleSize
                anchors.bottomMargin: -handle.handleSize / 2
                height: handle.handleSize
            }
        },
        State {
            name: "left"
            when: handle.direction === "left"
            AnchorChanges {
                target: handle
                anchors.left: target.left; anchors.top: target.top; anchors.bottom: target.bottom
            }
            PropertyChanges { target: handle
                anchors.leftMargin: -handle.handleSize / 2
                anchors.topMargin: handle.handleSize
                anchors.bottomMargin: handle.handleSize
                width: handle.handleSize
            }
        },
        State {
            name: "right"
            when: handle.direction === "right"
            AnchorChanges {
                target: handle
                anchors.right: target.right; anchors.top: target.top; anchors.bottom: target.bottom
            }
            PropertyChanges { target: handle
                anchors.rightMargin: -handle.handleSize / 2
                anchors.topMargin: handle.handleSize
                anchors.bottomMargin: handle.handleSize
                width: handle.handleSize
            }
        }
    ]

    // ---- Cursor mapping ----
    readonly property int _cursor: {
        switch (handle.direction) {
            case "top-left":
            case "bottom-right":  return Qt.SizeFDiagCursor
            case "top-right":
            case "bottom-left":   return Qt.SizeBDiagCursor
            case "top":
            case "bottom":        return Qt.SizeVerCursor
            case "left":
            case "right":         return Qt.SizeHorCursor
        }
        return Qt.ArrowCursor
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        anchors.margins: -handle.hitMargin
        hoverEnabled: true
        cursorShape: handle._cursor
        preventStealing: true

        property real startGlobalX: 0
        property real startGlobalY: 0
        property real startTargetX: 0
        property real startTargetY: 0
        property real startTargetW: 0
        property real startTargetH: 0

        onPressed: function(mouse) {
            const g = mapToGlobal(mouse.x, mouse.y)
            startGlobalX = g.x
            startGlobalY = g.y
            startTargetX = handle.target.x
            startTargetY = handle.target.y
            startTargetW = handle.target.width
            startTargetH = handle.target.height
            handle.resizeStarted()
        }

        onPositionChanged: function(mouse) {
            if (!pressed) return

            const g = mapToGlobal(mouse.x, mouse.y)
            const dx = g.x - startGlobalX
            const dy = g.y - startGlobalY
            const dir = handle.direction

            // Horizontal
            if (dir.indexOf("left") !== -1) {
                const newW = startTargetW - dx
                if (newW >= handle.minWidth) {
                    handle.target.x = startTargetX + dx
                    handle.target.width = newW
                }
            } else if (dir.indexOf("right") !== -1) {
                const newW = startTargetW + dx
                if (newW >= handle.minWidth)
                    handle.target.width = newW
            }

            // Vertical
            if (dir.indexOf("top") !== -1) {
                const newH = startTargetH - dy
                if (newH >= handle.minHeight) {
                    handle.target.y = startTargetY + dy
                    handle.target.height = newH
                }
            } else if (dir.indexOf("bottom") !== -1) {
                const newH = startTargetH + dy
                if (newH >= handle.minHeight)
                    handle.target.height = newH
            }
        }

        onReleased: handle.resizeFinished()
        onCanceled: handle.resizeFinished()
    }
}
