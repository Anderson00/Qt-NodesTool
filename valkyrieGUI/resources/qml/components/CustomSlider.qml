import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.12

import App.Theme 1.0
import Qaterial 1.0 as Qaterial

Item {
    id: root    
    //property alias orientation: slider.orientation;
    property string prefix: ""
    property string color: ""
    property string textColor: "#fff"
    //property alias color: slider.color
    property alias value: slider.value
    property alias from: slider.from
    property alias to: slider.to

    width: 200
    height: layout.height
    clip: false

    Rectangle {
        id: labelFloatingBody
        color: "transparent"
        width: labelFloating.width
        height: labelFloating.height

        opacity: 0.0

        Qaterial.Label {
            id: labelFloating
            text: slider.value.toFixed(0) + prefix
            color: root.textColor
        }

        x: layout.x + slider.x + slider.leftPadding + slider.visualPosition * (slider.availableWidth - 16) + 8 - width / 2
        y: layout.y + slider.y + slider.topPadding + slider.availableHeight / 2 - 8 - height - 4
        z: 1

        Behavior on x {
            NumberAnimation { duration: 50 }
        }

        NumberAnimation {
            id: animateOpacity
            target: labelFloatingBody
            properties: "opacity"
            from: 0.0
            to: 1.0
            duration: 500
        }
    }

    RowLayout{
        id: layout
        width: parent.width
        height: slider.height
        anchors.bottom: parent.bottom
        spacing: 0

        Slider {
            id: slider
            from: 5
            to: 100
            Layout.fillWidth: true

            value: 5

            background: Rectangle {
                x: slider.leftPadding
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: slider.availableWidth
                height: 4
                radius: 2
                color: "#555555"

                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    color: root.color !== "" ? root.color : ThemeManager.primaryColor
                    radius: 2
                }
            }

            handle: Rectangle {
                x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                y: slider.topPadding + slider.availableHeight / 2 - height / 2
                width: 16
                height: 16
                radius: 8
                color: slider.pressed ? Qt.darker(root.color !== "" ? root.color : ThemeManager.primaryColor, 1.2)
                                      : (root.color !== "" ? root.color : ThemeManager.primaryColor)
            }

            onValueChanged: {
                if(animateOpacity.running === false && labelFloatingBody.opacity !== 1.0){
                    animateOpacity.start()
                }
            }
        }

        Qaterial.Label {
            id: label
            visible: false
            text: slider.value.toFixed(0)
            Layout.alignment: Qt.AlignVCenter
            color: root.textColor
        }
    }
}
