import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.0
import QtQuick.Shapes 1.15
import App.Theme 1.0
import App.Properties 1.0
import App.Workspace 1.0
import App.Toast 1.0

import "../components"
import "../components/bottomsheets"
import "../components/viewport"
import "../components/drawers"
import Qaterial as Qaterial

Rectangle {
    id: root
    property var count: 0
    property int minWgrid: GlobalProperties.minWgrid
    property real minZoom: 0.2
    property real maxZoom: 5.0
    property real zoomScale: 1.0
    onZoomScaleChanged: viewPort.viewportScale = zoomScale

    // mouse properties
    property var mouseXX
    property var mouseYY
    property bool isConnecting: false
    property var shapeConn
    property bool m_suppressConnectionDraw: false

    //Behaviours properties
    property var behavioursZ: []
    property var nodeOnFocus

    // World-space point kept at the center of the view.
    // Updated whenever the canvas is panned or zoomed.
    // Initial value = (5000, 5000) = canvas center = "home" = display (0, 0).
    property real viewCenterX: 5000
    property real viewCenterY: 5000

    property var rectsArray: ListModel {}
    property bool allConnectionsMinimized: false

    // ── Grid snap ──────────────────────────────────────────────────────────
    // Read-only mirror of GlobalProperties — all mutations go through GlobalProperties
    // directly (G key, toolbar toggle, settings) to avoid binding-break issues.
    readonly property bool snapEnabled: GlobalProperties.snapEnabled
    onSnapEnabledChanged: { if (!snapEnabled) _clearSnapGuides() }

    // Effective snap grid size: follow visual grid when syncToGrid is on.
    readonly property int effectiveSnapGridSize: GlobalProperties.snapSyncToGrid
                                                 ? GlobalProperties.minWgrid
                                                 : GlobalProperties.snapGridSize

    property real snapGuideX:      -1   // canvas-space X of grid snap guide
    property real snapGuideY:      -1   // canvas-space Y of grid snap guide
    property var  alignGuidesX:    []   // canvas-space X positions of node-alignment guides
    property var  alignGuidesY:    []   // canvas-space Y positions of node-alignment guides
    property bool anyNodeSnapping: false

    // Guide visibility opacity — fades out after drag ends
    property real guideOpacity: 0

    onAnyNodeSnappingChanged: {
        if (anyNodeSnapping) {
            guideFadeTimer.stop()
            guideFade.stop()
            guideOpacity = 0.82
        } else {
            guideFadeTimer.restart()
        }
    }

    Timer {
        id: guideFadeTimer
        interval: 160
        onTriggered: guideFade.start()
    }
    NumberAnimation {
        id: guideFade
        target: root; property: "guideOpacity"
        to: 0; duration: 380; easing.type: Easing.InQuad
        onStopped: { if (!root.anyNodeSnapping) root.guideOpacity = 0 }
    }

    function _clearSnapGuides() {
        snapGuideX     = -1;   snapGuideY     = -1
        alignGuidesX   = [];   alignGuidesY   = []
        anyNodeSnapping = false
    }

    // ── Centralized snap computation ────────────────────────────────────────
    // Called by each node's drag handler. Returns snapped Qt.point and updates
    // all guide state as a side-effect.
    function computeSnap(rawX, rawY, draggedItem) {
        if (!root.snapEnabled) return Qt.point(rawX, rawY)

        var sg        = root.effectiveSnapGridSize
        var zm        = root.zoomScale
        // Convert screen-pixel radius to canvas units
        var threshold = GlobalProperties.snapRadius / zm
        var mode      = GlobalProperties.snapMode

        var snapX = rawX,  snapY = rawY
        var gx    = -1,    gy    = -1
        var axList = [],   ayList = []

        // ── Grid snap ───────────────────────────────────────────────────────
        if (sg > 0) {
            var gridX = Math.round(rawX / sg) * sg
            var gridY = Math.round(rawY / sg) * sg

            if (mode === "soft") {
                if (Math.abs(gridX - rawX) <= threshold) { snapX = gridX; gx = snapX }
                if (Math.abs(gridY - rawY) <= threshold) { snapY = gridY; gy = snapY }
            } else {
                snapX = gridX; snapY = gridY; gx = snapX; gy = snapY
            }
        }

        // ── Node alignment snap ─────────────────────────────────────────────
        if (GlobalProperties.snapToNodes && draggedItem) {
            var alignThr = Math.max(threshold * 1.5, 12 / zm)
            var nodeW    = draggedItem.width
            var nodeH    = draggedItem.height

            var bestDx   = alignThr + 1
            var bestDy   = alignThr + 1
            var bestSX   = snapX
            var bestSY   = snapY
            var newAxList = [], newAyList = []

            // Dragged node snap points: left, center, right / top, center, bottom
            var myXPts = [rawX, rawX + nodeW * 0.5, rawX + nodeW]
            var myYPts = [rawY, rawY + nodeH * 0.5, rawY + nodeH]

            for (var i = 0; i < nodes.model.count; i++) {
                var other = nodes.itemAt(i)
                if (!other || other === draggedItem) continue

                var oXPts = [other.x, other.x + other.width * 0.5, other.x + other.width]
                var oYPts = [other.y, other.y + other.height * 0.5, other.y + other.height]

                for (var oi = 0; oi < oXPts.length; oi++) {
                    for (var mi = 0; mi < myXPts.length; mi++) {
                        var d = Math.abs(myXPts[mi] - oXPts[oi])
                        if (d < bestDx) {
                            bestDx    = d
                            bestSX    = rawX + (oXPts[oi] - myXPts[mi])
                            newAxList = [oXPts[oi]]
                        }
                    }
                }
                for (var oj = 0; oj < oYPts.length; oj++) {
                    for (var mj = 0; mj < myYPts.length; mj++) {
                        var dy2 = Math.abs(myYPts[mj] - oYPts[oj])
                        if (dy2 < bestDy) {
                            bestDy    = dy2
                            bestSY    = rawY + (oYPts[oj] - myYPts[mj])
                            newAyList = [oYPts[oj]]
                        }
                    }
                }
            }

            if (bestDx <= alignThr) { snapX = bestSX; gx = snapX; axList = newAxList }
            if (bestDy <= alignThr) { snapY = bestSY; gy = snapY; ayList = newAyList }
        }

        root.snapGuideX    = gx
        root.snapGuideY    = gy
        root.alignGuidesX  = axList
        root.alignGuidesY  = ayList
        root.anyNodeSnapping = (gx >= 0 || gy >= 0 || axList.length > 0 || ayList.length > 0)

        return Qt.point(snapX, snapY)
    }

    // ── Edge snap for resize handles ────────────────────────────────────────
    // Called by ResizeHandle during drag. rawEdgeX/rawEdgeY are the absolute
    // canvas positions of the edge being moved; pass null when that axis is fixed.
    // Updates the same guide overlays used by drag snap.
    function computeEdgeSnap(rawEdgeX, rawEdgeY, draggedItem) {
        if (!root.snapEnabled) {
            _clearSnapGuides()
            return Qt.point(rawEdgeX !== null ? rawEdgeX : 0,
                            rawEdgeY !== null ? rawEdgeY : 0)
        }

        var sg        = root.effectiveSnapGridSize
        var zm        = root.zoomScale
        var threshold = GlobalProperties.snapRadius / zm
        var mode      = GlobalProperties.snapMode

        var snapX = rawEdgeX !== null ? rawEdgeX : 0
        var snapY = rawEdgeY !== null ? rawEdgeY : 0
        var gx = -1, gy = -1
        var axList = [], ayList = []

        // ── Grid snap ───────────────────────────────────────────────────────
        if (rawEdgeX !== null && sg > 0) {
            var gridX = Math.round(rawEdgeX / sg) * sg
            if (mode === "soft") {
                if (Math.abs(gridX - rawEdgeX) <= threshold) { snapX = gridX; gx = snapX }
            } else { snapX = gridX; gx = snapX }
        }
        if (rawEdgeY !== null && sg > 0) {
            var gridY = Math.round(rawEdgeY / sg) * sg
            if (mode === "soft") {
                if (Math.abs(gridY - rawEdgeY) <= threshold) { snapY = gridY; gy = snapY }
            } else { snapY = gridY; gy = snapY }
        }

        // ── Node alignment snap ─────────────────────────────────────────────
        if (GlobalProperties.snapToNodes && draggedItem) {
            var alignThr  = Math.max(threshold * 1.5, 12 / zm)
            var bestDx    = alignThr + 1
            var bestDy    = alignThr + 1

            for (var i = 0; i < nodes.model.count; i++) {
                var other = nodes.itemAt(i)
                if (!other || other === draggedItem) continue

                if (rawEdgeX !== null) {
                    var oXPts = [other.x, other.x + other.width * 0.5, other.x + other.width]
                    for (var oi = 0; oi < oXPts.length; oi++) {
                        var d = Math.abs(rawEdgeX - oXPts[oi])
                        if (d < bestDx) { bestDx = d; snapX = oXPts[oi]; axList = [oXPts[oi]] }
                    }
                }
                if (rawEdgeY !== null) {
                    var oYPts = [other.y, other.y + other.height * 0.5, other.y + other.height]
                    for (var oj = 0; oj < oYPts.length; oj++) {
                        var dy2 = Math.abs(rawEdgeY - oYPts[oj])
                        if (dy2 < bestDy) { bestDy = dy2; snapY = oYPts[oj]; ayList = [oYPts[oj]] }
                    }
                }
            }
            if (axList.length > 0) gx = snapX
            if (ayList.length > 0) gy = snapY
        }

        root.snapGuideX     = gx
        root.snapGuideY     = gy
        root.alignGuidesX   = axList
        root.alignGuidesY   = ayList
        root.anyNodeSnapping = (gx >= 0 || gy >= 0 || axList.length > 0 || ayList.length > 0)

        return Qt.point(snapX, snapY)
    }

    signal nodeConnected(var node1, var node2)

    onNodeOnFocusChanged: {
        // Deselect all nodes, then mark the new focused one
        for (let i = 0; i < nodes.model.count; i++) {
            let item = nodes.itemAt(i)
            if (item) item.isSelected = false
        }
        if (nodeOnFocus) {
            nodeOnFocus.isSelected = true
            console.log('>>' + nodeOnFocus.behaviourObject.title)
        }
    }

    property bool rightDrawerOpened: false
    property bool bottomDrawerOpened: false
    property bool isAnimatingCenter: false

    property int topBarHeight: 48
    property string selectedPanel: ""
    property string currentProject: WorkspaceManager.currentWorkspace !== "" ? WorkspaceManager.currentWorkspace : "Untitled Project"


    anchors.fill: parent
    clip: true

    color: ThemeManager.backgroundColor

    onWidthChanged: {
        viewSubWindowsWidthHeightArea()
    }

    onHeightChanged: {
        viewSubWindowsWidthHeightArea()
    }

    function clamp(value, min, max) {
      return Math.min(Math.max(value, min), max);
    }

    Connections {
        target: viewPort

        function onBehaviourAdded(obj){
            nodes.model.append({'object': obj, 'uuid': viewPort.getUUIDFromBehaviour(obj)})
        }

        function onBehavioursCleared() {
            nodeConnections.model.clear()
            nodes.model.clear()
            rectsArray.clear()
        }

        function onViewportRestoreRequested(x, y, scale) {
            zoomScale = scale
            mycanvas.x = x
            mycanvas.y = y
        }

        function onBehaviourRemoved(obj, uuid) {
            for (var i = 0; i < nodes.model.count; i++) {
                if (nodes.model.get(i).uuid === uuid) {
                    nodes.model.remove(i)
                    break
                }
            }
            for (var ri = 0; ri < rectsArray.count; ri++) {
                if (rectsArray.get(ri).uuid === uuid) {
                    rectsArray.remove(ri)
                    break
                }
            }
            // Remove visual connection lines associated with this node
            for (var ci = nodeConnections.model.count - 1; ci >= 0; ci--) {
                var cm = nodeConnections.model.get(ci)
                if (cm.outputUuid === uuid || cm.inputUuid === uuid)
                    nodeConnections.model.remove(ci)
            }
        }

        function onConnectionAdded(outputUuid, outputMethod, inputUuid, inputMethod) {
            if (!root.m_suppressConnectionDraw)
                Qt.callLater(function() { drawSavedConnection(outputUuid, outputMethod, inputUuid, inputMethod) })
        }

        function onConnectionRemoved(outputUuid, outputMethod, inputUuid, inputMethod) {
            for (var i = nodeConnections.model.count - 1; i >= 0; i--) {
                var m = nodeConnections.model.get(i)
                if (m.outputUuid === outputUuid && m.inputUuid === inputUuid &&
                    m.methodSignature1 === outputMethod && m.methodSignature2 === inputMethod) {
                    nodeConnections.model.remove(i)
                    break
                }
            }
        }

        // Visual connection drawing is managed by QML (manual) or restoreAllConnections() (load).
        function onBehaviourConnection(source, target){}
    }

    function viewSubWindowsWidthHeightArea() {
        // Re-anchor the canvas so the same world point stays centered after resize.
        if (!mycanvas.initialized) return
        mycanvas.x = containerCanvas.width  / 2 - viewCenterX * zoomScale
        mycanvas.y = containerCanvas.height / 2 - viewCenterY * zoomScale
    }


    function getBehaviourGreaterZ(){
        let aux = []
        aux = aux.concat(behavioursZ);
        return aux.sort()[aux.length - 1];
    }

    // Converts viewport coordinates to mycanvas local coordinates.
    function toLocal(vx, vy) {
        return Qt.point(
            (vx - mycanvas.x) / zoomScale,
            (vy - mycanvas.y) / zoomScale
        )
    }

    function detectNodeByMousePosition(x: double, y: double) {
        for (let i = 0; i < nodes.model.count; i++) {
            let node = nodes.model.get(i)['object']
            if ((x >= node.x && x <= node.x + node.width) &&
                (y >= node.y && y <= node.y + node.height))
                return node
        }
        return undefined
    }

    Keys.enabled: true
    Keys.onPressed: {
        if (event.key === Qt.Key_Shift) {
            event.accepted = true
        } else if (event.key === Qt.Key_S && (event.modifiers & Qt.ControlModifier)) {
            if (WorkspaceManager.currentWorkspace !== "") {
                const ok = viewPort.saveWorkspace(WorkspaceManager.currentWorkspace)
                ToastManager.show(ok ? "Project saved" : "Failed to save project",
                                  ok ? "success" : "error")
            } else {
                saveWorkspaceDialog.open()
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Z && (event.modifiers & Qt.ControlModifier)) {
            viewPort.undo()
            event.accepted = true
        } else if (event.key === Qt.Key_Y && (event.modifiers & Qt.ControlModifier)) {
            viewPort.redo()
            event.accepted = true
        } else if (event.key === Qt.Key_G && !event.modifiers) {
            GlobalProperties.snapEnabled = !GlobalProperties.snapEnabled
            event.accepted = true
        }
    }

    Qaterial.MiniFabButton {
        id: fabRightMenu
        visible: nodeOnFocus !== null && nodeOnFocus !== undefined
        anchors.right: parent.right
        anchors.top: topBar.bottom
        anchors.margins: 8
        z: 100

        icon.source: Qaterial.Icons.tune
        icon.color: ThemeManager.primaryColor
        flat: false
        radius: 6

        onClicked: {
            if(rightDrawerOpened)
                drawer.close()
            else
                drawer.open()
        }
    }

    NodeSettings {
        id: drawer
        modal: false
        interactive: false
        topMargin: topBar.height
        height: parent.height - topBar.height - statusBar.height

        viewPortWindow: viewPort
        selectedObjectView: root.nodeOnFocus

        onOpened: {
            rightDrawerOpened = true
        }

        onClosed: {
            rightDrawerOpened = false
        }

        onXChanged: {
            if (x > 0) {
                fabRightMenu.anchors.rightMargin = parent.width - x + 8
                viewRect.anchors.rightMargin = parent.width - x + 8
            }
        }
    }

    MouseArea {
        id: mouseAreaGlobal
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        hoverEnabled: true
        propagateComposedEvents: false
        preventStealing: true
        z: 10
        enabled: false
        visible: mouseAreaGlobal.enabled

        onClicked: {
            mouseAreaGlobal.enabled = false
            isConnecting = false

            let lp   = toLocal(mouse.x, mouse.y)
            let node = detectNodeByMousePosition(lp.x, lp.y)
            let vr   = node ? node.viewRect : undefined
            let lastConnection = nodeConnections.model.count - 1

            if (vr) {
                let conn = vr.connectionOnXYPosition(lp.x, lp.y)
                if (conn) {
                    // Capture everything needed BEFORE touching the model (model.get returns a live proxy)
                    let n1        = nodeConnections.model.get(lastConnection)
                    let outUuid   = viewPort.getUUIDFromBehaviour(n1['node'].behaviourObject)
                    let outMethod = n1['methodSignature1']
                    let inUuid    = viewPort.getUUIDFromBehaviour(node)
                    let inMethod  = conn.name
                    if (outUuid && inUuid && outMethod && inMethod) {
                        // Store uuids in the model entry so onBehaviourRemoved/onConnectionRemoved can identify it
                        nodeConnections.model.set(lastConnection, {
                            outputUuid: outUuid, inputUuid: inUuid,
                            methodSignature2: inMethod, node2: node
                        })
                        // Record undo; suppress visual redraw since we manually snap the line if valid
                        m_suppressConnectionDraw = true
                        let ok = viewPort.addConnectionWithUndo(outUuid, outMethod, inUuid, inMethod)
                        m_suppressConnectionDraw = false
                        
                        if (ok) {
                            shapeConn.circleConn2   = conn.circleConn
                            shapeConn.viewRectConn2 = node
                            shapeConn = undefined
                        } else {
                            shapeConn = undefined
                            nodeConnections.model.remove(lastConnection)
                        }
                    } else {
                        nodeConnections.model.remove(lastConnection)
                    }
                } else {
                    nodeConnections.model.remove(lastConnection)
                }
            } else {
                nodeConnections.model.remove(lastConnection)
            }

            shapeConn = undefined
            mouse.accepted = false
        }

        onPositionChanged: {
            mouseXX = mouse.x
            mouseYY = mouse.y
            mouse.accepted = false

            let lp = toLocal(mouse.x, mouse.y)
            let node = detectNodeByMousePosition(lp.x, lp.y)
            if (node && node.viewRect)
                node.viewRect.connectionOnXYPosition(lp.x, lp.y)
        }
    }

    MouseArea {
        id: mouseZoom
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        propagateComposedEvents: true
        hoverEnabled: true

        property real zoomMouseX: 0
        property real zoomMouseY: 0

        onClicked: {
            root.focus = true
        }

        onPositionChanged: {
            zoomMouseX = mouse.x
            zoomMouseY = mouse.y
        }

        onWheel: {
            if (isConnecting)
                return

            var oldZoom = zoomScale
            var newZoom = oldZoom + (wheel.angleDelta.y > 0 ? 0.1 : -0.1)
            newZoom = clamp(newZoom, minZoom, maxZoom)

            // Keep the content point under the mouse stationary during zoom.
            // Visual position of workspace origin: mycanvas.x + localX * zoom
            // => mycanvas.x_new = mouseX - (mouseX - mycanvas.x) * newZoom / oldZoom
            var mx = mouseZoom.zoomMouseX
            var my = mouseZoom.zoomMouseY
            mycanvas.x = mx - (mx - mycanvas.x) * newZoom / oldZoom
            mycanvas.y = my - (my - mycanvas.y) * newZoom / oldZoom

            canvasScale.origin.x = 0
            canvasScale.origin.y = 0
            zoomScale = newZoom
        }
    }

    ParallelAnimation {
        id: zoomGroupAnim
        NumberAnimation { id: zoomAnim; target: root; property: "zoomScale"; duration: 400; easing.type: Easing.InOutCubic }
        NumberAnimation { id: zoomAnimX; target: mycanvas; property: "x"; duration: 400; easing.type: Easing.InOutCubic }
        NumberAnimation { id: zoomAnimY; target: mycanvas; property: "y"; duration: 400; easing.type: Easing.InOutCubic }
    }

    function animateZoomToCenter(newZoom) {
        var targetScreenX = containerCanvas.width / 2
        var targetScreenY = containerCanvas.height / 2
        
        var oldZoom = zoomScale
        var targetX = targetScreenX - (targetScreenX - mycanvas.x) * newZoom / oldZoom
        var targetY = targetScreenY - (targetScreenY - mycanvas.y) * newZoom / oldZoom
        
        zoomAnim.to = newZoom
        zoomAnimX.to = targetX
        zoomAnimY.to = targetY
        zoomGroupAnim.start()
    }



    Rectangle {
        id: containerCanvas
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: "transparent"

        // Global hover tracker — HoverHandler propagates through all child items
        // without stealing events, so it works even when the mouse is over a node.
        HoverHandler {
            id: globalHover
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        }
        clip: true

        // ── Workspace item ───────────────────────────────────────────────────────
        // ── Infinite grid (viewport-fixed canvas) ────────────────────────────────
        // Viewport-sized only — no large texture allocation.
        // Infinite illusion via panOffset % cellSize.
        // LOD: at low zoom only major dots (~190) are drawn, avoiding the
        //      ~5 184 arc calls that caused drag lag at zoom=1.
        ViewportGridCanvas {
            id: gridCanvas
            anchors.fill: parent
            panX:     mycanvas.x
            panY:     mycanvas.y
            zoom:     zoomScale
            minWgrid: root.minWgrid
            pattern:  GlobalProperties.gridPattern
        }
        Item {
            id: mycanvas
            width:  10000
            height: 10000

            property bool initialized: false

            // Keep viewCenterX/Y and C++ viewport state in sync when panning.
            onXChanged: if (initialized) {
                root.viewCenterX  = (containerCanvas.width  / 2 - x) / zoomScale
                viewPort.viewportX = x
            }
            onYChanged: if (initialized) {
                root.viewCenterY  = (containerCanvas.height / 2 - y) / zoomScale
                viewPort.viewportY = y
            }

            Behavior on x {
                enabled: root.isAnimatingCenter
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.InOutCubic
                    onRunningChanged: if (!running) root.isAnimatingCenter = false
                }
            }
            Behavior on y {
                enabled: root.isAnimatingCenter
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.InOutCubic
                }
            }

            Component.onCompleted: {
                // Qt.callLater defers until after the first layout pass,
                // guaranteeing containerCanvas.width/height are final.
                Qt.callLater(function() {
                    mycanvas.x = containerCanvas.width  / 2 - 5000 * zoomScale
                    mycanvas.y = containerCanvas.height / 2 - 5000 * zoomScale
                    mycanvas.initialized = true
                })
            }

            transform: Scale {
                id: canvasScale
                origin.x: 0
                origin.y: 0
                xScale: zoomScale
                yScale: zoomScale
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent

                drag.smoothed: true
                drag.target: isConnecting ? undefined : mycanvas

                hoverEnabled: true
                property bool isHoveringConnection: false

                cursorShape: dragArea.drag.active ? Qt.ClosedHandCursor : (isHoveringConnection ? Qt.PointingHandCursor : Qt.OpenHandCursor)

                onPositionChanged: {
                    if (isConnecting || dragArea.drag.active) {
                        isHoveringConnection = false;
                        return;
                    }
                    
                    var px = mouse.x;
                    var py = mouse.y;
                    var bestDist = 15;
                    var hitFound = false;
                    
                    function getBezierPoint(t, p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y) {
                        var u = 1 - t;
                        var tt = t * t, uu = u * u;
                        var uuu = uu * u, ttt = tt * t;
                        var x = uuu * p0x + 3 * uu * t * p1x + 3 * u * tt * p2x + ttt * p3x;
                        var y = uuu * p0y + 3 * uu * t * p1y + 3 * u * tt * p2y + ttt * p3y;
                        return {x: x, y: y};
                    }

                    for (var i = 0; i < nodeConnections.model.count; i++) {
                        var shapeItem = nodeConnections.itemAt(i);
                        if (!shapeItem) continue;

                        var minD = Number.MAX_VALUE;
                        // Use 10 segments for faster hover evaluation
                        for (var s = 0; s <= 10; s++) {
                            var pt = getBezierPoint(s / 10, 
                                shapeItem.startXPos, shapeItem.startYPos,
                                shapeItem.ctrl1XPos, shapeItem.ctrl1YPos,
                                shapeItem.ctrl2XPos, shapeItem.ctrl2YPos,
                                shapeItem.endXPos, shapeItem.endYPos);
                            
                            var dx = px - pt.x;
                            var dy = py - pt.y;
                            var d = Math.sqrt(dx*dx + dy*dy);
                            if (d < minD) minD = d;
                        }
                        
                        if ((minD * zoomScale) < bestDist) {
                            hitFound = true;
                            break;
                        }
                    }
                    
                    isHoveringConnection = hitFound;
                }

                onClicked: {
                    root.focus = true
                    nodeOnFocus = null

                    if (isConnecting) return;

                    // ── Hit Test Connections ──
                    var px = mouse.x;
                    var py = mouse.y;
                    
                    var bestDist = 15; // 15 pixels tolerance
                    var hitIndex = -1;
                    
                    // Simple bezier evaluation function
                    function getBezierPoint(t, p0x, p0y, p1x, p1y, p2x, p2y, p3x, p3y) {
                        var u = 1 - t;
                        var tt = t * t, uu = u * u;
                        var uuu = uu * u, ttt = tt * t;
                        var x = uuu * p0x + 3 * uu * t * p1x + 3 * u * tt * p2x + ttt * p3x;
                        var y = uuu * p0y + 3 * uu * t * p1y + 3 * u * tt * p2y + ttt * p3y;
                        return {x: x, y: y};
                    }

                    for (var i = 0; i < nodeConnections.model.count; i++) {
                        var shapeItem = nodeConnections.itemAt(i);
                        if (!shapeItem) continue;

                        var minD = Number.MAX_VALUE;
                        // Approximate bezier with 20 segments
                        for (var s = 0; s <= 20; s++) {
                            var pt = getBezierPoint(s / 20, 
                                shapeItem.startXPos, shapeItem.startYPos,
                                shapeItem.ctrl1XPos, shapeItem.ctrl1YPos,
                                shapeItem.ctrl2XPos, shapeItem.ctrl2YPos,
                                shapeItem.endXPos, shapeItem.endYPos);
                            
                            var dx = px - pt.x;
                            var dy = py - pt.y;
                            var d = Math.sqrt(dx*dx + dy*dy);
                            if (d < minD) minD = d;
                        }
                        
                        // Because distance is calculated in canvas unscaled coordinates,
                        // we must scale the tolerance relative to the zoom.
                        var scaledDist = minD * zoomScale;
                        if (scaledDist < bestDist) {
                            bestDist = scaledDist;
                            hitIndex = i;
                        }
                    }

                    if (hitIndex !== -1) {
                        var connData = nodeConnections.model.get(hitIndex);
                        // Open radial menu
                        var globalPos = dragArea.mapToItem(root, mouse.x, mouse.y);
                        connMenu.originX = globalPos.x;
                        connMenu.originY = globalPos.y;
                        connMenu.connectionIndex = hitIndex;
                        connMenu.outUuid = connData.outputUuid;
                        connMenu.inUuid = connData.inputUuid;
                        connMenu.outMethod = connData.methodSignature1;
                        connMenu.inMethod = connData.methodSignature2;
                        
                        // Extract names if available
                        connMenu.outNodeName = connData.node ? connData.node.title : "Nó Origem";
                        connMenu.inNodeName = connData.node2 ? connData.node2.title : "Nó Destino";
                        
                        connMenu.open();
                    }
                }
            }

            Rectangle {
                id: mycanvasBody
                anchors.fill: parent
                color: "transparent"

                // ── Origin indicator at (5000, 5000) = display (0, 0) ────────
                ViewportOriginMarker {
                    id: originMarker
                    x: 5000
                    y: 5000
                }

                Repeater {
                    id: nodeConnections

                    model: ListModel {}

                    delegate: Shape {
                        id: shape
                        antialiasing: true
                        smooth: true
                        z: Number.MAX_VALUE

                        property var circleConnPoint
                        property var circleConnPoint2
                        property var circleConn2
                        property var viewRectConn2

                        property real dashOffset: 0

                        // Exposed for hit testing
                        property real startXPos: shapepath.startX
                        property real startYPos: shapepath.startY
                        property real endXPos: cubicPath.x
                        property real endYPos: cubicPath.y
                        property real ctrl1XPos: cubicPath.control1X
                        property real ctrl1YPos: cubicPath.control1Y
                        property real ctrl2XPos: cubicPath.control2X
                        property real ctrl2YPos: cubicPath.control2Y

                        Component.onCompleted: {
                            circleConnPoint = model.circleConn.mapToItem(parent, 0, 0)
                            if (model.isRestored) {
                                // Restored connection (undo/redo/load): anchor to target port
                                circleConn2   = model.initCircleConn2
                                viewRectConn2 = model.initViewRectConn2
                                // Recompute positions after layout
                                Qt.callLater(function() {
                                    circleConnPoint  = model.circleConn.mapToItem(shape.parent, 0, 0)
                                    if (circleConn2)
                                        circleConnPoint2 = circleConn2.mapToItem(shape.parent, 0, 0)
                                })
                            } else {
                                // New in-progress connection drawn by user
                                shapeConn = shape
                            }
                        }

                        onCircleConn2Changed: {
                            if (circleConn2) {
                                circleConnPoint2 = circleConn2.mapToItem(parent, 0, 0)
                            } else {
                                nodeConnections.model.remove(index)
                            }
                        }

                        Connections {
                            target: model.node
                            function onCloseButtonClicked() { nodeConnections.model.remove(index) }
                            function onXChanged()      { circleConnPoint = model.circleConn.mapToItem(parent, 0, 0) }
                            function onYChanged()      { circleConnPoint = model.circleConn.mapToItem(parent, 0, 0) }
                            function onWidthChanged()  { circleConnPoint = model.circleConn.mapToItem(parent, 0, 0) }
                            function onHeightChanged() { circleConnPoint = model.circleConn.mapToItem(parent, 0, 0) }
                        }

                        Connections {
                            target: viewRectConn2
                            function onXChanged()      { circleConnPoint2 = circleConn2.mapToItem(parent, 0, 0) }
                            function onYChanged()      { circleConnPoint2 = circleConn2.mapToItem(parent, 0, 0) }
                            function onWidthChanged()  { circleConnPoint2 = circleConn2.mapToItem(parent, 0, 0) }
                            function onHeightChanged() { circleConnPoint2 = circleConn2.mapToItem(parent, 0, 0) }
                        }

                        ShapePath {
                            id: shapepath
                            strokeColor: model.circleConn.color
                            strokeWidth: 2
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            strokeStyle: ShapePath.DashLine
                            dashPattern: [8, 4]

                            // Marching ants — animate ShapePath.dashOffset directly
                            // so the renderer marks the path dirty each frame.
                            NumberAnimation on dashOffset {
                                from: 0
                                to: -12
                                duration: 400
                                loops: Animation.Infinite
                                running: true
                            }

                            startX: circleConnPoint.x + model.circleConn.width / 2
                            startY: circleConnPoint.y + model.circleConn.height / 2

                            PathCubic {
                                id: cubicPath
                                readonly property real ex: circleConn2
                                    ? circleConnPoint2.x + circleConn2.width  / 2
                                    : (mouseAreaGlobal.mouseX - mycanvas.x) / zoomScale
                                readonly property real ey: circleConn2
                                    ? circleConnPoint2.y + circleConn2.height / 2
                                    : (mouseAreaGlobal.mouseY - mycanvas.y) / zoomScale

                                // Control points: horizontal tangents from each endpoint.
                                // Offset proportional to horizontal distance for a natural S-curve.
                                readonly property real dx: Math.abs(ex - shapepath.startX) * 0.5 + 40

                                x: ex
                                y: ey
                                control1X: shapepath.startX + dx
                                control1Y: shapepath.startY
                                control2X: ex - dx
                                control2Y: ey
                            }
                        }
                    }
                }

                Repeater {
                    id: nodes

                    property var objectToDelete

                    model: ListModel {
                        onCountChanged: {
                            if (nodes.objectToDelete) {
                                viewPort.removeBehaviourObject(nodes.objectToDelete)
                                nodes.objectToDelete = null
                            }
                        }
                    }

                    delegate: ViewComponentRectV2 {
                        id: viewComponentRectV2

                        // Snap — centralized functions in ViewPortWindow
                        snapEnabled:       root.snapEnabled
                        snapGridSize:      root.effectiveSnapGridSize
                        viewportSnap:      root.computeSnap
                        viewportEdgeSnap:  root.computeEdgeSnap

                        onXChanged: { if (isDragging && nodeOnFocus !== this) nodeOnFocus = this }
                        onYChanged: { if (isDragging && nodeOnFocus !== this) nodeOnFocus = this }

                        onResizeEnded: root._clearSnapGuides()

                        onFocusChanged: {
                            if (focus) nodeOnFocus = this
                        }

                        onConnectionSocketClicked: function(conn) {
                            isConnecting = true
                            nodeConnections.model.append({
                                methodSignature1: conn.name, node: this,
                                circleConn: conn.circleConn, node2: this, methodSignature2: "",
                                outputUuid: "", inputUuid: "",
                                initCircleConn2: conn.circleConn, initViewRectConn2: this,
                                isRestored: false
                            })
                            mouseAreaGlobal.enabled = true
                        }

                        borderColor:    ThemeManager.primaryColor
                        rootBodyColor:  "transparent"
                        behaviourObject: model.object

                        Component.onCompleted: {
                            behavioursZ[index] = 0
                            model.object.setViewRectangle(this)
                            rectsArray.append({
                                uuid:          viewPort.getUUIDFromBehaviour(model.object),
                                rectObjTarget: viewComponentRectV2
                            })
                            // Use saved position when non-zero; otherwise center in viewport.
                            if (model.object.x !== 0 || model.object.y !== 0) {
                                // ViewComponentRectV2.Component.onCompleted already set x/y from behaviourObject
                            } else {
                                var cx = (containerCanvas.width  / 2 - mycanvas.x) / zoomScale
                                var cy = (containerCanvas.height / 2 - mycanvas.y) / zoomScale
                                viewComponentRectV2.x = cx - viewComponentRectV2.width  / 2
                                viewComponentRectV2.y = cy - viewComponentRectV2.height / 2
                            }
                        }

                        onZChanged: { behavioursZ[index] = z }

                        Component.onDestruction: {
                            behavioursZ = behavioursZ.slice(0, index)
                                          .concat(behavioursZ.slice(index + 1, behavioursZ.length))
                        }

                        onNodeDragEnded: function(oldX, oldY, newX, newY) {
                            root._clearSnapGuides()
                            viewPort.recordNodeMove(
                                viewPort.getUUIDFromBehaviour(model.object),
                                oldX, oldY, newX, newY)
                        }

                        onNodeResizeEnded: function(oldW, oldH, newW, newH) {
                            root._clearSnapGuides()
                            viewPort.recordNodeResize(
                                viewPort.getUUIDFromBehaviour(model.object),
                                oldW, oldH, newW, newH)
                        }

                        onCloseButtonClicked: {
                            viewPort.removeNodeWithUndo(viewPort.getUUIDFromBehaviour(model.object))
                        }

                        onFrontOneStepClicked: { z += 1 }
                        onBackOneStepClicked:  { z = (z - 1 < 1) ? 0 : z - 1 }
                        onFrontTotalClicked:   { z = getBehaviourGreaterZ() + 1 }
                        onBackTotalClicked:    { z = 0 }
                    }
                }
            }
        }
    }


    // ── Snap guide overlays ────────────────────────────────────────────────────
    // All guide elements use root.guideOpacity which fades out after drag ends.

    // Grid snap — vertical guide
    Rectangle {
        visible: root.snapEnabled && root.snapGuideX >= 0 && root.guideOpacity > 0
        anchors.top:       parent.top
        anchors.bottom:    parent.bottom
        anchors.topMargin: root.topBarHeight
        x:       root.snapGuideX * root.zoomScale + mycanvas.x
        width:   1
        color:   GlobalProperties.snapGuideColor
        opacity: root.guideOpacity
        z: 290
    }

    // Grid snap — horizontal guide
    Rectangle {
        visible: root.snapEnabled && root.snapGuideY >= 0 && root.guideOpacity > 0
        anchors.left:  parent.left
        anchors.right: parent.right
        y:      root.topBarHeight + mycanvas.y + root.snapGuideY * root.zoomScale
        height: 1
        color:   GlobalProperties.snapGuideColor
        opacity: root.guideOpacity
        z: 290
    }

    // Grid snap — crosshair dot
    Rectangle {
        visible: root.snapEnabled && root.snapGuideX >= 0 && root.snapGuideY >= 0
                 && root.guideOpacity > 0
        x: root.snapGuideX * root.zoomScale + mycanvas.x - 5
        y: root.topBarHeight + mycanvas.y + root.snapGuideY * root.zoomScale - 5
        width: 10; height: 10; radius: 5
        color:   GlobalProperties.snapGuideColor
        opacity: root.guideOpacity
        z: 291

        Rectangle {
            anchors.centerIn: parent
            width: 18; height: 18; radius: 9
            color: "transparent"
            border.width: 1
            border.color: parent.color
            opacity: 0.50
        }
    }

    // Coordinate badge — world-space label next to the crosshair
    Rectangle {
        visible: root.snapEnabled && GlobalProperties.snapShowCoords
                 && root.snapGuideX >= 0 && root.snapGuideY >= 0
                 && root.guideOpacity > 0
        x: root.snapGuideX * root.zoomScale + mycanvas.x + 10
        y: root.topBarHeight + mycanvas.y + root.snapGuideY * root.zoomScale - 22
        width:  coordBadgeText.implicitWidth + 14
        height: 18
        radius: 4
        color:  Qt.rgba(0, 0, 0, 0.68)
        opacity: root.guideOpacity
        z: 292

        Text {
            id: coordBadgeText
            anchors.centerIn: parent
            // World origin is at canvas (5000, 5000); display as integer world coords
            text: (root.snapGuideX - 5000) + ", " + (root.snapGuideY - 5000)
            font.pixelSize: 10
            font.family: "monospace"
            color: GlobalProperties.snapGuideColor
        }
    }

    // Node alignment guides — vertical lines (blue-tinted)
    Repeater {
        model: root.snapEnabled ? root.alignGuidesX : []
        delegate: Rectangle {
            anchors.top:       parent.top
            anchors.bottom:    parent.bottom
            anchors.topMargin: root.topBarHeight
            x:       modelData * root.zoomScale + mycanvas.x
            width:   1
            color:   "#448aff"
            opacity: root.guideOpacity * 0.85
            z: 290
        }
    }

    // Node alignment guides — horizontal lines (blue-tinted)
    Repeater {
        model: root.snapEnabled ? root.alignGuidesY : []
        delegate: Rectangle {
            anchors.left:  parent.left
            anchors.right: parent.right
            y:      root.topBarHeight + mycanvas.y + modelData * root.zoomScale
            height: 1
            color:  "#448aff"
            opacity: root.guideOpacity * 0.85
            z: 290
        }
    }

    // ─── Top Bar ────────────────────────────────────────────────────────────────
    ViewportTopBar {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        z: 200
        barHeight:      topBarHeight
        currentProject: root.currentProject
        selectedPanel:  root.selectedPanel
        canUndo:        viewPort.canUndo
        canRedo:        viewPort.canRedo
        isDirty:        !viewPort.isClean
        onPanelToggled: function(panel) {
            if (root.selectedPanel === panel) {
                root.selectedPanel = ""
                leftPanelDrawer.close()
            } else {
                root.selectedPanel = panel
                leftPanelDrawer.open()
            }
        }
        onSettingsRequested:    settingsPopup.open()
        onNewProjectRequested:  {
            if (!viewPort.isClean) confirmNewProjectDialog.open()
            else                   doNewProject()
        }
        onSaveRequested: {
            if (WorkspaceManager.currentWorkspace !== "") {
                const ok = viewPort.saveWorkspace(WorkspaceManager.currentWorkspace)
                ToastManager.show(ok ? "Project saved" : "Failed to save project",
                                  ok ? "success" : "error")
            } else {
                saveWorkspaceDialog.open()
            }
        }
        onOpenRequested: openWorkspaceDialog.open()
        onUndoRequested: viewPort.undo()
        onRedoRequested: viewPort.redo()
        onScreenshotRequested: {
            const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, -5)
            const path = appDirPath + "/screenshots/screenshot_" + timestamp + ".png"
            viewPort.takeScreenshot(path)
            ToastManager.show("Screenshot saved", "success")
        }
    }

    // ─── Splash Screen ──────────────────────────────────────────────────────────
    SplashScreen {
        id: splashScreen
        onNewProjectRequested: { /* canvas is already empty — user can start and save later */ }
        onOpenProjectRequested: openWorkspaceDialog.open()
    }

    // ─── Settings Popup ─────────────────────────────────────────────────────────
    SettingsPopup {
        id: settingsPopup
    }

    // ─── Toast Display ──────────────────────────────────────────────────────────
    Toast {
        anchors.top:           topBar.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin:     16
        z: 9900
    }

    // ─── Connection Radial Menu ─────────────────────────────────────────────────
    ConnectionRadialMenu {
        id: connMenu
        z: 9950
    }

    // ─── Nodes List ─────────────────────────────────────────────────────────────
    NodesList {
        id: nodesList
        nodesModel: nodes.model
        containerCanvas: containerCanvas
        mycanvas: mycanvas
        zoomScale: root.zoomScale
        statusBar: statusBar
        topBar: topBar
        topLeftAnchor: topBar
        focusedNode: root.nodeOnFocus
        nodes: nodes
        onNodeSelected: function(nodeItem) {
            root.nodeOnFocus = nodeItem
        }
    }

    // ─── Save Workspace Dialog ───────────────────────────────────────────────────
    Popup {
        id: saveWorkspaceDialog
        width: 380
        x: (parent.width  - width)  / 2
        y: (parent.height - height) / 2
        z: 1000
        modal: true
        padding: 0
        closePolicy: Popup.CloseOnEscape

        background: Rectangle {
            color:  ThemeManager.surfaceColor
            radius: 10
            border.color: Qt.rgba(ThemeManager.borderColor.r,
                                  ThemeManager.borderColor.g,
                                  ThemeManager.borderColor.b, 0.5)
            border.width: 1
        }

        function doConfirm() {
            const name = saveNameField.text.trim()
            if (name === "") return
            const ok = viewPort.saveWorkspace(name)
            GlobalProperties.lastWorkspace = name
            saveWorkspaceDialog.close()
            ToastManager.show(ok ? "Project \"" + name + "\" saved" : "Failed to save project",
                              ok ? "success" : "error")
        }

        Column {
            width: parent.width
            spacing: 0

            // ── Header ─────────────────────────────────────────────────────────
            Item {
                width: parent.width
                height: 64

                Row {
                    anchors.left:           parent.left
                    anchors.leftMargin:     24
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14

                    Qaterial.ColorIcon {
                        source: Qaterial.Icons.contentSaveOutline
                        color:  ThemeManager.primaryColor
                        width: 22; height: 22
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text:           "Save Project"
                            font.pixelSize: 14
                            font.bold:      true
                            color:          ThemeManager.textColor
                        }
                        Text {
                            text:           "Enter a name for this workspace"
                            font.pixelSize: 11
                            color:          ThemeManager.textSecondaryColor
                        }
                    }
                }

                Qaterial.AppBarButton {
                    anchors.right:          parent.right
                    anchors.rightMargin:    8
                    anchors.verticalCenter: parent.verticalCenter
                    icon.source: Qaterial.Icons.close
                    icon.color:  ThemeManager.textSecondaryColor
                    width: 36; height: 36
                    onClicked: saveWorkspaceDialog.close()
                }
            }

            Rectangle { width: parent.width; height: 1; color: ThemeManager.borderColor; opacity: 0.4 }

            // ── Body ───────────────────────────────────────────────────────────
            Item {
                width: parent.width
                height: saveBodyCol.implicitHeight + 48

                Column {
                    id: saveBodyCol
                    x: 24; y: 24
                    width: parent.width - 48
                    spacing: 16

                    // Styled name input
                    Rectangle {
                        width:  parent.width
                        height: 40
                        radius: 6
                        color:  Qt.darker(ThemeManager.surfaceColor, 1.3)
                        border.color: saveNameField.activeFocus
                                           ? ThemeManager.primaryColor
                                           : ThemeManager.borderColor
                        border.width: saveNameField.activeFocus ? 1.5 : 1
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        TextInput {
                            id: saveNameField
                            anchors.fill:        parent
                            anchors.leftMargin:  12
                            anchors.rightMargin: 12
                            verticalAlignment:   TextInput.AlignVCenter

                            text:           WorkspaceManager.currentWorkspace
                            color:          ThemeManager.textColor
                            font.pixelSize: 13
                            selectByMouse:  true
                            selectionColor: Qt.rgba(ThemeManager.primaryColor.r,
                                                    ThemeManager.primaryColor.g,
                                                    ThemeManager.primaryColor.b, 0.4)
                            Keys.onReturnPressed: saveWorkspaceDialog.doConfirm()

                            Text {
                                visible:        parent.text === ""
                                text:           "Project name..."
                                color:          ThemeManager.textSecondaryColor
                                font.pixelSize: 13
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    // Action buttons
                    Row {
                        anchors.right: parent.right
                        spacing: 8

                        Rectangle {
                            width: 80; height: 36; radius: 6
                            color: saveDlgCancelHover.containsMouse
                                       ? Qt.rgba(ThemeManager.borderColor.r,
                                                 ThemeManager.borderColor.g,
                                                 ThemeManager.borderColor.b, 0.25)
                                       : "transparent"
                            border.color: ThemeManager.borderColor
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text:           "Cancel"
                                color:          ThemeManager.textSecondaryColor
                                font.pixelSize: 12
                            }
                            MouseArea {
                                id: saveDlgCancelHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor
                                onClicked:    saveWorkspaceDialog.close()
                            }
                        }

                        Rectangle {
                            readonly property bool ready: saveNameField.text.trim() !== ""
                            width: 80; height: 36; radius: 6
                            color: ready
                                       ? (saveDlgConfirmHover.containsMouse
                                              ? Qt.lighter(ThemeManager.primaryColor, 1.1)
                                              : ThemeManager.primaryColor)
                                       : Qt.rgba(ThemeManager.primaryColor.r,
                                                 ThemeManager.primaryColor.g,
                                                 ThemeManager.primaryColor.b, 0.35)
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text:           "Save"
                                color:          "white"
                                font.pixelSize: 12
                                font.bold:      true
                            }
                            MouseArea {
                                id: saveDlgConfirmHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape:  parent.ready ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked:    saveWorkspaceDialog.doConfirm()
                            }
                        }
                    }
                }
            }
        }
    }

    // ─── Open Workspace Dialog ───────────────────────────────────────────────────
    Popup {
        id: openWorkspaceDialog
        width: 420
        x: (parent.width  - width)  / 2
        y: (parent.height - height) / 2
        z: 1000
        modal: true
        padding: 0
        closePolicy: Popup.CloseOnEscape

        background: Rectangle {
            color:  ThemeManager.surfaceColor
            radius: 10
            border.color: Qt.rgba(ThemeManager.borderColor.r,
                                  ThemeManager.borderColor.g,
                                  ThemeManager.borderColor.b, 0.5)
            border.width: 1
        }

        Column {
            width: parent.width
            spacing: 0

            // ── Header ─────────────────────────────────────────────────────────
            Item {
                width: parent.width
                height: 64

                Row {
                    anchors.left:           parent.left
                    anchors.leftMargin:     24
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14

                    Qaterial.ColorIcon {
                        source: Qaterial.Icons.folderOpenOutline
                        color:  ThemeManager.primaryColor
                        width: 22; height: 22
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text:           "Open Project"
                            font.pixelSize: 14
                            font.bold:      true
                            color:          ThemeManager.textColor
                        }
                        Text {
                            text:           "Select a saved workspace"
                            font.pixelSize: 11
                            color:          ThemeManager.textSecondaryColor
                        }
                    }
                }

                Qaterial.AppBarButton {
                    anchors.right:          parent.right
                    anchors.rightMargin:    8
                    anchors.verticalCenter: parent.verticalCenter
                    icon.source: Qaterial.Icons.close
                    icon.color:  ThemeManager.textSecondaryColor
                    width: 36; height: 36
                    onClicked: openWorkspaceDialog.close()
                }
            }

            Rectangle { width: parent.width; height: 1; color: ThemeManager.borderColor; opacity: 0.4 }

            // ── Body ───────────────────────────────────────────────────────────
            Item {
                width: parent.width
                height: openBodyCol.implicitHeight + 48

                Column {
                    id: openBodyCol
                    x: 16; y: 16
                    width: parent.width - 32
                    spacing: 4

                    // Empty state
                    Item {
                        visible: WorkspaceManager.workspaceList.length === 0
                        width: parent.width
                        height: 80

                        Column {
                            anchors.centerIn: parent
                            spacing: 8

                            Qaterial.ColorIcon {
                                source: Qaterial.Icons.folderOutline
                                color:  ThemeManager.textSecondaryColor
                                width: 28; height: 28
                                anchors.horizontalCenter: parent.horizontalCenter
                                opacity: 0.4
                            }
                            Text {
                                text:           "No saved projects yet"
                                color:          ThemeManager.textSecondaryColor
                                font.pixelSize: 12
                                anchors.horizontalCenter: parent.horizontalCenter
                                opacity: 0.7
                            }
                        }
                    }

                    // Workspace list
                    Repeater {
                        model: WorkspaceManager.workspaceList

                        delegate: Rectangle {
                            id: wsCard
                            readonly property bool isCurrent: modelData === WorkspaceManager.currentWorkspace

                            width:  parent ? parent.width : 0
                            height: 48
                            radius: 6
                            color:  wsDel.containsMouse
                                        ? Qt.rgba(ThemeManager.dangerColor.r,
                                                  ThemeManager.dangerColor.g,
                                                  ThemeManager.dangerColor.b, 0.08)
                                        : wsItemMouse.containsMouse || isCurrent
                                              ? Qt.rgba(ThemeManager.primaryColor.r,
                                                        ThemeManager.primaryColor.g,
                                                        ThemeManager.primaryColor.b,
                                                        isCurrent ? 0.08 : 0.06)
                                              : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }

                            // Active indicator bar
                            Rectangle {
                                visible: wsCard.isCurrent
                                width: 3; height: parent.height * 0.5; radius: 2
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left:           parent.left
                                anchors.leftMargin:     2
                                color: ThemeManager.primaryColor
                                opacity: 0.8
                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left:           parent.left
                                anchors.leftMargin:     16
                                spacing: 10

                                Qaterial.ColorIcon {
                                    source: Qaterial.Icons.vectorSquare
                                    color:  wsCard.isCurrent ? ThemeManager.primaryColor : ThemeManager.textSecondaryColor
                                    width: 16; height: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text:  modelData + (wsCard.isCurrent ? "  (current)" : "")
                                    color: wsCard.isCurrent
                                               ? ThemeManager.primaryColor
                                               : wsItemMouse.containsMouse
                                                     ? ThemeManager.textColor
                                                     : ThemeManager.textSecondaryColor
                                    font.pixelSize: 13
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                }
                            }

                            // Delete button (appears on hover)
                            Rectangle {
                                id: wsDeleteBtn
                                anchors.right:          parent.right
                                anchors.rightMargin:    8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 28; height: 28; radius: 4
                                color: wsDel.containsMouse
                                           ? Qt.rgba(ThemeManager.dangerColor.r,
                                                     ThemeManager.dangerColor.g,
                                                     ThemeManager.dangerColor.b, 0.18)
                                           : "transparent"
                                opacity: wsItemMouse.containsMouse || wsDel.containsMouse ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                                Behavior on color   { ColorAnimation   { duration: 100 } }

                                Qaterial.ColorIcon {
                                    source: Qaterial.Icons.trashCanOutline
                                    color:  ThemeManager.dangerColor
                                    width: 16; height: 16
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    id: wsDel
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape:  Qt.PointingHandCursor
                                    onClicked: {
                                        const name = modelData
                                        WorkspaceManager.deleteWorkspace(name)
                                        ToastManager.show("Deleted \"" + name + "\"", "warning")
                                    }
                                }
                            }

                            MouseArea {
                                id: wsItemMouse
                                anchors.fill:   parent
                                anchors.rightMargin: 36
                                hoverEnabled:   true
                                cursorShape:    Qt.PointingHandCursor
                                onClicked: {
                                    root.m_suppressConnectionDraw = true
                                    viewPort.loadWorkspace(modelData)
                                    root.m_suppressConnectionDraw = false
                                    GlobalProperties.lastWorkspace = modelData
                                    openWorkspaceDialog.close()
                                }
                            }
                        }
                    }

                    // Bottom cancel row
                    Item {
                        width: parent.width
                        height: 48

                        Rectangle {
                            anchors.right:          parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 80; height: 36; radius: 6
                            color: openCancelHover.containsMouse
                                       ? Qt.rgba(ThemeManager.borderColor.r,
                                                 ThemeManager.borderColor.g,
                                                 ThemeManager.borderColor.b, 0.25)
                                       : "transparent"
                            border.color: ThemeManager.borderColor
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text:           "Cancel"
                                color:          ThemeManager.textSecondaryColor
                                font.pixelSize: 12
                            }
                            MouseArea {
                                id: openCancelHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor
                                onClicked:    openWorkspaceDialog.close()
                            }
                        }
                    }
                }
            }
        }
    }

    // ─── Toast Notification ──────────────────────────────────────────────────────
    // ─── Confirm New Project Dialog ───────────────────────────────────────────────
    Popup {
        id: confirmNewProjectDialog
        width: 360
        x: (parent.width  - width)  / 2
        y: (parent.height - height) / 2
        z: 1000
        modal: true
        padding: 0
        closePolicy: Popup.CloseOnEscape

        background: Rectangle {
            color:  ThemeManager.surfaceColor
            radius: 10
            border.color: Qt.rgba(ThemeManager.borderColor.r,
                                  ThemeManager.borderColor.g,
                                  ThemeManager.borderColor.b, 0.5)
            border.width: 1
        }

        Column {
            width: parent.width
            spacing: 0

            Item {
                width: parent.width
                height: 64

                Row {
                    anchors.left:           parent.left
                    anchors.leftMargin:     24
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 14

                    Qaterial.ColorIcon {
                        source: Qaterial.Icons.alertOutline
                        color:  "#ff9800"
                        width: 22; height: 22
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text:           "New Project"
                        font.pixelSize: 14
                        font.bold:      true
                        color:          ThemeManager.textColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Qaterial.AppBarButton {
                    anchors.right:          parent.right
                    anchors.rightMargin:    8
                    anchors.verticalCenter: parent.verticalCenter
                    icon.source: Qaterial.Icons.close
                    icon.color:  ThemeManager.textSecondaryColor
                    width: 36; height: 36
                    onClicked: confirmNewProjectDialog.close()
                }
            }

            Rectangle { width: parent.width; height: 1; color: ThemeManager.borderColor; opacity: 0.4 }

            Item {
                width: parent.width
                height: confirmBodyCol.implicitHeight + 48

                Column {
                    id: confirmBodyCol
                    x: 24; y: 24
                    width: parent.width - 48
                    spacing: 20

                    Text {
                        width: parent.width
                        text: "This project has unsaved changes. They will be permanently lost if you create a new project."
                        color:          ThemeManager.textSecondaryColor
                        font.pixelSize: 13
                        lineHeight:     1.5
                        wrapMode:       Text.WordWrap
                    }

                    Row {
                        anchors.right: parent.right
                        spacing: 8

                        Rectangle {
                            width: 80; height: 36; radius: 6
                            color: confCancelHover.containsMouse
                                       ? Qt.rgba(ThemeManager.borderColor.r,
                                                 ThemeManager.borderColor.g,
                                                 ThemeManager.borderColor.b, 0.25)
                                       : "transparent"
                            border.color: ThemeManager.borderColor
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text:           "Cancel"
                                color:          ThemeManager.textSecondaryColor
                                font.pixelSize: 12
                            }
                            MouseArea {
                                id: confCancelHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor
                                onClicked:    confirmNewProjectDialog.close()
                            }
                        }

                        Rectangle {
                            width: 120; height: 36; radius: 6
                            color: confDiscardHover.containsMouse
                                       ? Qt.lighter(ThemeManager.dangerColor, 1.1)
                                       : ThemeManager.dangerColor
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text:           "Discard & New"
                                color:          "white"
                                font.pixelSize: 12
                                font.bold:      true
                            }
                            MouseArea {
                                id: confDiscardHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor
                                onClicked: {
                                    confirmNewProjectDialog.close()
                                    doNewProject()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function doNewProject() {
        splashScreen.dismissed = true
        WorkspaceManager.newWorkspace()
        ToastManager.show("New project created", "success")
    }

    Component.onCompleted: {
        // Splash always appears — user selects the project to open.
        // No auto-load: recent projects are shown in the splash screen.
    }

    // ─── Connection restoration after workspace load ─────────────────────────────
    Connections {
        target: WorkspaceManager
        function onWorkspaceLoaded(name) {
            console.log("[ViewPort] Workspace loaded signal received:", name, "- scheduling connection restore")
            restoreConnectionsTimer.restart()
            ToastManager.show("Opened \"" + name + "\"", "success")
        }
    }

    Timer {
        id: restoreConnectionsTimer
        interval: 120
        running:  false
        onTriggered: restoreAllConnections()
    }

    function restoreAllConnections() {
        const conns = viewPort.getAllConnections()
        console.log("[ViewPort] Restoring", conns.length, "connections")
        for (let i = 0; i < conns.length; i++) {
            const c = conns[i]
            drawSavedConnection(c.outputUuid, c.outputMethod, c.inputUuid, c.inputMethod)
        }
    }

    function drawSavedConnection(outputUuid, outputMethod, inputUuid, inputMethod) {
        // Deduplicate: skip if this visual already exists
        for (let k = 0; k < nodeConnections.model.count; k++) {
            const ex = nodeConnections.model.get(k)
            if (ex.outputUuid === outputUuid && ex.inputUuid === inputUuid &&
                ex.methodSignature1 === outputMethod && ex.methodSignature2 === inputMethod)
                return
        }
        let sourceRect, targetRect
        for (let i = 0; i < rectsArray.count; i++) {
            const e = rectsArray.get(i)
            if (e.uuid === outputUuid) sourceRect = e.rectObjTarget
            if (e.uuid === inputUuid)  targetRect = e.rectObjTarget
        }
        if (!sourceRect || !targetRect) {
            console.warn("[ViewPort] Cannot find rect for connection", outputUuid, "->", inputUuid)
            return
        }
        const sourceConn = sourceRect.connectionByName(outputMethod)
        const targetConn = targetRect.connectionByName(inputMethod)
        if (!sourceConn || !targetConn || !sourceConn.circleConn || !targetConn.circleConn) {
            console.warn("[ViewPort] Cannot find ports for", outputMethod, "->", inputMethod)
            return
        }
        nodeConnections.model.append({
            outputUuid:        outputUuid,
            inputUuid:         inputUuid,
            methodSignature1:  outputMethod,
            node:              sourceRect,
            circleConn:        sourceConn.circleConn,
            node2:             targetRect,
            methodSignature2:  inputMethod,
            initCircleConn2:   targetConn.circleConn,
            initViewRectConn2: targetRect,
            isRestored:        true
        })
    }

    // ─── Left Panel Drawer ───────────────────────────────────────────────────────
    Drawer {
        id: leftPanelDrawer
        width: 320
        y: topBarHeight
        height: parent.height - topBarHeight
        edge: Qt.LeftEdge
        modal: false
        interactive: false
        z: 199

        background: Rectangle {
            color: Qt.darker(ThemeManager.backgroundColor, 1.2)

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: ThemeManager.primaryColor
                opacity: 0.2
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            Rectangle {
                id: panelHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 44

                color: "transparent"

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: ThemeManager.primaryColor
                    opacity: 0.15
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    text: {
                        if (selectedPanel === "nodes")     return "Nodes"
                        if (selectedPanel === "explorer")  return "Explorer"
                        if (selectedPanel === "variables") return "Variables"
                        if (selectedPanel === "settings")  return "Settings"
                        return ""
                    }
                    font.pixelSize: 13
                    font.bold: true
                    color: ThemeManager.textColor
                }
            }

            Item {
                anchors.top: panelHeader.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                NodesDrawer {
                    id: nodesDrawer
                    anchors.fill: parent
                    visible: selectedPanel === "nodes"

                    onBehaviourSelected: function(path, infos) {
                        viewPort.addBehaviour(path, infos)
                    }
                    onDragStarted: function(path, infos, lx, ly) {
                        var gp = nodesDrawer.mapToItem(root, lx, ly)
                        nodeDragGhost.currentPath  = path
                        nodeDragGhost.currentInfos = infos
                        nodeDragGhost.x = gp.x - nodeDragGhost.width  / 2
                        nodeDragGhost.y = gp.y - nodeDragGhost.height / 2
                        nodeDragGhost.open()
                    }
                    onDragUpdated: function(lx, ly) {
                        var gp = nodesDrawer.mapToItem(root, lx, ly)
                        nodeDragGhost.x = gp.x - nodeDragGhost.width  / 2
                        nodeDragGhost.y = gp.y - nodeDragGhost.height / 2
                    }
                    onDragEnded: function(lx, ly) {
                        nodeDragGhost.close()
                        if (lx < -9000) return  // onCanceled path — don't add node
                        var gp = nodesDrawer.mapToItem(root, lx, ly)
                        if (gp.x > leftPanelDrawer.width + 20)
                            viewPort.addBehaviour(nodeDragGhost.currentPath,
                                                  nodeDragGhost.currentInfos)
                    }
                }

                ExplorerDrawer {
                    anchors.fill: parent
                    visible: selectedPanel === "explorer"
                    rootFolder: "file:///" + appDirPath
                }

                VariablesDrawer {
                    anchors.fill: parent
                    visible: selectedPanel === "variables"
                }
            }
        }
    }

    // ─── Node drag ghost (Popup → renders in Overlay above Drawer) ─────────────
    Popup {
        id: nodeDragGhost
        modal: false
        closePolicy: Popup.NoAutoClose
        padding: 0
        background: null
        z: 200          // must exceed leftPanelDrawer.z (199)
        width: 136; height: 52

        property string currentPath:  ""
        property var    currentInfos: null

        Rectangle {
            anchors.fill: parent; radius: 7
            color: Qt.rgba(ThemeManager.primaryColor.r,
                           ThemeManager.primaryColor.g,
                           ThemeManager.primaryColor.b, 0.92)

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 2
                Text {
                    Layout.fillWidth: true
                    text: nodeDragGhost.currentInfos
                          ? (nodeDragGhost.currentInfos.name || "") : ""
                    font.pixelSize: 12; font.bold: true
                    color: "white"; elide: Text.ElideRight
                }
                Text {
                    text: "→ drop on canvas"
                    font.pixelSize: 9; color: "white"; opacity: 0.7
                }
            }
        }
    }

    Rectangle {
        id: viewRect
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 22 + 8
        anchors.rightMargin: 8
        color: "transparent"
        border.width: 2
        border.color: ThemeManager.primaryColor
        radius: 4

        width: parent.width / 8
        height: parent.height / 8

        Rectangle {
            id: previewContainer
            anchors.fill: parent
            anchors.margins: viewRect.border.width
            color: "transparent"
            clip: true
            radius: 4

            ShaderEffectSource {
                id: previewSource
                sourceItem: containerCanvas
                anchors.fill: parent
                scale: 1
                mipmap: true
                anchors.centerIn: parent
            }
        }

        Rectangle {
            visible: false
            color: "transparent"
            border.width: 1
            border.color: "#ccc"
            radius: 4

            width: viewRect.width / zoomScale
            height: viewRect.height / zoomScale

            x: -(mycanvas.x * viewRect.width) / (containerCanvas.width * zoomScale)
            y: -(mycanvas.y * viewRect.height) / (containerCanvas.height * zoomScale)
        }
    }

    // ─── Bottom Floating Toolbar ────────────────────────────────────────────────
    ViewportBottomToolBar {
        id: bottomToolBar
        visible: !splashScreen.visible
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 48 // Above status bar
        anchors.horizontalCenter: parent.horizontalCenter
        z: 900
        
        zoomScale: root.zoomScale
        minZoom: root.minZoom
        maxZoom: root.maxZoom
        showGrid: GlobalProperties.gridPattern !== "none"
        connectionsMinimized: root.allConnectionsMinimized
        snapEnabled: root.snapEnabled

        onZoomIn: {
            var newZoom = clamp(zoomScale + 0.5, minZoom, maxZoom)
            animateZoomToCenter(newZoom)
        }
        onZoomOut: {
            var newZoom = clamp(zoomScale - 0.5, minZoom, maxZoom)
            animateZoomToCenter(newZoom)
        }
        onResetZoom: {
            animateZoomToCenter(1.0)
        }
        onCenterView: {
            root.isAnimatingCenter = true
            zoomAnim.to = 1.0
            zoomAnimX.to = (containerCanvas.width  - mycanvas.width)  / 2
            zoomAnimY.to = (containerCanvas.height - mycanvas.height) / 2
            zoomGroupAnim.start()
        }
        onToggleGrid: {
            if (GlobalProperties.gridPattern === "none") {
                GlobalProperties.gridPattern = "dots" // Default grid pattern
            } else {
                GlobalProperties.gridPattern = "none"
            }
        }
        onToggleFps: {
            GlobalProperties.showFps = !GlobalProperties.showFps
        }
        onToggleFullscreen: {
            viewPort.setFullScreen(true)
        }
        onToggleConnectionsMinimized: {
            root.allConnectionsMinimized = !root.allConnectionsMinimized
            for (var i = 0; i < nodes.model.count; i++) {
                var nodeItem = nodes.itemAt(i)
                if (nodeItem) {
                    nodeItem.setMinimized(root.allConnectionsMinimized)
                }
            }
        }
        onToggleSnap: {
            GlobalProperties.snapEnabled = !GlobalProperties.snapEnabled
        }
    }

    // ─── Status Bar ─────────────────────────────────────────────────────────────
    ViewportStatusBar {
        id: statusBar
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right
        z: 200
        canvasPosX:      mycanvas.x
        canvasPosY:      mycanvas.y
        containerWidth:  containerCanvas.width
        containerHeight: containerCanvas.height
        zoom:            zoomScale
        hoverX:          globalHover.point.position.x
        hoverY:          globalHover.point.position.y
        nodeOnFocus:     root.nodeOnFocus
        nodeCount:       nodes.model.count
        fpsCount:        viewPort.fpsCount
        showFps:         GlobalProperties.showFps
    }
}
