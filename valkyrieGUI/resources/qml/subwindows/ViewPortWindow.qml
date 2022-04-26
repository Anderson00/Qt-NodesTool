import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.0
import QtQuick.Shapes 1.15

import "../components"
import "../components/bottomsheets"
import Qaterial 1.0 as Qaterial

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

    onNodeOnFocusChanged: {
        if(nodeOnFocus){
            console.log('>>' + nodeOnFocus.behaviourObject.title)
        }
    }

    property bool rightDrawerOpened: false
    property bool bottomDrawerOpened: false
    anchors.fill: parent
    clip: true

    color: '#27191c'

    onWidthChanged: {
        viewSubWindowsWidthHeightArea()
    }

    onHeightChanged: {
        viewSubWindowsWidthHeightArea()
    }

    Connections {
        target: viewPort

        function onBehaviourAdded(obj){
            nodes.model.append({'object':obj})
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
        icon.color: Material.accentColor
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
        icon.color: Material.accentColor
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

        onClicked: {
            console.log('qwd')
            root.focus = true
        }

        onWheel: {
            if(isConnecting)
                return;
            if (wheel.angleDelta.y > 0)
                sliderZoom.value += 0.1;
            else
               sliderZoom.value -= 0.1;
        }
    }

    Connections{
        target: viewPort

        function fullScreenToogle(){
           // console.log(val);
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
            icon.color: Material.accentColor
            flat: false


            onClicked: {
                if(icon.source == Qaterial.Icons.fullscreen)
                    icon.source = Qaterial.Icons.fullscreenExit
                else
                    icon.source = Qaterial.Icons.fullscreen

                viewPort.setFullScreen(true);
            }
        }

        Qaterial.MiniFabButton {
            id: centerButton
            icon.source: Qaterial.Icons.setCenter
            icon.color: Material.accentColor
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
        color: Material.accentColor
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

    Canvas {
        id: mycanvas
        width: parent.width
        height: parent.height
        property int wgrid: sliderZoom.value * root.minWgrid;

        Component.onCompleted: {
            mycanvas.requestPaint()
        }

        transform: Scale {            
            origin.x: 0
            origin.y: 0
            xScale: sliderZoom.value
            yScale: sliderZoom.value
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent

            //drag.active: !isConnecting
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
            border.color: "#96a0cd"
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
                        if(circleConn2)
                            circleConnPoint2 = circleConn2.mapToItem(parent, 0, 0);
                        else{
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

                model: ListModel{

                }

                delegate: ViewComponentRectV2 {

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
                        console.log(">>>>>>> focus:" + this.focus)
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

                    borderColor: Material.accentColor
                    rootBodyColor: "transparent"

                    behaviourObject: model.object

                    Component.onCompleted: {
                        behavioursZ[index] = 0
                        model.object.setViewRectangle(this)
                    }

                    onZChanged: {
                        behavioursZ[index] = z
                    }

                    Component.onDestruction: {
                        behavioursZ = behavioursZ.slice(0, index).concat(behavioursZ.slice(index + 1,behavioursZ.length))
                    }

                    onCloseButtonClicked: {
                        nodes.model.remove(index)
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
            ctx.lineWidth = 0.3
            ctx.strokeStyle = "#114d4d"
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
        border.color: "#96a0cd"
        radius: 4

        width: parent.width / 10
        height: parent.height / 10

        Repeater {
            id: viewRectGhostConns
            model: ListModel {

            }

            delegate: Shape {
                antialiasing: true
                smooth: true
                z: Number.MAX_VALUE

                Component.onCompleted: {
                    //circleConnPoint = model.rect.mapToItem(parent, 0, 0);
                }

                Connections {
                    target: model.rect1

                    function onXChanged(){
                        //circleConnPoint = model.circleConn.mapToItem(parent, 0, 0);
                    }

                    function onYChanged(){
                        //circleConnPoint = model.circleConn.mapToItem(parent, 0, 0);
                    }
                }

                Connections {
                    target:  model.rect2

                    function onXChanged(){
                        //circleConnPoint2 = circleConn2.mapToItem(parent, 0, 0);
                    }

                    function onYChanged(){
                        //circleConnPoint2 = circleConn2.mapToItem(parent, 0, 0);
                    }
                }

                ShapePath {
                    strokeColor: "red"
                    strokeWidth: 2
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap

                    startX: model.rect1.x
                    startY: model.rect1.y

                    PathLine {
                        x: model.rect2.x
                        y: model.rect2.y
                    }
                }
            }
        }

        Repeater {
            model: nodes.model

            delegate: Rectangle {
                id: rectObj
                width: model.object.width / 10
                height: model.object.height / 10
                radius: 4 / 10
                x: model.object.x / 10
                y: model.object.y / 10
                opacity: 0.3
                color: '#ccc'

                Component.onCompleted: {
                    //viewRectGhostConns.model.append({rect1: this, rect2: parent.parent});
                }

                SequentialAnimation {
                    id: sequential
                    running: (nodeOnFocus) ? nodeOnFocus.behaviourObject === model.object : false
                    loops: Animation.Infinite

                    onRunningChanged: {
                        if(!running){
                            opacity = 0.3
                        }
                    }

                    NumberAnimation {
                        id: animateOpacity
                        target: rectObj
                        property: "opacity"
                        from: 0.5
                        to: 1.0
                        duration: 250
                        //easing {type: Easing.OutBack; overshoot: 500}
                    }

                    NumberAnimation {
                        id: animateOpacity2
                        target: rectObj
                        property: "opacity"
                        from: 1.0
                        to: 0.5
                        duration: 250
                        //easing {type: Easing.OutBack; overshoot: 500}
                    }
                }

            }
        }

        Rectangle {
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
