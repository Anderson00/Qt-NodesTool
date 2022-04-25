import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.14
import QtQuick.Window 2.2
import QtQuick 2.14
import QtQml 2.14

import Qaterial 1.0 as Qaterial

import '../'

Drawer {
    id: root

    property QtObject viewPortWindow
    property var selectedObjectView

    width: parent.width
    height: 200
    modal: false
    edge: Qt.BottomEdge
    interactive: false

    function clear(){

    }

    function clamp(value, min, max){
        if(value <= min)
            return min
        else if(value >= max)
            return max
        return value
    }

    background: Rectangle {
        color: Qt.rgba(0.2, 0.2, 0.2, 0.8)
    }

    onSelectedObjectViewChanged: {
        if(selectedObjectView){
            name.text = selectedObjectView.behaviourObject.title
            objectX.text = selectedObjectView.x
            objectY.text = selectedObjectView.y
        }else{
            clear()
        }
    }

    Connections {
        target: selectedObjectView

        function onXChanged(){
            objectX.text = selectedObjectView.x.toFixed(0)
        }

        function onYChanged(){
            objectY.text = selectedObjectView.y.toFixed(0)
        }
    }

    // TODO: content, list of properties insipired in unity3d, blender, etc.
    ScrollView {
        width: root.width
        height: parent.height

        Rectangle {
            width: parent.width
            color: 'red'

            ColumnLayout {
                id: columnLayout
                spacing: 0
                width: parent.width
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right

                anchors.margins: 4

                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: -4
                    Layout.leftMargin: -5
                    Layout.rightMargin: -4
                    height: 40
                    color: '#222'
                    Label {
                        id: name
                        text: ''
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 4
                        color: Material.accentColor
                    }
                }

                RowLayout {
                    Label {
                        text: 'X:'
                    }

                    CustomTextField {
                        id: objectX
                        placeholderText: '0.00'

                        onTextEdited: {
                            objectX.text = Number(/[0-9]*/.exec(objectX.text)).toFixed(0)
                            selectedObjectView.x = Number(clamp(objectX.text, 0, viewPortWindow.width - selectedObjectView.width)).toFixed(0)
                            objectX.forceActiveFocus()
                        }
                    }


                    Label {
                        text: 'Y:'
                    }

                    CustomTextField {
                        id: objectY
                        placeholderText: '0.00'

                        onTextEdited: {
                            objectY.text = Number(/[0-9]*/.exec(objectY.text)).toFixed(0)
                            selectedObjectView.y = Number(clamp(objectY.text, 0, viewPortWindow.height - selectedObjectView.height)).toFixed(0)
                            objectY.forceActiveFocus()
                        }
                    }
                }
            }
        }
    }
}
