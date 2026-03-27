import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.12
import Qt5Compat.GraphicalEffects
import App.Theme 1.0

import Qaterial 1.0 as Qaterial

Rectangle {
    id: root

    property var behaviourObject

    property var connectionsInput: []
    property var connectionsOutput: []
    property alias title: titleView.text
    property string borderColor: "green"
    property alias rootBodyColor: rootBody.color
    property alias bodyComponent: rootBodyLoader.sourceComponent
    property alias bodySourceQML: rootBodyLoader.source
    property bool animEnabled: false

    property double xPrev: 0.0
    property double yPrev: 0.0
    
    property double minWidth: 150
    property double minHeight: 100
    
    property int resizeHandleSize: 8
    property bool isResizing: false
    property string resizeDirection: ""

    signal connectionSocketClicked(conn: var);

    // Menu
    signal closeButtonClicked();
    signal frontOneStepClicked();
    signal backOneStepClicked();
    signal frontTotalClicked();
    signal backTotalClicked();

    color: Qt.rgba(0.2, 0.2, 0.2, 0.5)
    radius: 4
    border.width: 1
    border.color: root.borderColor

    function stringToColour(str) {
        var hash = 0;
        for (var i = 0; i < str.length; i++) {
            hash = str.charCodeAt(i) + ((hash << 5) - hash);
        }
        var colour = '#';
        for (var i = 0; i < 3; i++) {
            var value = (hash >> (i * 8)) & 0xFF;
            colour += ('00' + value.toString(16)).substr(-2);
        }
        return colour;
    }

    function extractParams(text){
        return text.slice(text.indexOf('('), text.length - 1)
    }

    function connectionOnXYPosition(x:double, y:double) {
        let connJoint = [];
        connJoint = connJoint.concat(connectionsInput);
        connJoint = connJoint.concat(connectionsOutput);

        for(let i = 0; i < connJoint.length; i++){
            let conn = connJoint[i].connArea;
            let connPos = conn.mapToItem(this.parent, 0, 0);

            if((x >= connPos.x && x <= (conn.width + connPos.x)) &&
               (y >= connPos.y && y <= (conn.height + connPos.y))){
                return connJoint[i];
            }
        }

        return undefined;
    }

    function loadInputConns(){
        let connObj = [];
        let inputs = behaviourObject.getInputsMethodSignature();
        inputs.forEach((input) => connObj.push({'name' : input}));

        root.connectionsInput = connObj
    }

    function loadOutputConns(){
        let connObj = [];
        let outputs = behaviourObject.getOutputsMethodSignature();
        outputs.forEach((output) => connObj.push({'name' : output}));

        root.connectionsOutput = connObj
    }

    Component.onCompleted: {
        root.title = Qt.binding(() => behaviourObject.title)
        root.bodySourceQML = Qt.binding(() => behaviourObject.qmlBodyUrl)
        root.width = Qt.binding(() => behaviourObject.width)
        root.height = Qt.binding(() => behaviourObject.contentHeight + topHeader.height + divider.height + topHeader.anchors.margins + connectionsBody.height)
        root.x = Qt.binding(() => behaviourObject.x)
        root.y = Qt.binding(() => behaviourObject.y)
        loadInputConns()
        loadOutputConns()
        animEnabled = true
    }

    onXChanged: {
        behaviourObject.x = x
    }

    onYChanged: {
        behaviourObject.y = y
    }

    onWidthChanged: {
        behaviourObjectConn.enabled = false
        behaviourObject.contentWidth = width
        behaviourObjectConn.enabled = true
    }

    onHeightChanged: {
        behaviourObject.height = root.height
    }

    Connections {
        id: behaviourObjectConn
        target: behaviourObject

        function onContentWidthChanged(){
            behaviourObject.width = behaviourObject.contentWidth
        }
    }

    Connections {
        target: rootBodyLoader

        function onLoaded(){
            rootBodyLoader.item.behaviourObject = root.behaviourObject
        }
    }

    Behavior on height {
        enabled: animEnabled
        NumberAnimation {duration: 250; easing.type: Easing.OutQuad}
    }

    Behavior on width {
        enabled: animEnabled
        NumberAnimation {duration: 250; easing.type: Easing.OutQuad}
    }

    MouseArea {
        id: area
        z: 1
        anchors.fill: root
        hoverEnabled: true
        cursorShape: (area.containsMouse && !isResizing) ? Qt.OpenHandCursor : Qt.ArrowCursor
        drag.smoothed: true
        drag.target: root

        drag.minimumX: 0
        drag.minimumY: 0

        drag.maximumX: parent.parent.width - width
        drag.maximumY: parent.parent.height - height
        acceptedButtons: Qt.AllButtons;

        onClicked: {
            root.focus = true

            if(pressedButtons & Qt.RightButton){
                menu.open()
                root.focus = true
            }
        }
    }

    // Resize Handles
    // Top-Left Corner
    Rectangle {
        anchors.left: root.left
        anchors.top: root.top
        anchors.leftMargin: -resizeHandleSize / 2
        anchors.topMargin: -resizeHandleSize / 2
        width: resizeHandleSize
        height: resizeHandleSize
        radius: resizeHandleSize / 2
        color: isResizing && resizeDirection === "top-left" ? root.borderColor : Qt.rgba(0, 0, 0, 0)
        border.color: root.borderColor
        border.width: 1
        z: 20
        
        MouseArea {
            id: tlCorner
            anchors.centerIn: parent
            anchors.margins: -10
            width: resizeHandleSize + 20
            height: resizeHandleSize + 20
            hoverEnabled: true
            cursorShape: Qt.SizeFDiagCursor
            
            onEntered: parent.color = root.borderColor
            onExited: parent.color = isResizing && resizeDirection === "top-left" ? root.borderColor : Qt.rgba(0, 0, 0, 0)
            
            onPressed: {
                isResizing = true
                resizeDirection = "top-left"
                xPrev = mouse.x
                yPrev = mouse.y
            }
            
            onPositionChanged: {
                if (pressed && resizeDirection === "top-left") {
                    let deltaX = mouse.x - xPrev
                    let deltaY = mouse.y - yPrev
                    
                    let newWidth = root.width - deltaX
                    let newHeight = root.height - deltaY
                    
                    if (newWidth >= minWidth) {
                        root.x += deltaX
                        root.width = newWidth
                    }
                    if (newHeight >= minHeight) {
                        root.y += deltaY
                        root.height = newHeight
                    }
                }
            }
            
            onReleased: {
                isResizing = false
                resizeDirection = ""
            }
        }
    }

    // Top-Right Corner
    Rectangle {
        anchors.right: root.right
        anchors.top: root.top
        anchors.rightMargin: -resizeHandleSize / 2
        anchors.topMargin: -resizeHandleSize / 2
        width: resizeHandleSize
        height: resizeHandleSize
        radius: resizeHandleSize / 2
        color: isResizing && resizeDirection === "top-right" ? root.borderColor : Qt.rgba(0, 0, 0, 0)
        border.color: root.borderColor
        border.width: 1
        z: 20
        
        MouseArea {
            id: trCorner
            anchors.centerIn: parent
            anchors.margins: -10
            width: resizeHandleSize + 20
            height: resizeHandleSize + 20
            hoverEnabled: true
            cursorShape: Qt.SizeBDiagCursor
            
            onEntered: parent.color = root.borderColor
            onExited: parent.color = isResizing && resizeDirection === "top-right" ? root.borderColor : Qt.rgba(0, 0, 0, 0)
            
            onPressed: {
                isResizing = true
                resizeDirection = "top-right"
                xPrev = mouse.x
                yPrev = mouse.y
            }
            
            onPositionChanged: {
                if (pressed && resizeDirection === "top-right") {
                    let deltaX = mouse.x - xPrev
                    let deltaY = mouse.y - yPrev
                    
                    let newWidth = root.width + deltaX
                    let newHeight = root.height - deltaY
                    
                    if (newWidth >= minWidth) {
                        root.width = newWidth
                    }
                    if (newHeight >= minHeight) {
                        root.y += deltaY
                        root.height = newHeight
                    }
                }
            }
            
            onReleased: {
                isResizing = false
                resizeDirection = ""
            }
        }
    }

    // Bottom-Left Corner
    Rectangle {
        anchors.left: root.left
        anchors.bottom: root.bottom
        anchors.leftMargin: -resizeHandleSize / 2
        anchors.bottomMargin: -resizeHandleSize / 2
        width: resizeHandleSize
        height: resizeHandleSize
        radius: resizeHandleSize / 2
        color: isResizing && resizeDirection === "bottom-left" ? root.borderColor : Qt.rgba(0, 0, 0, 0)
        border.color: root.borderColor
        border.width: 1
        z: 20
        
        MouseArea {
            id: blCorner
            anchors.centerIn: parent
            anchors.margins: -10
            width: resizeHandleSize + 20
            height: resizeHandleSize + 20
            hoverEnabled: true
            cursorShape: Qt.SizeBDiagCursor
            
            onEntered: parent.color = root.borderColor
            onExited: parent.color = isResizing && resizeDirection === "bottom-left" ? root.borderColor : Qt.rgba(0, 0, 0, 0)
            
            onPressed: {
                isResizing = true
                resizeDirection = "bottom-left"
                xPrev = mouse.x
                yPrev = mouse.y
            }
            
            onPositionChanged: {
                if (pressed && resizeDirection === "bottom-left") {
                    let deltaX = mouse.x - xPrev
                    let deltaY = mouse.y - yPrev
                    
                    let newWidth = root.width - deltaX
                    let newHeight = root.height + deltaY
                    
                    if (newWidth >= minWidth) {
                        root.x += deltaX
                        root.width = newWidth
                    }
                    if (newHeight >= minHeight) {
                        root.height = newHeight
                    }
                }
            }
            
            onReleased: {
                isResizing = false
                resizeDirection = ""
            }
        }
    }

    // Bottom-Right Corner
    Rectangle {
        anchors.right: root.right
        anchors.bottom: root.bottom
        anchors.rightMargin: -resizeHandleSize / 2
        anchors.bottomMargin: -resizeHandleSize / 2
        width: resizeHandleSize
        height: resizeHandleSize
        radius: resizeHandleSize / 2
        color: isResizing && resizeDirection === "bottom-right" ? root.borderColor : Qt.rgba(0, 0, 0, 0)
        border.color: root.borderColor
        border.width: 1
        z: 20
        
        MouseArea {
            id: brCorner
            anchors.centerIn: parent
            anchors.margins: -10
            width: resizeHandleSize + 20
            height: resizeHandleSize + 20
            hoverEnabled: true
            cursorShape: Qt.SizeFDiagCursor
            
            onEntered: parent.color = root.borderColor
            onExited: parent.color = isResizing && resizeDirection === "bottom-right" ? root.borderColor : Qt.rgba(0, 0, 0, 0)
            
            onPressed: {
                isResizing = true
                resizeDirection = "bottom-right"
                xPrev = mouse.x
                yPrev = mouse.y
            }
            
            onPositionChanged: {
                if (pressed && resizeDirection === "bottom-right") {
                    let deltaX = mouse.x - xPrev
                    let deltaY = mouse.y - yPrev
                    
                    let newWidth = root.width + deltaX
                    let newHeight = root.height + deltaY
                    
                    if (newWidth >= minWidth) {
                        root.width = newWidth
                    }
                    if (newHeight >= minHeight) {
                        root.height = newHeight
                    }
                }
            }
            
            onReleased: {
                isResizing = false
                resizeDirection = ""
            }
        }
    }

    // Top Edge
    Rectangle {
        anchors.left: root.left
        anchors.right: root.right
        anchors.top: root.top
        anchors.leftMargin: resizeHandleSize
        anchors.rightMargin: resizeHandleSize
        anchors.topMargin: -resizeHandleSize / 2
        height: resizeHandleSize
        color: isResizing && resizeDirection === "top" ? root.borderColor : Qt.rgba(0, 0, 0, 0)
        border.color: root.borderColor
        border.width: 1
        z: 20
        
        MouseArea {
            id: topEdge
            anchors.fill: parent
            anchors.topMargin: -10
            anchors.bottomMargin: 0
            hoverEnabled: true
            cursorShape: Qt.SizeVerCursor
            
            onEntered: parent.color = root.borderColor
            onExited: parent.color = isResizing && resizeDirection === "top" ? root.borderColor : Qt.rgba(0, 0, 0, 0)
            
            onPressed: {
                isResizing = true
                resizeDirection = "top"
                yPrev = mouse.y
            }
            
            onPositionChanged: {
                if (pressed && resizeDirection === "top") {
                    let deltaY = mouse.y - yPrev
                    let newHeight = root.height - deltaY
                    
                    if (newHeight >= minHeight) {
                        root.y += deltaY
                        root.height = newHeight
                    }
                }
            }
            
            onReleased: {
                isResizing = false
                resizeDirection = ""
            }
        }
    }

    // Bottom Edge
    Rectangle {
        anchors.left: root.left
        anchors.right: root.right
        anchors.bottom: root.bottom
        anchors.leftMargin: resizeHandleSize
        anchors.rightMargin: resizeHandleSize
        anchors.bottomMargin: -resizeHandleSize / 2
        height: resizeHandleSize
        color: isResizing && resizeDirection === "bottom" ? root.borderColor : Qt.rgba(0, 0, 0, 0)
        border.color: root.borderColor
        border.width: 1
        z: 20
        
        MouseArea {
            id: bottomEdge
            anchors.fill: parent
            anchors.topMargin: 0
            anchors.bottomMargin: -10
            hoverEnabled: true
            cursorShape: Qt.SizeVerCursor
            
            onEntered: parent.color = root.borderColor
            onExited: parent.color = isResizing && resizeDirection === "bottom" ? root.borderColor : Qt.rgba(0, 0, 0, 0)
            
            onPressed: {
                isResizing = true
                resizeDirection = "bottom"
                yPrev = mouse.y
            }
            
            onPositionChanged: {
                if (pressed && resizeDirection === "bottom") {
                    let deltaY = mouse.y - yPrev
                    let newHeight = root.height + deltaY
                    
                    if (newHeight >= minHeight) {
                        root.height = newHeight
                    }
                }
            }
            
            onReleased: {
                isResizing = false
                resizeDirection = ""
            }
        }
    }

    // Left Edge
    Rectangle {
        anchors.left: root.left
        anchors.top: root.top
        anchors.bottom: root.bottom
        anchors.leftMargin: -resizeHandleSize / 2
        anchors.topMargin: resizeHandleSize
        anchors.bottomMargin: resizeHandleSize
        width: resizeHandleSize
        color: isResizing && resizeDirection === "left" ? root.borderColor : Qt.rgba(0, 0, 0, 0)
        border.color: root.borderColor
        border.width: 1
        z: 20
        
        MouseArea {
            id: leftEdge
            anchors.fill: parent
            anchors.leftMargin: -10
            anchors.rightMargin: 0
            hoverEnabled: true
            cursorShape: Qt.SizeHorCursor
            
            onEntered: parent.color = root.borderColor
            onExited: parent.color = isResizing && resizeDirection === "left" ? root.borderColor : Qt.rgba(0, 0, 0, 0)
            
            onPressed: {
                isResizing = true
                resizeDirection = "left"
                xPrev = mouse.x
            }
            
            onPositionChanged: {
                if (pressed && resizeDirection === "left") {
                    let deltaX = mouse.x - xPrev
                    let newWidth = root.width - deltaX
                    
                    if (newWidth >= minWidth) {
                        root.x += deltaX
                        root.width = newWidth
                    }
                }
            }
            
            onReleased: {
                isResizing = false
                resizeDirection = ""
            }
        }
    }

    // Right Edge
    Rectangle {
        anchors.right: root.right
        anchors.top: root.top
        anchors.bottom: root.bottom
        anchors.rightMargin: -resizeHandleSize / 2
        anchors.topMargin: resizeHandleSize
        anchors.bottomMargin: resizeHandleSize
        width: resizeHandleSize
        color: isResizing && resizeDirection === "right" ? root.borderColor : Qt.rgba(0, 0, 0, 0)
        border.color: root.borderColor
        border.width: 1
        z: 20
        
        MouseArea {
            id: rightEdge
            anchors.fill: parent
            anchors.leftMargin: 0
            anchors.rightMargin: -10
            hoverEnabled: true
            cursorShape: Qt.SizeHorCursor
            
            onEntered: parent.color = root.borderColor
            onExited: parent.color = isResizing && resizeDirection === "right" ? root.borderColor : Qt.rgba(0, 0, 0, 0)
            
            onPressed: {
                isResizing = true
                resizeDirection = "right"
                xPrev = mouse.x
            }
            
            onPositionChanged: {
                if (pressed && resizeDirection === "right") {
                    let deltaX = mouse.x - xPrev
                    let newWidth = root.width + deltaX
                    
                    if (newWidth >= minWidth) {
                        root.width = newWidth
                    }
                }
            }
            
            onReleased: {
                isResizing = false
                resizeDirection = ""
            }
        }
    }

    Rectangle {
        id: topHeaderRect
        anchors.left: root.left
        anchors.top: root.top
        anchors.right: root.right
        anchors.leftMargin: root.border.width
        anchors.topMargin: root.border.width
        anchors.rightMargin: root.border.width
        height: 25
        radius: root.radius - 1
        antialiasing: true

        z: 1
        color: root.focus ? root.border.color : root.color

        Rectangle {
            anchors.bottom: topHeaderRect.bottom
            width: parent.width
            height: root.radius
            color: topHeaderRect.color
            antialiasing: true
        }

        RowLayout{
            id: topHeader

            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            width: parent.width

            Text {
                id: titleView
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignCenter

                text: ""
                font.pixelSize: 8
                color: root.focus? "#333" : root.borderColor
            }

            NewButton {
                Layout.preferredHeight: 25
                Layout.preferredWidth: 20
                textColor: titleView.color
                iconSource: Qaterial.Icons.dotsVertical
                iconSize: 10
                variant: "text"
                onClicked: {
                    menu.open()
                }


                Menu {
                    id: menu
                    Material.foreground: ThemeManager.textColor

                    background: Rectangle {
                        color: ThemeManager.backgroundColor
                        border.color: ThemeManager.primaryColor
                        border.width: 1
                        radius: 4
                        implicitWidth: 200
                        implicitHeight: 40
                    }

                    onOpened: {
                        root.focus = true
                    }

                    onAboutToHide: {
                        root.focus = true
                    }

                    // Todo: repeater, dinamic items

                    //MenuSeparator {}

                    MenuItem {
                        text: "close"
                        icon.source: 'qrc:/Qaterial/Icons/close'
                        onTriggered: {
                            closeButtonClicked()
                        }
                    }

                    MenuItem {
                        text: "front + 1"
                        icon.source: 'qrc:/Qaterial/Icons/arrow-up'
                        onTriggered: {
                            frontOneStepClicked()
                        }
                    }

                    MenuItem {
                        text: "down - 1"
                        icon.source: 'qrc:/Qaterial/Icons/arrow-down'
                        onTriggered: {
                            backOneStepClicked()
                        }
                    }

                    MenuItem {
                        text: "front max"
                        icon.source: 'qrc:/Qaterial/Icons/flip-to-front'
                        onTriggered: {
                            frontTotalClicked()
                        }
                    }

                    MenuItem {
                        text: "back max"
                        icon.source: 'qrc:/Qaterial/Icons/flip-to-back'
                        onTriggered: {
                            backTotalClicked()
                        }
                    }
                }
            }

            NewButton {
                Layout.preferredHeight: 25
                Layout.preferredWidth: 20
                textColor: titleView.color
                iconSource: Qaterial.Icons.windowMaximize
                iconSize: 10
                variant: "text"
                onClicked: {
                    console.log("Maximize clicked")
                }
            }

            NewButton {
                Layout.preferredHeight: 25
                Layout.preferredWidth: 20
                textColor: titleView.color
                iconSource: Qaterial.Icons.close
                iconSize: 10
                variant: "text"
                onClicked: {
                    closeButtonClicked()
                }
            }
        }
    }

    Rectangle{
        id: divider
        color: root.border.color
        height: 1
        anchors.top: topHeaderRect.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 1
        anchors.rightMargin: 1
    }

    ColumnLayout {
        id: body
        anchors.top: divider.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 1
        anchors.rightMargin: 1
        anchors.bottomMargin: 1
        clip: true
        spacing: 0
        z:2

        RowLayout {
            id: connectionsBody
            Layout.fillWidth: true
            spacing: 0
            z:3
            visible: connectionsInput.length > 0 || connectionsOutput.length > 0

            SplitView {
                id: splitConns
                orientation: Qt.Horizontal
                Layout.fillWidth: true
                Layout.preferredHeight: ((columnLayoutInputConns.height > columnLayoutOutputConns.height)? columnLayoutInputConns.height : columnLayoutOutputConns.height) + 8

                Rectangle {
                    id: connectionsInputBody
                    Layout.preferredHeight: ((columnLayoutInputConns.height > columnLayoutOutputConns.height)? columnLayoutInputConns.height: columnLayoutOutputConns.height) + 4
                    Layout.fillWidth: true
                    SplitView.minimumWidth: 10
                    SplitView.preferredWidth: parent.width / 2

                    color: "#444"

                    ColumnLayout {
                        id: columnLayoutInputConns
                        width: parent.width
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.leftMargin: 4
                        anchors.topMargin: 2

                        Repeater {
                            Layout.fillWidth: true
                            model: connectionsInput
                            Rectangle {
                                id: inputArea
                                width: connInName.width + connInConnCircle.width
                                height: rowInput.height
                                color: 'transparent'

                                Component.onCompleted: {
                                    connectionsInput[index].connArea = inputArea
                                    connectionsInput[index].circleConn = connInConnCircle
                                }

                                MouseArea {
                                    width: connectionsInputBody.width - 4
                                    height: rowInput.height
                                    preventStealing: true

                                    onClicked: {
                                        console.log(modelData.name)
                                        root.connectionSocketClicked(connectionsInput[index])
                                    }
                                }

                                Row {
                                    id: rowInput
                                    Layout.alignment: Qt.AlignLeft
                                    spacing: 2

                                    Rectangle {
                                        id: connInConnCircle
                                        width: 4
                                        height: connInConnCircle.width
                                        radius: connInConnCircle.width                                        
                                        color: stringToColour(extractParams(connInName.text))
                                        anchors.verticalCenter: connInName.verticalCenter
                                    }

                                    Text {
                                        id: connInName
                                        font.pixelSize: 8
                                        color: "#ccc"
                                        text: modelData.name
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    clip: true
                    id: connectionsOutputBody
                    Layout.preferredHeight: ((columnLayoutInputConns.height > columnLayoutOutputConns.height)? columnLayoutInputConns.height: columnLayoutOutputConns.height) + 4
                    Layout.fillWidth: true
                    SplitView.minimumWidth: 10
                    SplitView.preferredWidth: parent.width / 2

                    color: "#222"

                    ColumnLayout {
                        id: columnLayoutOutputConns
                        //width: parent.width
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: 4
                        anchors.topMargin: 2
                        Repeater {
                            Layout.fillWidth: true
                            model: connectionsOutput

                            Rectangle {
                                id: outputArea
                                width: connOutName.width + 8
                                Layout.alignment: Qt.AlignRight
                                height: connOutName.height
                                color: 'transparent'

                                Component.onCompleted: {
                                    connectionsOutput[index].connArea = outputArea
                                    connectionsOutput[index].circleConn = connOutConnCircle
                                }

                                MouseArea {
                                    width: connectionsOutputBody.width
                                    height: connOutName.height

                                    onClicked: {
                                        root.connectionSocketClicked(connectionsOutput[index])
                                    }
                                }

                                Row {
                                    id: rowOutput
                                    anchors.right: parent.right
                                    spacing: 2

                                    Text {
                                        id: connOutName
                                        font.pixelSize: 8
                                        color: "#ccc"
                                        text: modelData.name
                                    }                                    

                                    Rectangle {
                                        id: connOutConnCircle
                                        width: 4
                                        height: connOutConnCircle.width
                                        radius: connOutConnCircle.width
                                        color: stringToColour(extractParams(connOutName.text))
                                        anchors.verticalCenter: connOutName.verticalCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: rootBody
            Layout.fillHeight: true
            Layout.fillWidth: true
            z:2
            radius: root.radius
            clip: true
            color: "#333"

            Loader {
                id: rootBodyLoader
                anchors.fill: parent
            }
        }
    }
}
