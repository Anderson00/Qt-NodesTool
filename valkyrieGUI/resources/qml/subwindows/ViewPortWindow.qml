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
    property var tt: ""
    property var count: 0
    property int minWgrid: GlobalProperties.minWgrid
    property int minZoom: 1
    property int maxZoom: 6

    // mouse properties
    property var mouseXX
    property var mouseYY
    property bool isConnecting: false
    property var shapeConn
    property bool m_suppressConnectionDraw: false
    property var finalPoint

    //Behaviours properties
    property var behavioursZ: []
    property var nodeOnFocus

    // World-space point kept at the center of the view.
    // Updated whenever the canvas is panned or zoomed.
    // Initial value = (5000, 5000) = canvas center = "home" = display (0, 0).
    property real viewCenterX: 5000
    property real viewCenterY: 5000

    property var rectsArray: ListModel {}

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
            sliderZoom.value = scale
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
        mycanvas.x = containerCanvas.width  / 2 - viewCenterX * sliderZoom.value
        mycanvas.y = containerCanvas.height / 2 - viewCenterY * sliderZoom.value
    }

    function addWindow(){

    }

    function getBehaviourGreaterZ(){
        let aux = []
        aux = aux.concat(behavioursZ);
        return aux.sort()[aux.length - 1];
    }

    // Converts viewport coordinates to mycanvas local coordinates.
    function toLocal(vx, vy) {
        return Qt.point(
            (vx - mycanvas.x) / sliderZoom.value,
            (vy - mycanvas.y) / sliderZoom.value
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
        }
    }

    Qaterial.MiniFabButton {
        id: fabRightMenu
        anchors.right: parent.right
        anchors.top: topBar.bottom
        z: 100
        opacity: (nodeOnFocus)? 1 : 0.3

        icon.source: Qaterial.Icons.tune
        icon.color: ThemeManager.primaryColor
        flat: false
        radius: 0

        onClicked: {
            if(opacity === 1){
                if(rightDrawerOpened)
                    drawer.close()
                else
                    drawer.open()
            }
        }
    }

    NodeSettings {
        id: drawer
        width: 200
        height: (parent.height - (parent.height - viewRect.y)) + viewRect.height + 8
        modal: false
        edge: Qt.RightEdge
        interactive: false

        viewPortWindow: root
        selectedObjectView: nodeOnFocus

        onOpened: {
            rightDrawerOpened = true
        }

        onClosed: {
            rightDrawerOpened = false
        }

        onXChanged: {
            fabRightMenu.anchors.rightMargin = parent.width - x
            viewRect.anchors.rightMargin = fabRightMenu.anchors.rightMargin + 8
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
                        // Draw visually using the original approach (direct circleConn2 set)
                        // This is reliable because the Shape item is already in the scene.
                        shapeConn.circleConn2   = conn.circleConn
                        shapeConn.viewRectConn2 = node
                        shapeConn = undefined
                        // Record undo; suppress visual redraw since line is already drawn
                        m_suppressConnectionDraw = true
                        viewPort.addConnectionWithUndo(outUuid, outMethod, inUuid, inMethod)
                        m_suppressConnectionDraw = false
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

            var oldZoom = sliderZoom.value
            var newZoom = oldZoom + (wheel.angleDelta.y > 0 ? 0.1 : -0.1)
            newZoom = Math.max(sliderZoom.from, Math.min(sliderZoom.to, newZoom))

            // Keep the content point under the mouse stationary during zoom.
            // Visual position of workspace origin: mycanvas.x + localX * zoom
            // => mycanvas.x_new = mouseX - (mouseX - mycanvas.x) * newZoom / oldZoom
            var mx = mouseZoom.zoomMouseX
            var my = mouseZoom.zoomMouseY
            mycanvas.x = mx - (mx - mycanvas.x) * newZoom / oldZoom
            mycanvas.y = my - (my - mycanvas.y) * newZoom / oldZoom

            canvasScale.origin.x = 0
            canvasScale.origin.y = 0
            sliderZoom.value = newZoom
        }
    }

    Column {
        id: fullscreenFab
        anchors.top: topBar.bottom
        anchors.left: root.left
        anchors.margins: 8
        spacing: 2
        z: 100

        Qaterial.MiniFabButton {
            id: fullscreenButton
            icon.source: Qaterial.Icons.fullscreen
            icon.color: ThemeManager.accentColor
            flat: false

            onClicked: {
                if(icon.source === Qaterial.Icons.fullscreen)
                    icon.source = Qaterial.Icons.fullscreenExit
                else
                    icon.source = Qaterial.Icons.fullscreen

                viewPort.setFullScreen(true);
            }
        }

        Qaterial.MiniFabButton {
            id: centerButton
            icon.source: Qaterial.Icons.setCenter
            icon.color: ThemeManager.accentColor
            flat: false

            readonly property real homeX: (containerCanvas.width  - mycanvas.width)  / 2
            readonly property real homeY: (containerCanvas.height - mycanvas.height) / 2

            opacity: (Math.abs(mycanvas.x - homeX) < 1 &&
                      Math.abs(mycanvas.y - homeY) < 1 &&
                      sliderZoom.value === 1) ? 0.3 : 1

            onClicked: {
                if (opacity < 1) return
                root.isAnimatingCenter = true
                mycanvas.x = homeX
                mycanvas.y = homeY
                zoomAnim.to = 1
                zoomAnim.start()
            }
        }
    }

    CustomSlider {
        id: sliderZoom
        from: minZoom
        to: maxZoom
        value: minZoom
        z: 100
        enabled: !isConnecting
        color: ThemeManager.primaryColor
        textColor: ThemeManager.textColor
        anchors.left: fullscreenFab.right
        anchors.top: topBar.bottom
        anchors.topMargin: 22
        prefix: "x"

        onValueChanged: viewPort.viewportScale = value
    }

    NumberAnimation {
        id: zoomAnim
        target: sliderZoom
        property: "value"
        duration: 400
        easing.type: Easing.InOutCubic
    }

    CustomSliderVertical {
        id: slider2
        visible: false
        from: 1
        to: 100
        value: 1
        z: 100
        anchors.top: fullscreenFab.bottom
        anchors.topMargin: -8
        anchors.left: fullscreenFab.left
        state: "left"

        onValueChanged: {

        }
    }

    Rectangle {
        id: fpsCounterContainer
        visible: viewPort.showFps
        color: "transparent"
        width: 100
        height: 50
        anchors.top: topBar.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        radius: 8

        Rectangle {
            anchors.fill: parent
            color: ThemeManager.primaryColor
            opacity: 0.5
            radius: fpsCounterContainer.radius
        }

        ColumnLayout {
            anchors.fill: parent
            Layout.alignment: Qt.AlignCenter
            spacing: 0

            Label {
                id: fpsCounter
                color: ThemeManager.textColor
                font.pixelSize: 14
                text: `${viewPort.fpsCount} FPS`
                Layout.alignment: Qt.AlignCenter
            }

            Label {
                id: fpsTime
                color: ThemeManager.textColor
                font.pixelSize: 14
                text: `${viewPort.fpsCount > 0? (1000/viewPort.fpsCount).toFixed(2) : 0} ms`
                Layout.alignment: Qt.AlignCenter
            }
        }
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
            zoom:     sliderZoom.value
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
                root.viewCenterX  = (containerCanvas.width  / 2 - x) / sliderZoom.value
                viewPort.viewportX = x
            }
            onYChanged: if (initialized) {
                root.viewCenterY  = (containerCanvas.height / 2 - y) / sliderZoom.value
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
                    mycanvas.x = containerCanvas.width  / 2 - 5000 * sliderZoom.value
                    mycanvas.y = containerCanvas.height / 2 - 5000 * sliderZoom.value
                    mycanvas.initialized = true
                })
            }

            transform: Scale {
                id: canvasScale
                origin.x: 0
                origin.y: 0
                xScale: sliderZoom.value
                yScale: sliderZoom.value
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent

                drag.smoothed: true
                drag.target: isConnecting ? undefined : mycanvas

                cursorShape: dragArea.drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                onClicked: {
                    root.focus = true
                    nodeOnFocus = null
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
                                readonly property real ex: circleConn2
                                    ? circleConnPoint2.x + circleConn2.width  / 2
                                    : (mouseAreaGlobal.mouseX - mycanvas.x) / sliderZoom.value
                                readonly property real ey: circleConn2
                                    ? circleConnPoint2.y + circleConn2.height / 2
                                    : (mouseAreaGlobal.mouseY - mycanvas.y) / sliderZoom.value

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

                        onXChanged: {
                            if (nodeOnFocus !== this) nodeOnFocus = this
                        }

                        onYChanged: {
                            if (nodeOnFocus !== this) nodeOnFocus = this
                        }

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
                                var cx = (containerCanvas.width  / 2 - mycanvas.x) / sliderZoom.value
                                var cy = (containerCanvas.height / 2 - mycanvas.y) / sliderZoom.value
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
                            viewPort.recordNodeMove(
                                viewPort.getUUIDFromBehaviour(model.object),
                                oldX, oldY, newX, newY)
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

    CustomToolbar {
        id: toolbar
        anchors.bottom: parent.bottom
        visible: false

        width: 350
        height: 50
        actions : [
            {text: "OK", icon: "play", onClicked: ()=>{console.log(3232)} },
            {text: "OK", icon: "stop", onClicked: ()=>{console.log(3232)} },
            {text: "OK", icon: "debug-step-into", onClicked: ()=>{console.log(3232)} },
            {text: "OK", onClicked: ()=>{console.log(3232)} }
        ]

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

    // ─── Nodes List ─────────────────────────────────────────────────────────────
    NodesList {
        id: nodesList
        nodesModel: nodes.model
        containerCanvas: containerCanvas
        mycanvas: mycanvas
        sliderZoom: sliderZoom
        statusBar: statusBar
        topBar: topBar
        topLeftAnchor: fullscreenFab
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

            width: viewRect.width / sliderZoom.value
            height: viewRect.height / sliderZoom.value

            x: -(mycanvas.x * viewRect.width) / (containerCanvas.width * sliderZoom.value)
            y: -(mycanvas.y * viewRect.height) / (containerCanvas.height * sliderZoom.value)
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
        zoom:            sliderZoom.value
        hoverX:          globalHover.point.position.x
        hoverY:          globalHover.point.position.y
        nodeOnFocus:     root.nodeOnFocus
        nodeCount:       nodes.model.count
    }
}
