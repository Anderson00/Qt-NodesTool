import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.0
import QtQuick.Shapes 1.15
import App.Theme 1.0

import "../components"
import "../components/bottomsheets"
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
    property var finalPoint

    //Behaviours properties
    property var behavioursZ: []
    property var nodeOnFocus

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

    property int topBarHeight: 48
    property string selectedPanel: ""
    property string currentProject: "Untitled Project"

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
            nodes.model.append({'object':obj})
        }

        function onBehaviourConnection(source, target){
            console.log("Source = "+ source + " target = "+ target)

            let sourceUUID = viewPort.getUUIDFromBehaviour(source);
            let targetUUID = viewPort.getUUIDFromBehaviour(target);

            let sourceObject;
            let targetObject;
            for(let i = 0; i < rectsArray.count; i++){
                if(rectsArray.get(i)["uuid"] === sourceUUID) {
                    sourceObject = rectsArray.get(i)["rectObjTarget"];
                }

                if(rectsArray.get(i)["uuid"] === targetUUID){
                    targetObject = rectsArray.get(i)["rectObjTarget"];
                }
            }

            if(sourceObject && targetObject){
                viewRectGhostConns.model.append({rect1: sourceObject, rect2: targetObject});
            }
        }
    }

    function viewSubWindowsWidthHeightArea(){
        // TODO:
        return;
        if(view3.x + view3.width > root.width){
            view3.x = root.width - view3.width
        }
        if(view3.y + view3.height > root.height){
            view3.y = root.height - view3.height
        }
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
                    shapeConn.circleConn2   = conn.circleConn
                    shapeConn.viewRectConn2 = node
                    nodeConnections.model.set(lastConnection, { node2: node, methodSignature2: conn.name })

                    let n1      = nodeConnections.model.get(lastConnection)
                    let isValid = n1['node'].behaviourObject.addConnection(
                                      n1['methodSignature1'], n1['node2'], n1['methodSignature2'])
                    if (isValid)
                        nodeConnected(node, shapeConn.viewRectConn2)
                    else
                        nodeConnections.model.remove(lastConnection)
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
                mycanvas.x = homeX
                mycanvas.y = homeY
                sliderZoom.value = 1
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

        onValueChanged: {}
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
        Canvas {
            id: gridCanvas
            anchors.fill: parent
            z: 0

            readonly property real panX: mycanvas.x
            readonly property real panY: mycanvas.y

            onPanXChanged:   requestPaint()
            onPanYChanged:   requestPaint()
            onWidthChanged:  requestPaint()
            onHeightChanged: requestPaint()

            Connections {
                target: sliderZoom
                function onValueChanged() { gridCanvas.requestPaint() }
            }
            Connections {
                target: ThemeManager
                function onThemeChanged() { gridCanvas.requestPaint() }
            }

            onPaint: {
                var ctx   = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var zoom  = sliderZoom.value
                var cell  = root.minWgrid * zoom   // minor cell in screen px
                var major = cell * 5               // major cell in screen px
                var pc    = ThemeManager.primaryColor
                var px    = mycanvas.x
                var py    = mycanvas.y

                // Infinite-grid offset: wrap pan into [0, period).
                var ox  = ((px % cell)  + cell)  % cell
                var oy  = ((py % cell)  + cell)  % cell
                var mox = ((px % major) + major) % major
                var moy = ((py % major) + major) % major

                // ── LOD: minor dots only when cell is large enough ────────────
                // Threshold 32 px ≈ zoom ≥ 1.6 → avoids ~5 000 arc calls at low zoom.
                if (cell >= 32) {
                    var mr = Math.max(0.9, zoom * 0.48)
                    ctx.fillStyle = Qt.rgba(pc.r, pc.g, pc.b, 0.20)
                    ctx.beginPath()
                    for (var ix = ox; ix <= width  + cell; ix += cell) {
                        for (var iy = oy; iy <= height + cell; iy += cell) {
                            ctx.moveTo(ix + mr, iy)
                            ctx.arc(ix, iy, mr, 0, 6.2832)
                        }
                    }
                    ctx.fill()
                }

                // ── Major dots (always shown, max ~200 at any zoom) ───────────
                var xr = Math.max(1.4, zoom * 0.88)
                ctx.fillStyle = Qt.rgba(pc.r, pc.g, pc.b, 0.48)
                ctx.beginPath()
                for (var jx = mox; jx <= width  + major; jx += major) {
                    for (var jy = moy; jy <= height + major; jy += major) {
                        ctx.moveTo(jx + xr, jy)
                        ctx.arc(jx, jy, xr, 0, 6.2832)
                    }
                }
                ctx.fill()

                // ── Workspace boundary indicator ──────────────────────────────
                // Shows where the 10 000×10 000 work area ends.
                var bL = px
                var bT = py
                var bR = px + mycanvas.width  * zoom
                var bB = py + mycanvas.height * zoom

                var anyEdgeVisible = (bL > 0 && bL < width)  ||
                                     (bR > 0 && bR < width)  ||
                                     (bT > 0 && bT < height) ||
                                     (bB > 0 && bB < height)

                if (anyEdgeVisible) {
                    var cL = Math.max(0, bL)
                    var cT = Math.max(0, bT)
                    var cR = Math.min(width,  bR)
                    var cB = Math.min(height, bB)

                    ctx.strokeStyle = Qt.rgba(pc.r, pc.g, pc.b, 0.55)
                    ctx.lineWidth   = 1.5
                    ctx.setLineDash([7, 5])
                    ctx.beginPath()
                    if (bL >= 0 && bL <= width)  { ctx.moveTo(bL, cT); ctx.lineTo(bL, cB) }
                    if (bR >= 0 && bR <= width)  { ctx.moveTo(bR, cT); ctx.lineTo(bR, cB) }
                    if (bT >= 0 && bT <= height) { ctx.moveTo(cL, bT); ctx.lineTo(cR, bT) }
                    if (bB >= 0 && bB <= height) { ctx.moveTo(cL, bB); ctx.lineTo(cR, bB) }
                    ctx.stroke()
                    ctx.setLineDash([])

                    // Corner labels "END" near each visible boundary corner
                    ctx.fillStyle = Qt.rgba(pc.r, pc.g, pc.b, 0.40)
                    ctx.font = "10px sans-serif"
                    if (bL >= 2 && bL <= width - 20 && bT >= 2 && bT <= height - 14)
                        ctx.fillText("⌜", bL + 3, bT + 12)
                    if (bR >= 20 && bR <= width - 2 && bT >= 2 && bT <= height - 14)
                        ctx.fillText("⌝", bR - 13, bT + 12)
                    if (bL >= 2 && bL <= width - 20 && bB >= 14 && bB <= height - 2)
                        ctx.fillText("⌞", bL + 3, bB - 3)
                    if (bR >= 20 && bR <= width - 2 && bB >= 14 && bB <= height - 2)
                        ctx.fillText("⌟", bR - 13, bB - 3)
                }
            }
        }

        // ── Workspace item (node container) ──────────────────────────────────
        Item {
            id: mycanvas
            width:  10000
            height: 10000

            Component.onCompleted: {
                mycanvas.x = (containerCanvas.width  - mycanvas.width)  / 2
                mycanvas.y = (containerCanvas.height - mycanvas.height) / 2
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

                        Component.onCompleted: {
                            circleConnPoint = model.circleConn.mapToItem(parent, 0, 0)
                            shapeConn = shape
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
                            function onXChanged() { circleConnPoint = model.circleConn.mapToItem(parent, 0, 0) }
                            function onYChanged() { circleConnPoint = model.circleConn.mapToItem(parent, 0, 0) }
                        }

                        Connections {
                            target: viewRectConn2
                            function onXChanged() { circleConnPoint2 = circleConn2.mapToItem(parent, 0, 0) }
                            function onYChanged() { circleConnPoint2 = circleConn2.mapToItem(parent, 0, 0) }
                        }

                        ShapePath {
                            id: shapepath
                            strokeColor: model.circleConn.color
                            strokeWidth: 2
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap

                            startX: circleConnPoint.x + model.circleConn.width / 2
                            startY: circleConnPoint.y + model.circleConn.height / 2

                            PathLine {
                                // When tracking mouse: convert viewport coords to mycanvas local space.
                                x: circleConn2 ? circleConnPoint2.x + circleConn2.width  / 2
                                               : (mouseAreaGlobal.mouseX - mycanvas.x) / sliderZoom.value
                                y: circleConn2 ? circleConnPoint2.y + circleConn2.height / 2
                                               : (mouseAreaGlobal.mouseY - mycanvas.y) / sliderZoom.value
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

                        onConnectionSocketClicked: {
                            isConnecting = true
                            nodeConnections.model.append({
                                methodSignature1: conn.name, node: this,
                                circleConn: conn.circleConn, node2: null, methodSignature2: null
                            })
                            mouseAreaGlobal.enabled = true
                        }

                        borderColor:    ThemeManager.primaryColor
                        rootBodyColor:  "transparent"
                        behaviourObject: model.object

                        Component.onCompleted: {
                            behavioursZ[index] = 0
                            model.object.setViewRectangle(this)
                            // Place at the center of the currently visible viewport area,
                            // correctly accounting for current pan and zoom.
                            var cx = (containerCanvas.width  / 2 - mycanvas.x) / sliderZoom.value
                            var cy = (containerCanvas.height / 2 - mycanvas.y) / sliderZoom.value
                            viewComponentRectV2.x = cx - viewComponentRectV2.width  / 2
                            viewComponentRectV2.y = cy - viewComponentRectV2.height / 2
                        }

                        onZChanged: { behavioursZ[index] = z }

                        Component.onDestruction: {
                            behavioursZ = behavioursZ.slice(0, index)
                                          .concat(behavioursZ.slice(index + 1, behavioursZ.length))
                        }

                        onCloseButtonClicked: {
                            nodes.objectToDelete = model.object
                            nodes.model.remove(index)
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

    ProgressBar {
        id: progressX
        width: viewRect.width - 2
        height: 3

        value: 0
        from: 0
        to: 100

        anchors.bottom: viewRect.top
        anchors.left: viewRect.left
        Material.accent: ThemeManager.primaryColor
    }

    ProgressBar {
        id: progressY
        width: viewRect.height + 3
        height: 3

        value: 0
        from: 0
        to: 100

        rotation: -90

        anchors.left: viewRect.left
        anchors.bottom: viewRect.bottom
        anchors.bottomMargin: width/2
        anchors.leftMargin: - width/2 - 3
        Material.accent: ThemeManager.primaryColor
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
    Rectangle {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: topBarHeight
        z: 200
        color: Qt.darker(ThemeManager.backgroundColor, 1.35)

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: ThemeManager.primaryColor
            opacity: 0.3
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 8
            spacing: 0

            // App name + project
            Row {
                spacing: 0
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "Valkyrie"
                    font.pixelSize: 14
                    font.bold: true
                    font.letterSpacing: 0.8
                    color: ThemeManager.primaryColor
                    height: topBarHeight
                    verticalAlignment: Text.AlignVCenter
                }

                Item { width: 12; height: 1 }

                Rectangle {
                    width: 1; height: 16
                    color: ThemeManager.textColor
                    opacity: 0.3
                    anchors.verticalCenter: parent.verticalCenter
                }

                Item { width: 12; height: 1 }

                Text {
                    text: currentProject
                    font.pixelSize: 12
                    color: ThemeManager.textColor
                    opacity: 0.55
                    height: topBarHeight
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // Nav buttons – left-aligned, icon + text side by side
            Row {
                spacing: 0
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 8

                // Nodes
                Item {
                    width: nodesRow.implicitWidth + 24
                    height: topBarHeight

                    Rectangle {
                        anchors.fill: parent
                        color: ThemeManager.primaryColor
                        opacity: selectedPanel === "nodes" ? 0.12 : nodesHoverArea.containsMouse ? 0.06 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Row {
                        id: nodesRow
                        anchors.centerIn: parent
                        spacing: 7

                        Qaterial.ColorIcon {
                            source: Qaterial.Icons.graphOutline
                            color: selectedPanel === "nodes" ? ThemeManager.primaryColor : ThemeManager.textColor
                            width: 16; height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            text: "Nodes"
                            font.pixelSize: 11
                            color: selectedPanel === "nodes" ? ThemeManager.primaryColor : ThemeManager.textColor
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.leftMargin: 6; anchors.rightMargin: 6
                        height: 2; radius: 1
                        color: ThemeManager.primaryColor
                        visible: selectedPanel === "nodes"
                    }

                    MouseArea {
                        id: nodesHoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (selectedPanel === "nodes") {
                                selectedPanel = ""
                                leftPanelDrawer.close()
                            } else {
                                selectedPanel = "nodes"
                                leftPanelDrawer.open()
                            }
                        }
                    }
                }

                // Explorer
                Item {
                    width: explorerRow.implicitWidth + 24
                    height: topBarHeight

                    Rectangle {
                        anchors.fill: parent
                        color: ThemeManager.primaryColor
                        opacity: selectedPanel === "explorer" ? 0.12 : explorerHoverArea.containsMouse ? 0.06 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Row {
                        id: explorerRow
                        anchors.centerIn: parent
                        spacing: 7

                        Qaterial.ColorIcon {
                            source: Qaterial.Icons.folderOutline
                            color: selectedPanel === "explorer" ? ThemeManager.primaryColor : ThemeManager.textColor
                            width: 16; height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            text: "Explorer"
                            font.pixelSize: 11
                            color: selectedPanel === "explorer" ? ThemeManager.primaryColor : ThemeManager.textColor
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.leftMargin: 6; anchors.rightMargin: 6
                        height: 2; radius: 1
                        color: ThemeManager.primaryColor
                        visible: selectedPanel === "explorer"
                    }

                    MouseArea {
                        id: explorerHoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (selectedPanel === "explorer") {
                                selectedPanel = ""
                                leftPanelDrawer.close()
                            } else {
                                selectedPanel = "explorer"
                                leftPanelDrawer.open()
                            }
                        }
                    }
                }

                // Variables
                Item {
                    width: variablesRow.implicitWidth + 24
                    height: topBarHeight

                    Rectangle {
                        anchors.fill: parent
                        color: ThemeManager.primaryColor
                        opacity: selectedPanel === "variables" ? 0.12 : variablesHoverArea.containsMouse ? 0.06 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Row {
                        id: variablesRow
                        anchors.centerIn: parent
                        spacing: 7

                        Qaterial.ColorIcon {
                            source: Qaterial.Icons.codeJson
                            color: selectedPanel === "variables" ? ThemeManager.primaryColor : ThemeManager.textColor
                            width: 16; height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        Text {
                            text: "Variables"
                            font.pixelSize: 11
                            color: selectedPanel === "variables" ? ThemeManager.primaryColor : ThemeManager.textColor
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.leftMargin: 6; anchors.rightMargin: 6
                        height: 2; radius: 1
                        color: ThemeManager.primaryColor
                        visible: selectedPanel === "variables"
                    }

                    MouseArea {
                        id: variablesHoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (selectedPanel === "variables") {
                                selectedPanel = ""
                                leftPanelDrawer.close()
                            } else {
                                selectedPanel = "variables"
                                leftPanelDrawer.open()
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Right action buttons
            Row {
                spacing: 0
                Layout.alignment: Qt.AlignVCenter

                Qaterial.AppBarButton {
                    icon.source: Qaterial.Icons.contentSave
                    icon.color: ThemeManager.textColor
                    ToolTip.text: "Save"
                    ToolTip.visible: hovered
                    ToolTip.delay: 500
                    width: 40; height: 40
                }

                Qaterial.AppBarButton {
                    icon.source: Qaterial.Icons.folderOpenOutline
                    icon.color: ThemeManager.textColor
                    ToolTip.text: "Open Project"
                    ToolTip.visible: hovered
                    ToolTip.delay: 500
                    width: 40; height: 40
                }

                Qaterial.AppBarButton {
                    width: 40; height: 40
                    icon.source: Qaterial.Icons.cogOutline
                    icon.color: ThemeManager.textColor
                    ToolTip.text: "Settings"
                    ToolTip.visible: hovered
                    ToolTip.delay: 500
                    onClicked: settingsPopup.open()
                }
            }
        }
    }

    // ─── Settings Popup ─────────────────────────────────────────────────────────
    SettingsPopup {
        id: settingsPopup
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

            onXChanged: {
                progressX.value = Math.abs(x) % (viewRect.width+Math.abs(x));

            }

            onYChanged: {
                progressY.value = Math.abs(y) % (viewRect.height + Math.abs(y));
            }
        }
    }

    // ─── Status Bar ─────────────────────────────────────────────────────────────
    Rectangle {
        id: statusBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 22
        z: 200
        color: Qt.darker(ThemeManager.backgroundColor, 1.55)

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: ThemeManager.primaryColor
            opacity: 0.22
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 0

            // ── View center (where the user is looking)
            Text {
                text: "\u25ef"
                font.pixelSize: 9
                color: ThemeManager.primaryColor
                opacity: 0.80
                Layout.alignment: Qt.AlignVCenter
            }
            Item { Layout.preferredWidth: 4 }
            Text {
                font.pixelSize: 10
                color: ThemeManager.textColor
                opacity: 0.60
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 140
                text: {
                    var cx = Math.round((containerCanvas.width  / 2 - mycanvas.x) / sliderZoom.value)
                    var cy = Math.round((containerCanvas.height / 2 - mycanvas.y) / sliderZoom.value)
                    return "X " + cx + "  Y " + cy
                }
            }

            Rectangle {
                Layout.preferredWidth: 1; Layout.preferredHeight: 12
                Layout.alignment: Qt.AlignVCenter
                color: ThemeManager.textColor; opacity: 0.18
            }
            Item { Layout.preferredWidth: 10 }

            // ── Mouse world position (via HoverHandler — updates even over nodes)
            Text {
                text: "\u2316"
                font.pixelSize: 11
                color: ThemeManager.primaryColor
                opacity: 0.80
                Layout.alignment: Qt.AlignVCenter
            }
            Item { Layout.preferredWidth: 4 }
            Text {
                font.pixelSize: 10
                color: ThemeManager.textColor
                opacity: 0.60
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 140
                text: {
                    var mx = Math.round((globalHover.point.position.x - mycanvas.x) / sliderZoom.value)
                    var my = Math.round((globalHover.point.position.y - mycanvas.y) / sliderZoom.value)
                    return "X " + mx + "  Y " + my
                }
            }

            Rectangle {
                Layout.preferredWidth: 1; Layout.preferredHeight: 12
                Layout.alignment: Qt.AlignVCenter
                color: ThemeManager.textColor; opacity: 0.18
            }
            Item { Layout.preferredWidth: 10 }

            // ── Zoom level
            Text {
                text: "\u2295"
                font.pixelSize: 11
                color: ThemeManager.primaryColor
                opacity: 0.80
                Layout.alignment: Qt.AlignVCenter
            }
            Item { Layout.preferredWidth: 4 }
            Text {
                font.pixelSize: 10
                color: ThemeManager.textColor
                opacity: 0.60
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 44
                text: Math.round(sliderZoom.value * 100) + "%"
            }

            Rectangle {
                Layout.preferredWidth: 1; Layout.preferredHeight: 12
                Layout.alignment: Qt.AlignVCenter
                color: ThemeManager.textColor; opacity: 0.18
                visible: nodeOnFocus !== undefined && nodeOnFocus !== null
            }
            Item {
                Layout.preferredWidth: 10
                visible: nodeOnFocus !== undefined && nodeOnFocus !== null
            }

            // ── Selected node
            Text {
                text: "\u25c8"
                font.pixelSize: 10
                color: ThemeManager.primaryColor
                opacity: 0.85
                Layout.alignment: Qt.AlignVCenter
                visible: nodeOnFocus !== undefined && nodeOnFocus !== null
            }
            Item {
                Layout.preferredWidth: 5
                visible: nodeOnFocus !== undefined && nodeOnFocus !== null
            }
            Text {
                font.pixelSize: 10
                color: ThemeManager.textColor
                opacity: 0.65
                Layout.alignment: Qt.AlignVCenter
                Layout.maximumWidth: 160
                visible: nodeOnFocus !== undefined && nodeOnFocus !== null
                text: nodeOnFocus ? (nodeOnFocus.behaviourObject ? nodeOnFocus.behaviourObject.title : "Node") : ""
                elide: Text.ElideRight
            }

            Item { Layout.fillWidth: true }

            // ── Node count
            Text {
                font.pixelSize: 10
                color: ThemeManager.textColor
                opacity: 0.40
                Layout.alignment: Qt.AlignVCenter
                text: nodes.model.count + (nodes.model.count === 1 ? " node" : " nodes")
            }
        }
    }
}
