import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12

import "../components"

Rectangle {
    property var tt: ""
    property var count: 0
    anchors.fill: parent
    clip: true

    color: '#27191c'

    Connections{
        target: window

        function onWindowMaximizing(val){
            console.log(val);
        }
    }

    CustomSlider {
        id: slider
        value: 50
        z: 100
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.leftMargin: 8

        onValueChanged: {
            mycanvas.wgrid = slider.value
            mycanvas.requestPaint()
        }
    }


    CustomSliderVertical {
        id: slider2
        value: 50
        z: 100
        anchors.top: slider.bottom
        anchors.topMargin: - 16
        anchors.left: parent.left
        state: "left"

        onValueChanged: {

        }
    }

    Canvas {
        id: mycanvas
        width: parent.width * (slider.value / 50)
        height: parent.height * (slider.value / 50)
        property int wgrid: slider.value

        MouseArea {
            anchors.fill: parent

            drag.smoothed: true
            drag.target: mycanvas
            //drag.minimumX: -(mycanvas.width -  parent.width/2)
            //drag.maximumX: mycanvas.width - parent.width
            //drag.minimumY: -(mycanvas.height -  parent.height/2)
            //drag.maximumY: mycanvas.height - parent.height

        }

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0,0, width, height)
            ctx.lineWidth = 0.3
            ctx.strokeStyle = "#114d4d"
            ctx.beginPath()
            var nrows = height / wgrid;
            for(var i=0; i < nrows+1; i++){
                ctx.moveTo(0, wgrid*i);
                ctx.lineTo(width, wgrid*i);
            }

            var ncols = width/wgrid
            for(var j=0; j < ncols+1; j++){
                ctx.moveTo(wgrid*j, 0);
                ctx.lineTo(wgrid*j, height);
            }
            ctx.closePath()
            ctx.stroke()
        }
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

        Rectangle {
            color: "transparent"
            border.width: 1
            border.color: "#ccc"
            radius: 4

            width: viewRect.width / 2
            height: viewRect.height / 2

            x: -(mycanvas.x / (viewRect.width*0.5));
            y: -(mycanvas.y / (viewRect.height*0.5));
        }
    }
}
