import QtQuick 2.15
import App.Properties 1.0

// Generic resize handle for the 4 corners and 4 edges of a parent Rectangle.
// Supports grid snap and node-alignment snap via viewportEdgeSnap.
Rectangle {
    id: handle

    property string direction: "right"
    property Item   target: parent

    property int   handleSize:  8
    property int   hitMargin:   10
    property real  minWidth:    50
    property real  minHeight:   50
    property color highlightColor: "white"

    // Provided by ViewComponentRectV2 → ViewPortWindow.computeEdgeSnap
    // Signature: (rawEdgeX, rawEdgeY, node) → Qt.point
    //   rawEdgeX / rawEdgeY: canvas position of the edge being dragged, or null if that axis is fixed.
    property var viewportEdgeSnap: null

    // Fallback when viewportEdgeSnap is not available
    readonly property bool _snapActive: GlobalProperties.snapEnabled
    readonly property int  _snapGrid:   GlobalProperties.snapSyncToGrid
                                        ? GlobalProperties.minWgrid
                                        : GlobalProperties.snapGridSize

    function _fallbackSnapEdge(pos) {
        if (!_snapActive || _snapGrid <= 0) return pos
        return Math.round(pos / _snapGrid) * _snapGrid
    }

    // Snap a single edge: use viewport function when available, fallback otherwise.
    // Returns the snapped position for a single axis.
    function _snapX(rawX) {
        if (viewportEdgeSnap) return viewportEdgeSnap(rawX, null, handle.target).x
        return _fallbackSnapEdge(rawX)
    }
    function _snapY(rawY) {
        if (viewportEdgeSnap) return viewportEdgeSnap(null, rawY, handle.target).y
        return _fallbackSnapEdge(rawY)
    }
    // Snap both axes simultaneously (corners) — single call so guides reflect both.
    function _snapXY(rawX, rawY) {
        if (viewportEdgeSnap) return viewportEdgeSnap(rawX, rawY, handle.target)
        return Qt.point(_fallbackSnapEdge(rawX), _fallbackSnapEdge(rawY))
    }

    readonly property bool active: dragArea.pressed

    // Final geometry last written to target during this drag session
    property real _endX: 0
    property real _endY: 0
    property real _endW: 0
    property real _endH: 0

    signal resizeStarted()
    signal resizeFinished(real oldX, real oldY, real oldW, real oldH,
                          real newX, real newY, real newW, real newH)

    z: 20
    color: (GlobalProperties.debugMode && (dragArea.containsMouse || active))
           ? handle.highlightColor
           : Qt.rgba(0, 0, 0, 0)
    border.width: GlobalProperties.debugMode ? 1 : 0
    border.color: GlobalProperties.debugMode ? handle.highlightColor : "transparent"

    // ── Geometry per direction ─────────────────────────────────────────────────
    states: [
        State {
            name: "top-left"
            when: handle.direction === "top-left"
            AnchorChanges { target: handle; anchors.left: target.left; anchors.top: target.top }
            PropertyChanges { target: handle
                anchors.leftMargin: -handle.handleSize / 2; anchors.topMargin: -handle.handleSize / 2
                width: handle.handleSize; height: handle.handleSize; radius: handle.handleSize / 2
            }
        },
        State {
            name: "top-right"
            when: handle.direction === "top-right"
            AnchorChanges { target: handle; anchors.right: target.right; anchors.top: target.top }
            PropertyChanges { target: handle
                anchors.rightMargin: -handle.handleSize / 2; anchors.topMargin: -handle.handleSize / 2
                width: handle.handleSize; height: handle.handleSize; radius: handle.handleSize / 2
            }
        },
        State {
            name: "bottom-left"
            when: handle.direction === "bottom-left"
            AnchorChanges { target: handle; anchors.left: target.left; anchors.bottom: target.bottom }
            PropertyChanges { target: handle
                anchors.leftMargin: -handle.handleSize / 2; anchors.bottomMargin: -handle.handleSize / 2
                width: handle.handleSize; height: handle.handleSize; radius: handle.handleSize / 2
            }
        },
        State {
            name: "bottom-right"
            when: handle.direction === "bottom-right"
            AnchorChanges { target: handle; anchors.right: target.right; anchors.bottom: target.bottom }
            PropertyChanges { target: handle
                anchors.rightMargin: -handle.handleSize / 2; anchors.bottomMargin: -handle.handleSize / 2
                width: handle.handleSize; height: handle.handleSize; radius: handle.handleSize / 2
            }
        },
        State {
            name: "top"
            when: handle.direction === "top"
            AnchorChanges { target: handle; anchors.left: target.left; anchors.right: target.right; anchors.top: target.top }
            PropertyChanges { target: handle
                anchors.leftMargin: handle.handleSize; anchors.rightMargin: handle.handleSize
                anchors.topMargin: -handle.handleSize / 2; height: handle.handleSize
            }
        },
        State {
            name: "bottom"
            when: handle.direction === "bottom"
            AnchorChanges { target: handle; anchors.left: target.left; anchors.right: target.right; anchors.bottom: target.bottom }
            PropertyChanges { target: handle
                anchors.leftMargin: handle.handleSize; anchors.rightMargin: handle.handleSize
                anchors.bottomMargin: -handle.handleSize / 2; height: handle.handleSize
            }
        },
        State {
            name: "left"
            when: handle.direction === "left"
            AnchorChanges { target: handle; anchors.left: target.left; anchors.top: target.top; anchors.bottom: target.bottom }
            PropertyChanges { target: handle
                anchors.leftMargin: -handle.handleSize / 2
                anchors.topMargin: handle.handleSize; anchors.bottomMargin: handle.handleSize
                width: handle.handleSize
            }
        },
        State {
            name: "right"
            when: handle.direction === "right"
            AnchorChanges { target: handle; anchors.right: target.right; anchors.top: target.top; anchors.bottom: target.bottom }
            PropertyChanges { target: handle
                anchors.rightMargin: -handle.handleSize / 2
                anchors.topMargin: handle.handleSize; anchors.bottomMargin: handle.handleSize
                width: handle.handleSize
            }
        }
    ]

    // ── Cursor ─────────────────────────────────────────────────────────────────
    readonly property int _cursor: {
        switch (handle.direction) {
            case "top-left":  case "bottom-right": return Qt.SizeFDiagCursor
            case "top-right": case "bottom-left":  return Qt.SizeBDiagCursor
            case "top":       case "bottom":        return Qt.SizeVerCursor
            case "left":      case "right":         return Qt.SizeHorCursor
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
            startGlobalX = g.x;  startGlobalY = g.y
            startTargetX = handle.target.x;    startTargetY = handle.target.y
            startTargetW = handle.target.width; startTargetH = handle.target.height
            handle._endX = handle.target.x;    handle._endY = handle.target.y
            handle._endW = handle.target.width; handle._endH = handle.target.height
            handle.resizeStarted()
        }

        onPositionChanged: function(mouse) {
            if (!pressed) return

            const g   = mapToGlobal(mouse.x, mouse.y)
            const dx  = g.x - startGlobalX
            const dy  = g.y - startGlobalY
            const dir = handle.direction

            const isLeft   = dir.indexOf("left")   !== -1
            const isRight  = dir.indexOf("right")  !== -1
            const isTop    = dir.indexOf("top")    !== -1
            const isBottom = dir.indexOf("bottom") !== -1
            const isCorner = (isLeft || isRight) && (isTop || isBottom)

            // Raw absolute canvas positions of the edges being moved
            var rawX = isLeft  ? startTargetX + dx
                     : isRight ? startTargetX + startTargetW + dx : null
            var rawY = isTop    ? startTargetY + dy
                     : isBottom ? startTargetY + startTargetH + dy : null

            // Snap — single call for corners (both axes at once for coherent guides)
            var snappedX, snappedY
            if (isCorner) {
                var s = handle._snapXY(rawX, rawY)
                snappedX = s.x;  snappedY = s.y
            } else if (rawX !== null) {
                snappedX = handle._snapX(rawX)
            } else {
                snappedY = handle._snapY(rawY)
            }

            // Apply horizontal result
            if (isLeft) {
                var newW = startTargetX + startTargetW - snappedX
                if (newW >= handle.minWidth) {
                    handle.target.x     = snappedX
                    handle.target.width = newW
                }
            } else if (isRight) {
                var newWr = snappedX - startTargetX
                if (newWr >= handle.minWidth)
                    handle.target.width = newWr
            }

            // Apply vertical result
            if (isTop) {
                var newH = startTargetY + startTargetH - snappedY
                if (newH >= handle.minHeight) {
                    handle.target.y      = snappedY
                    handle.target.height = newH
                }
            } else if (isBottom) {
                var newHb = snappedY - startTargetY
                if (newHb >= handle.minHeight)
                    handle.target.height = newHb
            }

            // Record final geometry after every move (last value wins at release)
            handle._endX = handle.target.x;    handle._endY = handle.target.y
            handle._endW = handle.target.width; handle._endH = handle.target.height
        }

        onReleased: handle.resizeFinished(
            dragArea.startTargetX, dragArea.startTargetY,
            dragArea.startTargetW, dragArea.startTargetH,
            handle._endX, handle._endY,
            handle._endW, handle._endH)
        onCanceled: handle.resizeFinished(
            dragArea.startTargetX, dragArea.startTargetY,
            dragArea.startTargetW, dragArea.startTargetH,
            dragArea.startTargetX, dragArea.startTargetY,
            dragArea.startTargetW, dragArea.startTargetH)
    }
}
