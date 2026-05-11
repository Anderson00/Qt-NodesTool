import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.12
import QtQuick.Shapes 1.15

import App.Theme 1.0


Rectangle {
    id: root
    property var actions: []

    width: body.implicitWidth
    height: body.implicitHeight
    color: Qt.rgba(ThemeManager.foregroundColor.r, ThemeManager.foregroundColor.g, ThemeManager.foregroundColor.b, 0.85)

    Shape {
        id: shape
        antialiasing: true
        width: 50
        height: root.height
        anchors.left: parent.right
        anchors.top: parent.top

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                GradientStop { position: 0; color: root.color }
            }
            strokeStyle: ShapePath.SolidLine
            //dashPattern: [ 1, 2 ]
            startX: 0; startY: 0
            PathLine { x: 0; y: shape.height }
            PathLine { x: shape.width; y: shape.height }
            PathLine { x: 0; y: 0 }
        }
    }

    RowLayout{
        id: body
        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
        }

        Repeater {
            id: btRepeater
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.actions

            AppBarButton {
                width: 40
                icon.source: modelData.icon ? "qrc:/icons/" + modelData.icon + ".svg" : "qrc:/icons/information.svg"
                icon.color: ThemeManager.primaryColor
                Layout.alignment: Qt.AlignLeft

                onClicked: {
                    if(actions[index].onClicked){
                        actions[index].onClicked()
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }
    }

}

