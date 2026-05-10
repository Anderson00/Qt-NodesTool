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
    property var nodeOnFocus

    // Multi-select
    property var    selectedNodes:   []      // all currently selected node items
    property string toolMode:        "pan"   // "pan" | "select"
    property bool   isShiftHeld:     false
    property var    _groupLeader:    null
    property var    _groupOffsets:   []
    // Rubber-band (canvas-space coords, before zoom/scale transform)
    property bool   isRubberBanding: false
    property real   rubberStartX:    0
    property real   rubberStartY:    0
    property real   rubberEndX:      0
    property real   rubberEndY:      0

    // Group frame drag (mirrors the _groupLeader pattern for multi-select)
    property var _activeFrame:   null   // GroupFrame item being dragged
    property var _frameNodeRefs: []     // [{node, startX, startY}]

    // Copy / paste clipboard
    property var clipboard:    null  // { nodes: [...], conns: [...] }
    property int pasteOffset:  0     // grows by 40 per paste so copies don't overlap

    // Group frame colors (cycled on creation)
    readonly property var _frameColors: ["#4CAF50","#2196F3","#FF9800","#9C27B0","#F44336","#00BCD4","#FF5722","#607D8B"]
    property int _frameColorIdx: 0

    // ── Camera / Visualization state ─────────────────────────────────────────
    property bool showCamera:        false
    property bool showVisualization: false
    // Camera rect in world (canvas) coordinates — owned by CameraFrameItem
    property real cameraWorldX: 4600
    property real cameraWorldY: 4775
    property real cameraWorldW: 800
    property real cameraWorldH: 450

    // World-space point kept at the center of the view.
    // Updated whenever the canvas is panned or zoomed.
    // Initial value = (5000, 5000) = canvas center = "home" = display (0, 0).
    property real viewCenterX: 5000
    property real viewCenterY: 5000

    property var rectsArray: ListModel {}
    property bool allConnectionsMinimized: false

    property bool isCloning: false
    property bool _isPastingVisualization: false
    property bool _wasFullScreenBeforePlay: false

    // Detecção robusta de Fullscreen (compara dimensões da janela com a tela)
    readonly property bool isActuallyFullScreen: (root.width >= Screen.width - 5 && root.height >= Screen.height - 5)

    function startVisualization() {
        if (isCloning) return
        isCloning = true
        root.showVisualization = true
        
        Qt.callLater(function() {
            root._isPastingVisualization = true
            
            // 1. Identify nodes in camera area
            let nodesToClone = []
            for (let i = 0; i < nodes.model.count; i++) {
                let item = nodes.model.get(i)
                if (item.isVisualization) continue
                
                let obj = item.object
                if (obj.x + obj.width >= root.cameraWorldX && obj.x <= root.cameraWorldX + root.cameraWorldW &&
                    obj.y + obj.height >= root.cameraWorldY && obj.y <= root.cameraWorldY + root.cameraWorldH) {
                    nodesToClone.push(item.uuid)
                }
            }
            
            // 2. Clone nodes and map UUIDs
            let uuidMap = {}
            nodesToClone.forEach(oldUuid => {
                let data = viewPort.getNodeData(oldUuid)
                let newUuid = viewPort.pasteNode(data, 0, 0)
                if (newUuid) uuidMap[oldUuid] = newUuid
            })
            
            // 3. Clone connections
            nodesToClone.forEach(oldUuid => {
                let conns = viewPort.getNodeConnections(oldUuid)
                conns.forEach(c => {
                    let outUuid = c.outputUuid; let inUuid = c.inputUuid
                    if (uuidMap[outUuid] && uuidMap[inUuid]) {
                        viewPort.addConnectionByUuids(uuidMap[outUuid], c.outputMethod,
                                                      uuidMap[inUuid], c.inputMethod)
                    }
                })
            })
            
            root._isPastingVisualization = false
            isCloning = false
            
            // Armazena o estado atual e força o Fullscreen se necessário
            root._wasFullScreenBeforePlay = root.isActuallyFullScreen
            if (!root._wasFullScreenBeforePlay) {
                viewPort.setFullScreen(true)
            }
        })
    }

    function stopVisualization() {
        // Se entramos em fullscreen apenas para o play, saímos ao dar stop
        if (root.isActuallyFullScreen && !root._wasFullScreenBeforePlay) {
            viewPort.setFullScreen(true)
        }

        for (let i = nodes.model.count - 1; i >= 0; i--) {
            let item = nodes.model.get(i)
            if (item.isVisualization) {
                viewPort.removeBehaviourObject(item.object)
            }
        }
    }

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
            nodes.model.append({
                'object': obj, 
                'uuid': viewPort.getUUIDFromBehaviour(obj),
                'isVisualization': root._isPastingVisualization
            })
        }

        function onBehavioursCleared() {
            root.selectedNodes = []
            root.nodeOnFocus   = null
            nodeConnections.model.clear()
            nodes.model.clear()
            rectsArray.clear()
            frameModel.clear()
            root._activeFrame    = null
            root._frameNodeRefs  = []
            root.clipboard       = null
            root.pasteOffset     = 0
        }

        function onViewportRestoreRequested(x, y, scale) {
            zoomScale = scale
            mycanvas.x = x
            mycanvas.y = y
        }

        function onWindowFullScreen(full) {
            root.isFullScreen = full
        }

        function onBehaviourRemoved(obj, uuid) {
            for (var i = 0; i < nodes.model.count; i++) {
                if (nodes.model.get(i).uuid === uuid) {
                    // Clean selectedNodes before the item is destroyed
                    var item = nodes.itemAt(i)
                    if (item) {
                        var si = root.selectedNodes.indexOf(item)
                        if (si >= 0) {
                            var arr = root.selectedNodes.slice()
                            arr.splice(si, 1)
                            root.selectedNodes = arr
                            if (root.nodeOnFocus === item)
                                root.nodeOnFocus = arr.length > 0 ? arr[arr.length - 1] : null
                        }
                    }
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


    // ── Z-order management ────────────────────────────────────────────────────
    // Returns all node rects sorted by z ascending.
    function _zSortedRects() {
        var all = []
        for (var i = 0; i < rectsArray.count; i++)
            all.push(rectsArray.get(i).rectObjTarget)
        all.sort(function(a, b) { return a.z - b.z })
        return all
    }

    // Reassign z as 1..N in current order — keeps relative stack intact, no gaps.
    function _compactZ() {
        var sorted = _zSortedRects()
        for (var i = 0; i < sorted.length; i++)
            sorted[i].z = i + 1
    }

    // Swap target with the node immediately above it.
    function _bringForward(target) {
        var sorted = _zSortedRects()
        var idx = sorted.indexOf(target)
        if (idx < 0 || idx === sorted.length - 1) return
        var tmp = sorted[idx + 1].z
        sorted[idx + 1].z = target.z
        target.z = tmp
        _compactZ()
    }

    // Swap target with the node immediately below it.
    function _sendBackward(target) {
        var sorted = _zSortedRects()
        var idx = sorted.indexOf(target)
        if (idx <= 0) return
        var tmp = sorted[idx - 1].z
        sorted[idx - 1].z = target.z
        target.z = tmp
        _compactZ()
    }

    // Place target above every other node.
    function _bringToFront(target) {
        var sorted = _zSortedRects()
        if (sorted.length === 0 || sorted.indexOf(target) === sorted.length - 1) return
        target.z = sorted[sorted.length - 1].z + 1
        _compactZ()
    }

    // Place target below every other node.
    function _sendToBack(target) {
        var sorted = _zSortedRects()
        if (sorted.length === 0 || sorted.indexOf(target) === 0) return
        target.z = sorted[0].z - 1
        _compactZ()
    }

    // ── Multi-select ──────────────────────────────────────────────────────────────

    function _setSelection(items) {
        for (var i = 0; i < nodes.model.count; i++) {
            var it = nodes.itemAt(i)
            if (it) it.isSelected = false
        }
        selectedNodes = items.slice()
        for (var j = 0; j < selectedNodes.length; j++)
            selectedNodes[j].isSelected = true
        nodeOnFocus = selectedNodes.length > 0 ? selectedNodes[selectedNodes.length - 1] : null
    }

    function _addToSelection(item) {
        var idx = selectedNodes.indexOf(item)
        if (idx >= 0) {
            item.isSelected = false
            var arr = selectedNodes.slice()
            arr.splice(idx, 1)
            selectedNodes = arr
            nodeOnFocus = arr.length > 0 ? arr[arr.length - 1] : null
        } else {
            item.isSelected = true
            var arr2 = selectedNodes.slice()
            arr2.push(item)
            selectedNodes = arr2
            nodeOnFocus = item
        }
    }

    function _clearSelection() {
        for (var i = 0; i < nodes.model.count; i++) {
            var it = nodes.itemAt(i)
            if (it) it.isSelected = false
        }
        selectedNodes = []
        nodeOnFocus = null
    }

    function _selectNodesInRect(rx1, ry1, rx2, ry2) {
        var toSelect = []
        for (var i = 0; i < nodes.model.count; i++) {
            var it = nodes.itemAt(i)
            if (!it) continue
            if ((it.x + it.width) > rx1 && it.x < rx2 &&
                (it.y + it.height) > ry1 && it.y < ry2)
                toSelect.push(it)
        }
        if (toSelect.length > 0) _setSelection(toSelect)
        else                     _clearSelection()
    }

    function _deleteSelected() {
        if (selectedNodes.length === 0) return
        var uuids = []
        for (var i = 0; i < selectedNodes.length; i++)
            uuids.push(viewPort.getUUIDFromBehaviour(selectedNodes[i].behaviourObject))
        _clearSelection()
        if (uuids.length === 1) {
            viewPort.removeNodeWithUndo(uuids[0])
        } else {
            viewPort.beginUndoMacro("Delete " + uuids.length + " nodes")
            for (var j = 0; j < uuids.length; j++)
                viewPort.removeNodeWithUndo(uuids[j])
            viewPort.endUndoMacro()
        }
    }

    function _setupGroupDrag(leader) {
        // Always reset first so stale state never leaks into the next drag
        _groupLeader  = null
        _groupOffsets = []
        if (selectedNodes.length <= 1 || selectedNodes.indexOf(leader) < 0) return
        _groupLeader = leader
        for (var i = 0; i < selectedNodes.length; i++) {
            var n = selectedNodes[i]
            if (n === leader) continue
            _groupOffsets.push({
                node:   n,
                dx:     n.x - leader.x,
                dy:     n.y - leader.y,
                startX: n.x,
                startY: n.y
            })
        }
    }

    // Called by the root-level Connections watcher whenever the drag leader moves.
    function _syncGroupFollowers() {
        if (!_groupLeader || _groupOffsets.length === 0) return
        var lx = _groupLeader.x
        var ly = _groupLeader.y
        for (var i = 0; i < _groupOffsets.length; i++) {
            var go = _groupOffsets[i]
            // Disable the Behavior animation so the follower moves instantly with the leader.
            // isGroupFollowing = true → Behavior.enabled = false (synchronous in QML).
            go.node.isGroupFollowing = true
            go.node.x = lx + go.dx
            go.node.y = ly + go.dy
            go.node.isGroupFollowing = false
            if (go.node.behaviourObject) {
                go.node.behaviourObject.x = go.node.x
                go.node.behaviourObject.y = go.node.y
            }
        }
    }

    // ── Copy / Paste / Duplicate ──────────────────────────────────────────────────

    function _copySelected() {
        if (selectedNodes.length === 0) return
        var cbUuids = [], cbNodes = []
        for (var i = 0; i < selectedNodes.length; i++) {
            var uuid = viewPort.getUUIDFromBehaviour(selectedNodes[i].behaviourObject)
            cbUuids.push(uuid)
            cbNodes.push(viewPort.getNodeData(uuid))
        }
        // Collect only connections whose both endpoints are inside the selection
        var cbConns = [], seen = {}
        for (var j = 0; j < cbUuids.length; j++) {
            var conns = viewPort.getNodeConnections(cbUuids[j])
            for (var k = 0; k < conns.length; k++) {
                var c      = conns[k]
                var outIdx = cbUuids.indexOf(c.outputUuid)
                var inIdx  = cbUuids.indexOf(c.inputUuid)
                if (outIdx < 0 || inIdx < 0) continue
                var key = outIdx + "|" + c.outputMethod + "|" + inIdx + "|" + c.inputMethod
                if (seen[key]) continue
                seen[key] = true
                cbConns.push({ outIdx: outIdx, outMethod: c.outputMethod,
                               inIdx:  inIdx,  inMethod:  c.inputMethod })
            }
        }
        clipboard   = { nodes: cbNodes, conns: cbConns }
        pasteOffset = 0
        var n = cbNodes.length
        ToastManager.show("Copied " + n + " node" + (n > 1 ? "s" : ""), "success")
    }

    function _pasteClipboard() {
        if (!clipboard || clipboard.nodes.length === 0) return
        pasteOffset += 40
        var ox = pasteOffset, oy = pasteOffset
        var newUuids = []
        var n = clipboard.nodes.length
        viewPort.beginUndoMacro("Paste " + n + " node" + (n > 1 ? "s" : ""))
        for (var i = 0; i < n; i++) {
            var uuid = viewPort.pasteNode(clipboard.nodes[i], ox, oy)
            newUuids.push(uuid)
        }
        for (var j = 0; j < clipboard.conns.length; j++) {
            var c = clipboard.conns[j]
            if (newUuids[c.outIdx] && newUuids[c.inIdx])
                viewPort.addConnectionWithUndo(newUuids[c.outIdx], c.outMethod,
                                              newUuids[c.inIdx],  c.inMethod)
        }
        viewPort.endUndoMacro()
        // Select pasted nodes after the Repeater has a chance to create items
        var _uuids = newUuids.slice()
        Qt.callLater(function() {
            var pasted = []
            for (var k = 0; k < _uuids.length; k++) {
                for (var ni = 0; ni < nodes.model.count; ni++) {
                    if (nodes.model.get(ni).uuid === _uuids[k]) {
                        var it = nodes.itemAt(ni)
                        if (it) pasted.push(it)
                        break
                    }
                }
            }
            if (pasted.length > 0) _setSelection(pasted)
        })
    }

    // ── Group Frames ──────────────────────────────────────────────────────────────

    function _groupSelected() {
        if (selectedNodes.length < 2) {
            ToastManager.show("Select at least 2 nodes to group", "warning")
            return
        }
        var minX = 1e9, minY = 1e9, maxX = -1e9, maxY = -1e9
        var uuids = []
        for (var i = 0; i < selectedNodes.length; i++) {
            var n = selectedNodes[i]
            if (n.x            < minX) minX = n.x
            if (n.y            < minY) minY = n.y
            if (n.x + n.width  > maxX) maxX = n.x + n.width
            if (n.y + n.height > maxY) maxY = n.y + n.height
            uuids.push(viewPort.getUUIDFromBehaviour(n.behaviourObject))
        }
        var pad   = 24
        var color = root._frameColors[root._frameColorIdx % root._frameColors.length]
        root._frameColorIdx++
        frameModel.append({
            frameLabel:    "Group",
            frameColorStr: color,
            fx: minX - pad,
            fy: minY - pad - 28,
            fw: (maxX - minX) + pad * 2,
            fh: (maxY - minY) + pad * 2 + 28,
            nodeUuidsJson: JSON.stringify(uuids)
        })
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
    Keys.onPressed: function(event) {
        switch (event.key) {
            case Qt.Key_Shift:
                isShiftHeld = true
                event.accepted = true
                break
            case Qt.Key_Escape:
                _clearSelection()
                event.accepted = true
                break
            case Qt.Key_Delete:
            case Qt.Key_Backspace:
                _deleteSelected()
                event.accepted = true
                break
            case Qt.Key_S:
                toolMode = "select"
                event.accepted = true
                break
            case Qt.Key_P:
                toolMode = "pan"
                event.accepted = true
                break
        }
    }
    Keys.onReleased: function(event) {
        if (event.key === Qt.Key_Shift) isShiftHeld = false
    }

    Qaterial.MiniFabButton {
        id: fabRightMenu
        visible: nodeOnFocus !== null && nodeOnFocus !== undefined
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.top: topBar.bottom
        anchors.topMargin: historyPanel.visible ? historyPanel.height + 16 : 8
        z: 100

        Behavior on anchors.topMargin {
            NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
        }

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

        onClicked: function(mouse) {
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

        onPositionChanged: function(mouse) {
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

        onClicked: function(mouse) {
            root.focus = true
            if (!isConnecting) {
                var cL = mycanvas.x
                var cT = mycanvas.y
                var cR = mycanvas.x + mycanvas.width  * zoomScale
                var cB = mycanvas.y + mycanvas.height * zoomScale
                if (mouse.x < cL || mouse.x > cR || mouse.y < cT || mouse.y > cB)
                    ToastManager.show("Fora da área de trabalho", "warning")
            }
        }

        onPositionChanged: function(mouse) {
            zoomMouseX = mouse.x
            zoomMouseY = mouse.y
        }

        onWheel: function(wheel) {
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

        // ── Infinite grid (viewport-fixed) ───────────────────────────────────────
        // NEW: ViewportGridSGG — direct QSG renderer. Vertex buffer filled in C++
        // on the render thread; no JS, no QPainter, no texture upload per frame.
        // To revert: comment this block and uncomment ViewportGridCanvas below.
        ViewportGridSGG {
            id: gridCanvas
            anchors.fill: parent
            panX:        mycanvas.x
            panY:        mycanvas.y
            zoom:        zoomScale
            minWgrid:    root.minWgrid
            pattern:     GlobalProperties.gridPattern
        }

        // ── OLD: Canvas-based grid (kept for easy rollback) ───────────────────────
        // ViewportGridCanvas {
        //     id: gridCanvas
        //     anchors.fill: parent
        //     panX:     mycanvas.x
        //     panY:     mycanvas.y
        //     zoom:     zoomScale
        //     minWgrid: root.minWgrid
        //     pattern:  GlobalProperties.gridPattern
        // }

        // ── Rubber-band selection overlay (screen-space, not scaled with canvas) ──
        Rectangle {
            id: rubberBandRect
            visible: root.isRubberBanding
            z: 400
            x:      Math.min(root.rubberStartX, root.rubberEndX) * root.zoomScale + mycanvas.x
            y:      Math.min(root.rubberStartY, root.rubberEndY) * root.zoomScale + mycanvas.y
            width:  Math.abs(root.rubberEndX - root.rubberStartX) * root.zoomScale
            height: Math.abs(root.rubberEndY - root.rubberStartY) * root.zoomScale
            color:  Qt.rgba(ThemeManager.primaryColor.r,
                            ThemeManager.primaryColor.g,
                            ThemeManager.primaryColor.b, 0.10)
            border.color: ThemeManager.primaryColor
            border.width: 1
            radius: 2
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
                drag.target: isConnecting ? undefined : (root.toolMode === "pan" ? mycanvas : undefined)

                hoverEnabled: true
                property bool isHoveringConnection: false
                property bool _rubberWasMeaningful: false

                cursorShape: {
                    if (root.toolMode === "select" && !isConnecting)
                        return root.isRubberBanding ? Qt.CrossCursor : Qt.ArrowCursor
                    return dragArea.drag.active ? Qt.ClosedHandCursor
                                                : (isHoveringConnection ? Qt.PointingHandCursor : Qt.OpenHandCursor)
                }

                onPressed: function(mouse) {
                    _rubberWasMeaningful = false
                    if (root.toolMode === "select" && !isConnecting) {
                        root.rubberStartX    = mouse.x
                        root.rubberStartY    = mouse.y
                        root.rubberEndX      = mouse.x
                        root.rubberEndY      = mouse.y
                        root.isRubberBanding = true
                    }
                }

                onReleased: {
                    if (root.isRubberBanding) {
                        root.isRubberBanding = false
                        if (_rubberWasMeaningful) {
                            root._selectNodesInRect(
                                Math.min(root.rubberStartX, root.rubberEndX),
                                Math.min(root.rubberStartY, root.rubberEndY),
                                Math.max(root.rubberStartX, root.rubberEndX),
                                Math.max(root.rubberStartY, root.rubberEndY))
                        }
                    }
                }

                onPositionChanged: function(mouse) {
                    if (root.isRubberBanding && root.toolMode === "select") {
                        root.rubberEndX = mouse.x
                        root.rubberEndY = mouse.y
                        var rw = Math.abs(root.rubberEndX - root.rubberStartX) * root.zoomScale
                        var rh = Math.abs(root.rubberEndY - root.rubberStartY) * root.zoomScale
                        if (rw > 6 || rh > 6) _rubberWasMeaningful = true
                        return
                    }
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

                onClicked: function(mouse) {
                    root.focus = true
                    if (_rubberWasMeaningful) { _rubberWasMeaningful = false; return }
                    root._clearSelection()
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

                // ── Camera frame — above all nodes; connections sit at MAX_VALUE ─
                CameraFrameItem {
                    id: cameraFrame
                    visible: root.showCamera
                    z: Number.MAX_VALUE - 1

                    // All geometry set imperatively to avoid binding conflicts with drag/resize.
                    Component.onCompleted: {
                        x      = root.cameraWorldX
                        y      = root.cameraWorldY
                        width  = root.cameraWorldW
                        height = root.cameraWorldH
                    }

                    onCameraRectChanged: function(wx, wy, ww, wh) {
                        root.cameraWorldX = wx
                        root.cameraWorldY = wy
                        root.cameraWorldW = ww
                        root.cameraWorldH = wh
                    }

                    onCloseRequested: root.showCamera = false
                }

                // ── Group Frames (behind connections and nodes) ───────────────
                ListModel { id: frameModel }

                Repeater {
                    id: frameRepeater
                    model: frameModel

                    delegate: GroupFrame {
                        id: groupFrameItem
                        width:      model.fw
                        height:     model.fh
                        frameLabel: model.frameLabel
                        frameColor: model.frameColorStr
                        z: 0.5  // behind nodes (z≥1), above grid (z=0)

                        // Set position imperatively — avoids binding conflicts with drag
                        Component.onCompleted: { x = model.fx; y = model.fy }

                        onLabelEdited: function(newLabel) {
                            frameModel.set(index, { frameLabel: newLabel })
                        }

                        // On press: capture node start positions so Connections can
                        // compute absolute new positions (startX + totalDelta).
                        onFrameDragStarted: {
                            var uuids = JSON.parse(model.nodeUuidsJson)
                            var refs  = []
                            for (var i = 0; i < uuids.length; i++) {
                                for (var j = 0; j < nodes.model.count; j++) {
                                    if (nodes.model.get(j).uuid === uuids[i]) {
                                        var it = nodes.itemAt(j)
                                        if (it) refs.push({ node: it, startX: it.x, startY: it.y })
                                        break
                                    }
                                }
                            }
                            root._activeFrame    = groupFrameItem
                            root._frameNodeRefs  = refs
                        }

                        // On release: stop syncing, record undo, persist frame position.
                        onFrameDragCompleted: function(oldFx, oldFy, newFx, newFy) {
                            var dx   = newFx - oldFx
                            var dy   = newFy - oldFy
                            var refs = root._frameNodeRefs.slice()  // snapshot before clear
                            root._activeFrame    = null
                            root._frameNodeRefs  = []
                            if (Math.abs(dx) < 0.5 && Math.abs(dy) < 0.5) return
                            viewPort.beginUndoMacro("Move group")
                            for (var i = 0; i < refs.length; i++) {
                                viewPort.recordNodeMove(
                                    viewPort.getUUIDFromBehaviour(refs[i].node.behaviourObject),
                                    refs[i].startX, refs[i].startY,
                                    refs[i].node.x,  refs[i].node.y)
                            }
                            viewPort.endUndoMacro()
                            frameModel.set(index, { fx: newFx, fy: newFy })
                        }

                        onContentsSelected: {
                            var uuids = JSON.parse(model.nodeUuidsJson)
                            var toSel = []
                            for (var i = 0; i < uuids.length; i++) {
                                for (var j = 0; j < nodes.model.count; j++) {
                                    if (nodes.model.get(j).uuid === uuids[i]) {
                                        var it = nodes.itemAt(j)
                                        if (it) toSel.push(it)
                                        break
                                    }
                                }
                            }
                            if (toSel.length > 0) root._setSelection(toSel)
                        }

                        onDissolved: { frameModel.remove(index) }
                    }
                }

                Repeater {
                    id: nodeConnections

                    model: ListModel {}

                    delegate: Shape {
                        id: shape
                        antialiasing: true
                        smooth: true
                        z: Number.MAX_VALUE

                        property var circleConnPoint:  null
                        property var circleConnPoint2: null
                        property var circleConn2:      null
                        property var viewRectConn2:    null

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

                        visible:           !model.isVisualization

                        // nodePressed fires on every mouse-down — select the node immediately
                        // unless it's already part of the current selection (preserves group).
                        onNodePressed: {
                            if (root.isShiftHeld) return  // shift handled in onNodeClicked
                            if (!root.selectedNodes.includes(viewComponentRectV2))
                                root._setSelection([viewComponentRectV2])
                        }

                        // nodeClicked fires only on a true click (no significant drag),
                        // so it never fires after a drag — the group stays selected.
                        onNodeClicked: {
                            if (root.isShiftHeld)
                                root._addToSelection(viewComponentRectV2)
                        }

                        onResizeEnded: root._clearSnapGuides()

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
                            // New nodes appear on top of all existing ones.
                            var maxZ = 0
                            for (var i = 0; i < rectsArray.count; i++) {
                                var r = rectsArray.get(i).rectObjTarget
                                if (r && r.z > maxZ) maxZ = r.z
                            }
                            z = maxZ + 1

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

                        // Bring to front automatically when the user starts dragging.
                        onIsDraggingChanged: {
                            if (isDragging) {
                                root._bringToFront(viewComponentRectV2)
                                root._setupGroupDrag(viewComponentRectV2)
                            }
                            // Do NOT clear group state here — onIsDraggingChanged fires
                            // synchronously inside area.onReleased BEFORE nodeDragEnded is
                            // emitted, so clearing here would wipe offsets before the undo
                            // macro can read them. Cleanup happens in onNodeDragEnded.
                        }

                        onNodeDragEnded: function(oldX, oldY, newX, newY) {
                            root._clearSnapGuides()
                            var uuid    = viewPort.getUUIDFromBehaviour(model.object)
                            var isGroup = (root._groupLeader === viewComponentRectV2
                                          && root._groupOffsets.length > 0)
                            // Snapshot offsets NOW — before clearing group state
                            var offsets = isGroup ? root._groupOffsets.slice() : []

                            // Clear group state so the Connections watcher stops firing
                            root._groupLeader  = null
                            root._groupOffsets = []

                            if (isGroup) {
                                viewPort.beginUndoMacro("Move " + (offsets.length + 1) + " nodes")
                                viewPort.recordNodeMove(uuid, oldX, oldY, newX, newY)
                                for (var mi = 0; mi < offsets.length; mi++) {
                                    var go2 = offsets[mi]
                                    viewPort.recordNodeMove(
                                        viewPort.getUUIDFromBehaviour(go2.node.behaviourObject),
                                        go2.startX, go2.startY, go2.node.x, go2.node.y)
                                }
                                viewPort.endUndoMacro()
                            } else {
                                viewPort.recordNodeMove(uuid, oldX, oldY, newX, newY)
                            }
                        }

                        onNodeResizeEnded: function(oldX, oldY, oldW, oldH, newX, newY, newW, newH) {
                            root._clearSnapGuides()
                            viewPort.recordNodeResize(
                                viewPort.getUUIDFromBehaviour(model.object),
                                oldX, oldY, oldW, oldH,
                                newX, newY, newW, newH)
                        }

                        onCloseButtonClicked: {
                            viewPort.removeNodeWithUndo(viewPort.getUUIDFromBehaviour(model.object))
                        }

                        onFrontOneStepClicked: root._bringForward(viewComponentRectV2)
                        onBackOneStepClicked:  root._sendBackward(viewComponentRectV2)
                        onFrontTotalClicked:   root._bringToFront(viewComponentRectV2)
                        onBackTotalClicked:    root._sendToBack(viewComponentRectV2)
                    }
                }
            }
        }
    }


    // ── Fullscreen visualization overlay ─────────────────────────────────────────
    FullscreenVisualization {
        id: fullscreenOverlay
        anchors.fill: parent
        z: 9999
        visible: root.showVisualization && vizWindow.isPlaying

        cameraX:      root.cameraWorldX
        cameraY:      root.cameraWorldY
        cameraWidth:  root.cameraWorldW
        cameraHeight: root.cameraWorldH
        nodesModel:   nodes.model

        onCloseRequested: vizWindow.isPlaying = false
    }

    Shortcut {
        sequence: "Escape"
        context:  Qt.ApplicationShortcut
        enabled:  fullscreenOverlay.visible
        onActivated: vizWindow.isPlaying = false
    }

    // ── Visualization window overlay ──────────────────────────────────────────────
    VisualizationWindow {
        id: vizWindow
        visible: root.showVisualization
        z: 300

        x: root.width  - width  - 12
        y: topBarHeight + 12

        cameraX:      root.cameraWorldX
        cameraY:      root.cameraWorldY
        cameraWidth:  root.cameraWorldW
        cameraHeight: root.cameraWorldH
        nodesModel:   nodes.model

        onCloseRequested: root.showVisualization = false

        onIsPlayingChanged: {
            if (isPlaying) root.startVisualization()
            else root.stopVisualization()
        }

        onDetachRequested: {
            externalVizWindow.show()
            externalVizWindow.raise()
        }
    }

    // ── External visualization window ───────────────────────────────────────────
    ExternalVisualizationWindow {
        id: externalVizWindow
        
        cameraX:      root.cameraWorldX
        cameraY:      root.cameraWorldY
        cameraWidth:  root.cameraWorldW
        cameraHeight: root.cameraWorldH
        nodesModel:   nodes.model
        
        onClosing: {
            // Sincroniza o estado de 'playing' caso a janela seja fechada manualmente
            vizWindow.isPlaying = false
        }
    }

    // ── Group frame node sync ─────────────────────────────────────────────────────
    // Same Connections pattern as multi-select group drag.
    // Uses absolute offsets (startX + totalDelta) — avoids floating-point drift.
    function _syncFrameNodes() {
        if (!_activeFrame || _frameNodeRefs.length === 0) return
        var dx = _activeFrame.x - _activeFrame._pressFrameX
        var dy = _activeFrame.y - _activeFrame._pressFrameY
        for (var i = 0; i < _frameNodeRefs.length; i++) {
            var ref = _frameNodeRefs[i]
            ref.node.isGroupFollowing = true
            ref.node.x = ref.startX + dx
            ref.node.y = ref.startY + dy
            ref.node.isGroupFollowing = false
            if (ref.node.behaviourObject) {
                ref.node.behaviourObject.x = ref.node.x
                ref.node.behaviourObject.y = ref.node.y
            }
        }
    }

    Connections {
        target:  root._activeFrame
        enabled: root._activeFrame !== null
        function onXChanged() { root._syncFrameNodes() }
        function onYChanged() { root._syncFrameNodes() }
    }

    // ── Group drag follower sync ──────────────────────────────────────────────────
    // Watches the drag leader's x/y directly. enabled only checks _groupLeader
    // because _groupOffsets is mutated with push() — QML bindings do NOT detect
    // array mutations (short-circuit evaluation prevents length being tracked as
    // a dependency). The _syncGroupFollowers guard handles the empty case.
    Connections {
        target:  root._groupLeader
        enabled: root._groupLeader !== null

        function onXChanged() { root._syncGroupFollowers() }
        function onYChanged() { root._syncGroupFollowers() }
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
        showCamera:        root.showCamera
        showVisualization: root.showVisualization
        onCameraToggled: {
            root.showCamera = !root.showCamera
            if (root.showCamera) {
                cameraFrame.x      = root.cameraWorldX
                cameraFrame.y      = root.cameraWorldY
                cameraFrame.width  = root.cameraWorldW
                cameraFrame.height = root.cameraWorldH
            }
        }
        onVisualizationToggled: {
            root.showVisualization = !root.showVisualization
            if (root.showVisualization) {
                vizWindow.x = root.width  - vizWindow.width  - 12
                vizWindow.y = topBarHeight + 12
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

    // ─── History Panel ──────────────────────────────────────────────────────────
    HistoryPanel {
        id: historyPanel
        vp:      viewPort
        visible: topBar.historyPanelOpen
        z: 190

        anchors.top:   topBar.bottom
        anchors.right: parent.right
        anchors.topMargin:   8
        // drawer.position: 0.0 = closed/invisible, 1.0 = fully open.
        // Works correctly even before the drawer has ever been shown (position=0).
        anchors.rightMargin: 8 + drawer.width * drawer.position

        onCloseRequested: topBar.historyPanelOpen = false
    }

    Shortcut {
        sequence: "Ctrl+Z"
        context:  Qt.ApplicationShortcut
        onActivated: viewPort.undo()
    }
    Shortcut {
        sequence: "Ctrl+Y"
        context:  Qt.ApplicationShortcut
        onActivated: viewPort.redo()
    }
    Shortcut {
        sequence: "Ctrl+S"
        context:  Qt.ApplicationShortcut
        onActivated: {
            if (WorkspaceManager.currentWorkspace !== "") {
                const ok = viewPort.saveWorkspace(WorkspaceManager.currentWorkspace)
                ToastManager.show(ok ? "Project saved" : "Failed to save project",
                                  ok ? "success" : "error")
            } else {
                saveWorkspaceDialog.open()
            }
        }
    }
    Shortcut {
        sequence: "G"
        context:  Qt.ApplicationShortcut
        onActivated: GlobalProperties.snapEnabled = !GlobalProperties.snapEnabled
    }
    Shortcut {
        sequence: "Ctrl+H"
        context:  Qt.ApplicationShortcut
        onActivated: topBar.historyPanelOpen = !topBar.historyPanelOpen
    }
    Shortcut {
        sequence: "F"
        context:  Qt.ApplicationShortcut
        onActivated: root._focusFrame()
    }
    Shortcut {
        sequence: "Ctrl+A"
        context:  Qt.ApplicationShortcut
        onActivated: {
            var all = []
            for (var i = 0; i < nodes.model.count; i++) {
                var it = nodes.itemAt(i)
                if (it) all.push(it)
            }
            root._setSelection(all)
        }
    }
    Shortcut {
        sequence: "Ctrl+C"
        context:  Qt.ApplicationShortcut
        onActivated: root._copySelected()
    }
    Shortcut {
        sequence: "Ctrl+V"
        context:  Qt.ApplicationShortcut
        onActivated: root._pasteClipboard()
    }
    Shortcut {
        sequence: "Ctrl+D"
        context:  Qt.ApplicationShortcut
        onActivated: { root._copySelected(); root._pasteClipboard() }
    }
    Shortcut {
        sequence: "Ctrl+G"
        context:  Qt.ApplicationShortcut
        onActivated: root._groupSelected()
    }
    Shortcut {
        sequence: "Ctrl+Shift+C"
        context:  Qt.ApplicationShortcut
        onActivated: {
            root.showCamera = !root.showCamera
            if (root.showCamera) {
                cameraFrame.x      = root.cameraWorldX
                cameraFrame.y      = root.cameraWorldY
                cameraFrame.width  = root.cameraWorldW
                cameraFrame.height = root.cameraWorldH
            }
        }
    }
    Shortcut {
        sequence: "Ctrl+Shift+V"
        context:  Qt.ApplicationShortcut
        onActivated: {
            root.showVisualization = !root.showVisualization
            if (root.showVisualization) {
                vizWindow.x = root.width  - vizWindow.width  - 12
                vizWindow.y = topBarHeight + 12
            }
        }
    }
    Shortcut {
        sequence: "Ctrl+Shift+G"
        context:  Qt.ApplicationShortcut
        onActivated: {
            // Dissolve all frames that contain any selected node
            var selUuids = []
            for (var i = 0; i < root.selectedNodes.length; i++)
                selUuids.push(viewPort.getUUIDFromBehaviour(root.selectedNodes[i].behaviourObject))
            for (var fi = frameModel.count - 1; fi >= 0; fi--) {
                var fuuids = JSON.parse(frameModel.get(fi).nodeUuidsJson)
                for (var k = 0; k < fuuids.length; k++) {
                    if (selUuids.indexOf(fuuids[k]) >= 0) { frameModel.remove(fi); break }
                }
            }
        }
    }

    // Smooth pan+zoom animation used by the F shortcut.
    ParallelAnimation {
        id: focusAnim
        property real toX: 0
        property real toY: 0
        NumberAnimation { target: mycanvas; property: "x"; to: focusAnim.toX; duration: 380; easing.type: Easing.OutQuart }
        NumberAnimation { target: mycanvas; property: "y"; to: focusAnim.toY; duration: 380; easing.type: Easing.OutQuart }
        NumberAnimation { target: root;    property: "zoomScale"; to: 1.0;    duration: 380; easing.type: Easing.OutQuart }
    }

    function _focusFrame() {
        var wx, wy
        if (root.selectedNodes.length > 1) {
            var mnX = 1e9, mnY = 1e9, mxX = -1e9, mxY = -1e9
            for (var i = 0; i < root.selectedNodes.length; i++) {
                var n = root.selectedNodes[i]
                if (n.x            < mnX) mnX = n.x
                if (n.y            < mnY) mnY = n.y
                if (n.x + n.width  > mxX) mxX = n.x + n.width
                if (n.y + n.height > mxY) mxY = n.y + n.height
            }
            wx = (mnX + mxX) / 2
            wy = (mnY + mxY) / 2
        } else if (root.nodeOnFocus) {
            wx = root.nodeOnFocus.x + root.nodeOnFocus.width  / 2
            wy = root.nodeOnFocus.y + root.nodeOnFocus.height / 2
        } else {
            // Canvas center ("home") is the world point (5000, 5000)
            wx = 5000
            wy = 5000
        }
        focusAnim.stop()
        focusAnim.toX = containerCanvas.width  / 2 - wx
        focusAnim.toY = containerCanvas.height / 2 - wy
        focusAnim.start()
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
            root._setSelection([nodeItem])
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
        onClosed: root.selectedPanel = ""

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

    // ─── Left panel light-dismiss ────────────────────────────────────────────────
    // Transparent overlay over the canvas area (right of the drawer).
    // Closes the drawer when the user clicks outside it.
    // mouse.accepted = false lets the click propagate to nodes/canvas underneath.
    MouseArea {
        anchors.top:    topBar.bottom
        anchors.bottom: parent.bottom
        anchors.right:  parent.right
        anchors.left:   parent.left
        anchors.leftMargin: leftPanelDrawer.position * leftPanelDrawer.width
        z: 50
        enabled:             leftPanelDrawer.position > 0
        visible:             enabled
        propagateComposedEvents: true
        onPressed: function(mouse) {
            leftPanelDrawer.close()
            mouse.accepted = false
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
        toolMode:    root.toolMode

        onToolModeActivated: function(mode) { root.toolMode = mode }

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
        selectedCount:   root.selectedNodes.length
        nodeCount:       nodes.model.count
        fpsCount:        viewPort.fpsCount
        showFps:         GlobalProperties.showFps
    }

    // ── Loading Spinner Overlay ──────────────────────────────────────────────────
    // Embedded directly to avoid qrc/import issues with new files.
    Rectangle {
        id: cloningOverlay
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.4)
        visible: root.isCloning
        z: 20000 // On top of everything

        // Block mouse events during cloning
        MouseArea { anchors.fill: parent; preventStealing: true }

        Rectangle {
            anchors.centerIn: parent
            width: 140; height: 110; radius: 12
            color: Qt.rgba(0.1, 0.1, 0.1, 0.9)
            border.color: Qt.rgba(1, 1, 1, 0.1)

            Column {
                anchors.centerIn: parent
                spacing: 12
                
                BusyIndicator {
                    id: indicator
                    running: cloningOverlay.visible
                    anchors.horizontalCenter: parent.horizontalCenter
                    
                    contentItem: Item {
                        implicitWidth:  42; implicitHeight: 42
                        Canvas {
                            anchors.fill: parent
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.reset()
                                ctx.translate(width/2, height/2)
                                ctx.rotate(rotation * Math.PI / 180)
                                ctx.strokeStyle = "#FF9800" // Use a constant to be safe
                                ctx.lineWidth = 3
                                ctx.lineCap = "round"
                                ctx.beginPath()
                                ctx.arc(0, 0, width/2 - 4, 0, Math.PI * 1.5)
                                ctx.stroke()
                            }
                            RotationAnimation on rotation {
                                from: 0; to: 360; duration: 800; loops: Animation.Infinite
                                running: indicator.running
                            }
                        }
                    }
                }
                Text {
                    text: "Clonando Nós..."
                    color: "white"; font.pixelSize: 11; font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
