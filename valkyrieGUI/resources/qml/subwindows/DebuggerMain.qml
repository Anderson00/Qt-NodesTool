import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12

Rectangle {
    property var tt: ""
    property var count: 0
    anchors.fill: parent

    color:'#27191c'

    Connections{
        target: window

        function onWindowMaximizing(val){
            console.log(val);
        }
    }

    Text{
        text: parent.width + "|"+parent.height
    }

    MouseArea{
        anchors.fill: parent

        onClicked: {
            console.log(window);
            console.log(mouse.x + "|"+mouse.y);
            mycanvas2.conexoes.push([mouse.x , mouse.y])

            mycanvas2.requestPaint()

        }
    }

    Slider{
        id: slider
        from: 5
        to: 100

        value: 5

        onValueChanged: {
            mycanvas.wgrid = slider.value
            mycanvas.requestPaint()


        }
    }

    Canvas {
        id: mycanvas2
        width: parent.width
        height: parent.height
        property var conexoes: []

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0,0, parent.width, parent.height)
            ctx.lineWidth = 1
            ctx.strokeStyle = "blue"
            ctx.beginPath()

            for(var i = 0; i < conexoes.length - 1; i++){
                let coordTo = conexoes[i+1];
                let coordFrom = conexoes[i];
                ctx.moveTo(coordFrom[0], coordFrom[1]);
                ctx.lineTo(coordTo[0], coordTo[1]);
            }

            ctx.closePath()
            ctx.stroke()
        }
    }

    Canvas {
        id: mycanvas
        width: parent.width
        height: parent.height
        property int wgrid: slider.value

        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0,0, parent.width, parent.height)
            ctx.lineWidth = 0.3
            ctx.strokeStyle = "#114d4d"
            ctx.beginPath()
            var nrows = height/wgrid;
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
}
