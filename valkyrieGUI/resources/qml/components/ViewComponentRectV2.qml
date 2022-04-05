import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.12
import QtGraphicalEffects 1.15

import Qaterial 1.0 as Qaterial

Rectangle {
    id: root

    property var connectionsInput: []
    property var connectionsOutput: []
    property alias title: titleView.text
    property string borderColor: "green"
    property alias rootBodyColor: rootBody.color
    property alias bodyComponent: rootBodyLoader.sourceComponent

    property double xPrev: 0.0
    property double yPrev: 0.0

    signal connectionSocketClicked(conn: var);

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

            text: "Titulo Janela"
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
                        root.destroy()
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

            Rectangle {
                id: connectionsInputBody
                Layout.preferredHeight: ((columnLayoutInputConns.height > columnLayoutOutputConns.height)? columnLayoutInputConns.height: columnLayoutOutputConns.height) + 4
                Layout.fillWidth: true

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
                                width: rowInput.width
                                height: rowInput.height

                                onClicked: {
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
                id: connectionsOutputBody
                Layout.preferredHeight: ((columnLayoutInputConns.height > columnLayoutOutputConns.height)? columnLayoutInputConns.height: columnLayoutOutputConns.height) + 4
                Layout.fillWidth: true

                color: "#222"

                ColumnLayout {
                    id: columnLayoutOutputConns
                    width: parent.width
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: 4
                    anchors.topMargin: 2
                    Repeater {
                        model: connectionsOutput
                        Row {
                            Layout.alignment: Qt.AlignRight
                            spacing: 2

                            Component.onCompleted: {
                                connectionsOutput[index].circleConn = connOutConnCircle
                            }

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

        Rectangle {
            id: rootBody
            Layout.fillHeight: true
            Layout.fillWidth: true
            z:2
            radius: root.radius
            clip: true
            color: "#333"

            MouseArea {
                id: rootBodyArea
                anchors.fill: rootBody
                //hoverEnabled: true
                //cursorShape: rootBodyArea.containsMouse ? Qt.OpenHandCursor : Qt.ArrowCursor
                onClicked: {
                    console.log("Clicked")
                }
            }

            Loader{
                id: rootBodyLoader
                anchors.fill: parent
            }
        }
    }
}
