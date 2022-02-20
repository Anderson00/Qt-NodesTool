import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.12

import Qaterial 1.0 as Qaterial

Item {
    id: root    
    //property alias orientation: slider.orientation;
    property alias value: slider.value
    property alias from: slider.from
    property alias to: slider.to

    width: 200
    height: layout.height

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

        x: slider.x + slider.leftPadding + ((slider.width - (labelFloating.width * 1.4)) * slider.visualPosition)

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
        width: parent.width
        height: slider.height
        spacing: 0

        Slider {
            id: slider
            from: 5
            to: 100
            Layout.fillWidth: true

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

        Qaterial.Label {
            id: label
            visible: false
            text: slider.value.toFixed(0)
            Layout.alignment: Qt.AlignVCenter
            color: Qaterial.Style.colorTheme.secondaryText
        }
    }
}
