import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.0
import QtQuick.Shapes 1.15
import App.Theme 1.0
import App.Properties 1.0
import App.Workspace 1.0

import "../components"
import "../components/bottomsheets"
import "../components/viewport"
import Qaterial as Qaterial

Rectangle {
    id: root
    property var tt: ""
    property var count: 0
    property int minWgrid: 20
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
        if (event.key == Qt.Key_Shift) {

            event.accepted = true;
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

    Qaterial.MiniFabButton {
        id: fabBottomMenu
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 22
        anchors.horizontalCenter: parent.horizontalCenter
        z: 100

        icon.source: Qaterial.Icons.folderTable
        icon.color: ThemeManager.primaryColor
        flat: false
        radius: 0

        onClicked: {
            if(bottomDrawerOpened)
                drawerFolder.close()
            else
                drawerFolder.open()
        }
    }

    FolderBottomSheet {
        id: drawerFolder

        viewPortWindow: root

        onBehaviourSelected: {
            console.log(viewPort.addBehaviour(path, infos))
        }

        onOpened: {
            bottomDrawerOpened = true
        }

        onClosed: {
            bottomDrawerOpened = false
        }

        onYChanged: {
            fabBottomMenu.anchors.bottomMargin = (parent.height - y) + 22
            toolbar.anchors.bottomMargin = (parent.height - y) + 22
            viewRect.anchors.bottomMargin = (parent.height - y) + 22 + 8
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

                        // Marching ants animation
                        NumberAnimation on dashOffset {
                            from: 0
                            to: -12
                            duration: 400
                            loops: Animation.Infinite
                            running: true
                        }
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
                            dashOffset: shape.dashOffset

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
        onPanelToggled: function(panel) {
            if (root.selectedPanel === panel) {
                root.selectedPanel = ""
                leftPanelDrawer.close()
            } else {
                root.selectedPanel = panel
                leftPanelDrawer.open()
            }
        }
        onSettingsRequested: settingsPopup.open()
        onSaveRequested: {
            if (WorkspaceManager.currentWorkspace !== "")
                viewPort.saveWorkspace(WorkspaceManager.currentWorkspace)
            else
                saveWorkspaceDialog.open()
        }
        onOpenRequested: openWorkspaceDialog.open()
        onUndoRequested: viewPort.undo()
        onRedoRequested: viewPort.redo()
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

    // ─── Save Workspace Dialog ───────────────────────────────────────────────────
    Popup {
        id: saveWorkspaceDialog
        width: 300
        x: (parent.width  - width)  / 2
        y: (parent.height - height) / 2
        z: 1000
        modal: true
        padding: 20
        closePolicy: Popup.CloseOnEscape

        background: Rectangle {
            color:  ThemeManager.surfaceColor
            radius: 8
            border.color: ThemeManager.borderColor
            border.width: 1
        }

        Column {
            width: parent.width
            spacing: 12

            Text {
                text: "Save Workspace"
                font.pixelSize: 14
                font.bold: true
                color: ThemeManager.foregroundColor
            }

            TextField {
                id: saveNameField
                width: parent.width
                placeholderText: "Workspace name..."
                text: WorkspaceManager.currentWorkspace
                color: ThemeManager.foregroundColor
                background: Rectangle {
                    color: Qt.darker(ThemeManager.surfaceColor, 1.2)
                    radius: 4
                    border.color: ThemeManager.borderColor
                }
                Keys.onReturnPressed: {
                    if (text.trim() !== "") saveConfirmBtn.clicked()
                }
            }

            Row {
                spacing: 8
                anchors.right: parent.right

                Button {
                    text: "Cancel"
                    flat: true
                    onClicked: saveWorkspaceDialog.close()
                }

                Button {
                    id: saveConfirmBtn
                    text: "Save"
                    enabled: saveNameField.text.trim() !== ""
                    onClicked: {
                        const name = saveNameField.text.trim()
                        viewPort.saveWorkspace(name)
                        GlobalProperties.lastWorkspace = name
                        saveWorkspaceDialog.close()
                    }
                }
            }
        }
    }

    // ─── Open Workspace Dialog ───────────────────────────────────────────────────
    Popup {
        id: openWorkspaceDialog
        width: 300
        x: (parent.width  - width)  / 2
        y: (parent.height - height) / 2
        z: 1000
        modal: true
        padding: 20
        closePolicy: Popup.CloseOnEscape

        background: Rectangle {
            color:  ThemeManager.surfaceColor
            radius: 8
            border.color: ThemeManager.borderColor
            border.width: 1
        }

        Column {
            width: parent.width
            spacing: 12

            Text {
                text: "Open Workspace"
                font.pixelSize: 14
                font.bold: true
                color: ThemeManager.foregroundColor
            }

            Text {
                visible: WorkspaceManager.workspaceList.length === 0
                text: "No saved workspaces yet."
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 12
            }

            ListView {
                visible: WorkspaceManager.workspaceList.length > 0
                width:  parent.width
                height: Math.min(WorkspaceManager.workspaceList.length * 40, 200)
                model:  WorkspaceManager.workspaceList
                clip:   true

                delegate: Rectangle {
                    width:  parent ? parent.width : 0
                    height: 40
                    radius: 4
                    color:  wsItemMouse.containsMouse
                                ? Qt.rgba(ThemeManager.primaryColor.r,
                                          ThemeManager.primaryColor.g,
                                          ThemeManager.primaryColor.b, 0.12)
                                : "transparent"

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left:           parent.left
                        anchors.leftMargin:     8
                        text:  modelData
                        color: modelData === WorkspaceManager.currentWorkspace
                                   ? ThemeManager.primaryColor
                                   : ThemeManager.foregroundColor
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: wsItemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked: {
                            viewPort.loadWorkspace(modelData)
                            GlobalProperties.lastWorkspace = modelData
                            openWorkspaceDialog.close()
                        }
                    }
                }
            }

            Button {
                text: "Cancel"
                flat: true
                anchors.right: parent.right
                onClicked: openWorkspaceDialog.close()
            }
        }
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
        width: 280
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

                Text {
                    anchors.centerIn: parent
                    text: selectedPanel ? (selectedPanel.charAt(0).toUpperCase() + selectedPanel.slice(1) + " panel") : ""
                    color: ThemeManager.textColor
                    opacity: 0.35
                    font.pixelSize: 12
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
