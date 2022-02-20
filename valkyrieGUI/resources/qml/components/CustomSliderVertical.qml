import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.12

import Qaterial 1.0 as Qaterial

Item {
    id: root
    property alias value: slider.value
    property alias from: slider.from
    property alias to: slider.to

    width: labelFloating.width + slider.width
    height: layout.height

    state: "left"

    states: [
        State {
            name: "left"
            PropertyChanges {
                target: labelFloatingBody
                rotation: -90;

            }
        },

        State {
            name: "right"
            PropertyChanges {
                target: labelFloatingBody
                rotation: 90;
                anchors.left: layout.right
                anchors.leftMargin: -(slider.rightPadding + 8)

            }
        }
    ]


    Rectangle {
        id: labelFloatingBody
        color: "transparent"
        width: labelFloating.width
        height: labelFloating.height

        opacity: 0.0

        Qaterial.Label {
            id: labelFloating
            text: slider.value.toFixed(0)
            color: slider.color
        }

        y: ((slider.y) + slider.leftPadding + ((slider.height - (labelFloating.height*1.8 )) * slider.visualPosition))

        Behavior on y {
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

        NumberAnimation {
            id: animateOpacity2
            target: labelFloatingBody
            properties: "opacity"
            from: 1.0
            to: 0.0
            duration: 200

        }
    }

    RowLayout{
        id: layout
        width: slider.width
        height: slider.height
        spacing: 0

        Slider {
            id: slider
            from: 5
            to: 100

            Layout.fillWidth: true
            orientation: Qt.Vertical

            value: 5

            onFocusChanged: {
                if(slider.focus === false){
                    animateOpacity2.start()
                }
            }

            onValueChanged: {
                if(animateOpacity.running === false && labelFloatingBody.opacity !== 1.0){
                    animateOpacity.start()
                }
            }
        }
    }
}
