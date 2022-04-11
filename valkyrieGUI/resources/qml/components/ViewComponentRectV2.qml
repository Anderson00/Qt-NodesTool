import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.12
import QtGraphicalEffects 1.15

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

        console.log(x + " " + y)
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
        cursorShape: area.containsMouse ? Qt.OpenHandCursor : Qt.ArrowCursor
        drag.smoothed: true
        drag.target: root

        drag.minimumX: 0
        drag.minimumY: 0

        drag.maximumX: parent.parent.width - width
        drag.maximumY: parent.parent.height - height
        acceptedButtons: Qt.AllButtons;

        onClicked: {
            console.log('ckicled')
            root.focus = true

            if(pressedButtons & Qt.RightButton){
                menu.open()
            }
        }
    }

    RowLayout{
        id: topHeader
        anchors.left: root.left
        anchors.top: root.top
        anchors.right: root.right
        height: titleView.height + 8
        //width: parent.width
        anchors.margins: 4
        anchors.bottomMargin: 0
        z: 1

        Text {
            id: titleView
            Layout.fillWidth: true

            text: ""
            font.pixelSize: 8
            color: root.borderColor

        }

        Rectangle {
            Layout.preferredHeight: 10
            width: 10
            color: Qt.rgba(0.2, 0.2, 0.2, 0.5)
            radius: 10

            MouseArea {
                anchors.fill: parent
                z: 2

                onClicked: {
                    menu.open()
                }
            }

            Menu {
                id: menu

                // Todo: repeater, dinamic items

                MenuSeparator {}

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

            Column{
                anchors.centerIn: parent
                spacing: 1
                Repeater {
                    model: 3
                    Rectangle {
                        width: 2
                        height: width
                        radius: width
                        color: root.borderColor
                    }
                }
            }
        }
    }

    Rectangle{
        id: divider
        color: root.border.color
        height: 1
        anchors.top: topHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
    }

    ColumnLayout {
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
                Layout.preferredHeight: ((columnLayoutInputConns.height > columnLayoutOutputConns.height)? columnLayoutInputConns.height: columnLayoutOutputConns.height) + 4

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
                            Item {
                                width: parent.width
                                height: rowInput.height

                                Component.onCompleted: {
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
                                        color: stringToColour(connInName.text)
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
                                width: connOutName.width + 8
                                Layout.alignment: Qt.AlignRight
                                height: connOutName.height
                                color: 'transparent'

                                Component.onCompleted: {
                                    connectionsOutput[index].circleConn = connOutConnCircle
                                }

                                MouseArea {
                                    width: connectionsOutputBody.width
                                    height: connOutName.height

                                    onClicked: {
                                        console.log(modelData.name)
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
                                        color: stringToColour(connOutName.text)
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

            Loader{
                id: rootBodyLoader
                anchors.fill: parent
            }
        }
    }
}
