import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0
import QtQuick.Controls.Material 2.12
import QtGraphicalEffects 1.15

import Qaterial 1.0 as Qaterial

Rectangle {
    id: root

    property var connections: []
    property alias title: titleView.text
    property string borderColor: "green"

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
        anchors.fill: root
        hoverEnabled: true
        cursorShape: area.containsMouse ? Qt.OpenHandCursor : Qt.ArrowCursor
        drag.smoothed: true
        drag.target: root
    }

    RowLayout{
        anchors.left: root.left
        anchors.top: root.top
        anchors.right: root.right
        //width: parent.width
        anchors.margins: 4
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

    Rectangle {
        id: rootBody
        anchors.centerIn: parent
        width: parent.width - ((connectionRight.width + 8)*2)
        height: parent.height - ((connectionBottom.height + 8)*2)
        z:1
        color: "transparent"

        MouseArea {
            id: rootBodyArea
            anchors.fill: rootBody
            //hoverEnabled: true
            //cursorShape: rootBodyArea.containsMouse ? Qt.OpenHandCursor : Qt.ArrowCursor
            onClicked: {
                console.log("Clicked")
            }
        }
        Text {
            text: "Testando"
            color: "#333"
            anchors.centerIn: parent
        }
    }

    Column {
        id: connectionRight
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 4
        spacing: 2

        Repeater {
            id: connectionsRepeaterRight
            model: root.connections

            delegate: connectionComponent
        }
    }

    Row {
        id: connectionBottom
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 4
        spacing: 2

        Repeater {
            id: connectionsRepeaterBottom
            model: root.connections

            delegate: connectionComponent
        }
    }

    Component {
        id: connectionComponent
        Rectangle {
            width: 5
            height: 5
            radius: modelData.type === "unidirect"? 0 : width
            color: stringToColour(modelData.name)
        }
    }
}
