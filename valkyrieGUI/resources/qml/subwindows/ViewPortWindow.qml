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
        if(nodeOnFocus){
            console.log('>>' + nodeOnFocus.behaviourObject.title)
        }
    }

    property bool rightDrawerOpened: false
    property bool bottomDrawerOpened: false
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

    function detectNodeByMousePosition(x: double, y : double){
        for(let i = 0; i < nodes.model.count; i++){
            let node = nodes.model.get(i)['object'];
            if((x >= node.x && x <= (node.width + node.x)) &&
               (y >= node.y && y <= (node.height + node.y))){
                return node;
            }
        }
        return undefined;
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
            fabBottomMenu.anchors.bottomMargin = parent.height - y
            toolbar.anchors.bottomMargin = parent.height - y
            viewRect.anchors.bottomMargin = fabBottomMenu.anchors.bottomMargin + 8
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
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: false
        preventStealing: true
        z: 10
        enabled: false

        onClicked: {
            // TODO: dinamic code, this is a prototype
            // shapepath.startX = mouse.x;
            // shapepath.startY = mouse.y;
            mouseAreaGlobal.enabled = false
            isConnecting = false
            console.log(shapeConn.circleConnPoint2)

            let node = detectNodeByMousePosition(mouse.x, mouse.y)
            let viewRect = (node)? node.viewRect : undefined
            let conn;
            let lastConnection = nodeConnections.model.count - 1;
            if(viewRect){
                conn = viewRect.connectionOnXYPosition(mouse.x, mouse.y)
                if(conn){
                    shapeConn.circleConn2 = conn.circleConn
                    shapeConn.viewRectConn2 = node

                    //TODO:
                    //node.
                    nodeConnections.model.set(lastConnection, {node2: node, methodSignature2: conn.name})

                    let node1 = nodeConnections.model.get(lastConnection);
                    let isValid = node1['node'].behaviourObject.addConnection(node1['methodSignature1'], node1['node2'], node1['methodSignature2'])
                    if(isValid){
                        // TODO:
                        nodeConnected(node, shapeConn.viewRectConn2)
                    }else{
                        nodeConnections.model.remove(lastConnection)
                    }
                }else{
                    nodeConnections.model.remove(lastConnection)
                }
            }else {
                nodeConnections.model.remove(lastConnection)
            }

            shapeConn = undefined;
            mouse.accepted = false
        }

        onPositionChanged: {
            // TODO: dinamic code, this is a prototype
            // shapepath.startX = mouse.x;
            // shapepath.startY = mouse.y;
            mouseXX = mouse.x;
            mouseYY = mouse.y;

            mouse.accepted = false

            let node = detectNodeByMousePosition(mouse.x, mouse.y)
            let viewRect = (node)? node.viewRect : undefined
            let conn;
            if(viewRect){
                conn = viewRect.connectionOnXYPosition(mouse.x, mouse.y)
            }
        }
    }

    MouseArea {
        id: mouseZoom
        anchors.fill: parent
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
            if(isConnecting)
                return;

            let oldZoom = sliderZoom.value
            let newZoom = oldZoom + (wheel.angleDelta.y > 0 ? 0.1 : -0.1)
            newZoom = Math.max(sliderZoom.from, Math.min(sliderZoom.to, newZoom))

            // Definir a origem do zoom na posição do mouse
            canvasScale.origin.x = mouseZoom.zoomMouseX
            canvasScale.origin.y = mouseZoom.zoomMouseY

            sliderZoom.value = newZoom
        }
    }

    Column {
        id: fullscreenFab
        anchors.top: root.top
        anchors.left: root.left
        anchors.margins: 8
        spacing: 2
        z: 100

        Qaterial.MiniFabButton {

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
            opacity: (mycanvas.x == 0 && mycanvas.y == 0 && sliderZoom.value == 1)? 0.3 : 1

            onClicked: {
                if(opacity == 1){
                    mycanvas.x = 0;
                    mycanvas.y = 0;
                    sliderZoom.value = 1;
                }
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
        anchors.left: fullscreenFab.right
        anchors.top: parent.top
        anchors.topMargin: 8
        prefix: "x"

        onValueChanged: {
            if(isConnecting)
                return;
            mycanvas.wgrid = sliderZoom.value * minWgrid
            mycanvas.requestPaint()
        }
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
        color: ThemeManager.primaryColor
        opacity: 0.5
        width: 100
        height: 50
        anchors.horizontalCenter: parent.horizontalCenter
        radius: 8

        ColumnLayout {
            anchors.fill: parent
            Layout.alignment: Qt.AlignCenter

            Label {
                id: fpsCounter
                color: "#EAEAEA"
                text: `${viewPort.fpsCount} FPS`
                Layout.alignment: Qt.AlignCenter
            }

            Label {
                id: fpsTime
                color: "#EAEAEA"
                text: `${viewPort.fpsCount > 0? (1000/viewPort.fpsCount).toFixed(2) : 0} ms`
                Layout.alignment: Qt.AlignCenter
            }
        }
    }

    Rectangle {
        id: containerCanvas
        width: parent.width
        height: parent.height
        color: "transparent"

        Canvas {
            id: mycanvas
            width: parent.width
            height: parent.height
            property real wgrid: root.minWgrid / sliderZoom.value;

            Component.onCompleted: {
                mycanvas.requestPaint()
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
                }

            }

            Rectangle{
                id: mycanvasBody
                anchors.fill: parent
                border.width: 1
                border.color: ThemeManager.primaryColor
                color: "transparent"

                Repeater {
                    id: nodeConnections

                    model: ListModel {

                    }

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
                            circleConnPoint = model.circleConn.mapToItem(parent, 0, 0);
                            shapeConn = shape;

                        }

                        onCircleConn2Changed: {
                            if(circleConn2){
                                circleConnPoint2 = circleConn2.mapToItem(parent, 0, 0);
                            }else{
                                // TODO: remove connection in CPP/Behaviour
                                nodeConnections.model.remove(index)
                            }
                        }

                        Connections {
                            target: model.node

                            function onCloseButtonClicked(){
                                nodeConnections.model.remove(index)
                            }

                            function onXChanged(){
                                circleConnPoint = model.circleConn.mapToItem(parent, 0, 0);
                            }

                            function onYChanged(){
                                circleConnPoint = model.circleConn.mapToItem(parent, 0, 0);
                            }
                        }

                        Connections {
                            target: viewRectConn2

                            function onXChanged(){
                                circleConnPoint2 = circleConn2.mapToItem(parent, 0, 0);
                            }

                            function onYChanged(){
                                circleConnPoint2 = circleConn2.mapToItem(parent, 0, 0);
                            }
                        }

                        ShapePath {
                            id: shapepath
                            strokeColor: model.circleConn.color
                            strokeWidth: 2
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap

                            startX: circleConnPoint.x + model.circleConn.width/2
                            startY: circleConnPoint.y + model.circleConn.height/2

                            PathLine {
                                id: lineTest
                                x: circleConn2 ? circleConnPoint2.x + circleConn2.width/2 : mouseAreaGlobal.mouseX
                                y: circleConn2 ? circleConnPoint2.y + circleConn2.width/2 : mouseAreaGlobal.mouseY
                            }
                        }
                    }
                }

                Repeater {
                    id: nodes

                    property var objectToDelete;

                    model: ListModel{
                        onCountChanged: {
                            if(nodes.objectToDelete){
                                viewPort.removeBehaviourObject(nodes.objectToDelete);
                                nodes.objectToDelete = null;
                            }
                        }
                    }

                    delegate: ViewComponentRectV2 {
                        id: viewComponentRectV2

                        Connections {
                            target: mycanvasBody

                            function onWidthChanged() {
                                viewComponentRectV2.x = clamp(viewComponentRectV2.x, 0, mycanvasBody.width - viewComponentRectV2.width)
                            }

                            function onHeightChanged() {
                                viewComponentRectV2.y = clamp(viewComponentRectV2.y, 0, mycanvasBody.height - viewComponentRectV2.height)
                            }
                        }

                        onXChanged: {
                            this.focus = true
                            if(nodeOnFocus !== this)
                                nodeOnFocus = this
                        }

                        onYChanged: {
                            this.focus = true
                            if(nodeOnFocus !== this)
                                nodeOnFocus = this
                        }

                        onFocusChanged: {
                            if(focus)
                                nodeOnFocus = this
                        }

                        onConnectionSocketClicked: {
                            isConnecting = true
                            mycanvas.x = 0;
                            mycanvas.y = 0;
                            sliderZoom.value = 1;
                            nodeConnections.model.append({methodSignature1: conn.name, node: this, circleConn: conn.circleConn, node2: null, methodSignature2: null})
                            mouseAreaGlobal.enabled = true
                            //fogForNodeConnections.visible = true
                        }

                        borderColor: ThemeManager.primaryColor
                        rootBodyColor: "transparent"

                        behaviourObject: model.object

                        Component.onCompleted: {
                            behavioursZ[index] = 0
                            model.object.setViewRectangle(this)

                            behaviourObject.x = mycanvasBody.width/2 - width/2
                            behaviourObject.y = mycanvasBody.height/2 - height/2
                        }

                        onZChanged: {
                            behavioursZ[index] = z
                        }

                        Component.onDestruction: {
                            behavioursZ = behavioursZ.slice(0, index).concat(behavioursZ.slice(index + 1,behavioursZ.length))
                        }

                        onCloseButtonClicked: {
                            nodes.objectToDelete = model.object
                            nodes.model.remove(index);
                        }

                        onFrontOneStepClicked: {
                            z += 1
                        }

                        onBackOneStepClicked: {
                            z = ((z - 1) < 1) ? 0 : z - 1;
                        }

                        onFrontTotalClicked: {
                            z = getBehaviourGreaterZ() + 1;
                        }

                        onBackTotalClicked: {
                            z = 0;
                        }
                    }
                }
            }

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0,0, width, height)
                ctx.lineWidth = 0.3 / sliderZoom.value
                ctx.strokeStyle = "#535C27"
                ctx.beginPath()
                var nrows = height / wgrid;
                for(var i = 0; i < nrows+1; i++){
                    ctx.moveTo(0, wgrid*i);
                    ctx.lineTo(width, wgrid*i);
                }

                var ncols = width / wgrid
                for(var j = 0; j < ncols+1; j++){
                    ctx.moveTo(wgrid*j, 0);
                    ctx.lineTo(wgrid*j, height);
                }
                ctx.closePath()
                ctx.stroke()
            }
        }
    }

    ProgressBar {
        id: progressX
        width: viewRect.width
        height: 3

        value: 10
        from: 0
        to: 100

        anchors.bottom: viewRect.top
        anchors.left: viewRect.left
    }

    ProgressBar {
        id: progressY
        width: viewRect.height + 4
        height: 3

        value: 10
        from: 0
        to: 100

        rotation: -90

        anchors.left: viewRect.left
        anchors.bottom: viewRect.bottom
        anchors.bottomMargin: width/2
        anchors.leftMargin: - width/2 - 3
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

    Rectangle {
        id: viewRect
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.bottomMargin: 8
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

            x: -(mycanvas.x / (viewRect.width * 0.3));
            y: -(mycanvas.y / (viewRect.height * 0.3));

            onXChanged: {
                progressX.value = Math.abs(x) % (viewRect.width+Math.abs(x));

            }

            onYChanged: {
                progressY.value = Math.abs(y) % (viewRect.height + Math.abs(y));
            }
        }
    }
}
