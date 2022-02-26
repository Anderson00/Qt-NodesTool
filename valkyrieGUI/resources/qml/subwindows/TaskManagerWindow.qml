import QtQuick 2.12
import QtQml 2.14
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12
import QtCharts 2.15

import Qaterial 1.0 as Qaterial

Rectangle {
    anchors.fill: parent
    color: "#140f07"

    property int cpuUsage: 0

    Component.onCompleted: {
        charTotalUsage.axes[1].max = 100
        charTotalUsage.axes[0].max = 100
        charTotalUsage.axes[0].tickType = ValueAxis.TicksFixed
        charTotalUsage.axes[1].labelFormat = "%.0f"
        charTotalUsage.axes[0].labelsVisible = false

        timeer.start()
    }

    Timer {
        id: timeer
        interval: (sliderTimeout.value*(1000-100))+100
        repeat: true

        property int count: 0

        onTriggered: {
            //console.log(count + " " + taskManager.totalUsage())

            labelTotalMemoryUsage.text = taskManager.totalSystemMemoryUsage() + " MB"
            progressTotalMemoryUsage.value = Number(taskManager.totalSystemMemoryUsage())
            progressTotalMemoryUsagePercent.text = ((taskManager.totalSystemMemoryUsage() / taskManager.totalSystemMemory())*100).toFixed(0) + " %"

            let total = taskManager.totalUsage();
            cpuUsage = total;
            lineSerie.append(++count, total/1)
            charTotalUsage.axes[0].min = 0
            //charTotalUsage.axes[0].max = count
            charTotalUsage.axes[0].tickCount = 5
            charTotalUsage.axes[1].min = 0
            charTotalUsage.update()
            if(count >= 100){
                //lineSerie.removePoints(0,1);
                charTotalUsage.axes[0].min = count - 100
                charTotalUsage.axes[0].max = count
            }

            grid.model = (function(){
                let obj = taskManager.processMemoryCounters();
                let vectKeys = Object.keys(obj);
                let resultObj = [];
                for(let index in vectKeys){
                    let key = vectKeys[index];
                    resultObj.push({"type": key, "val": obj[key] + ((key !== "PageFaultCount") ? " MB" : "")});
                }
                return resultObj;
            }())

        }
    }

    ColumnLayout {
        anchors.fill: parent

        anchors.margins: 8

        RowLayout{
            Layout.fillWidth: true
            Layout.fillHeight: true

            Qaterial.Slider
            {
                id: sliderTimeout
                value: 0.5
                Binding on value { when: !sliderTimeout.pressed; value: sliderTimeout.value;restoreMode: Binding.RestoreBindingOrValue }
                orientation: Qt.Vertical
                Layout.fillHeight: true
                color: Material.accentColor

            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                ProgressBar {
                    Layout.fillWidth: true
                    value: cpuUsage / 100

                }

                ChartView {
                    id: charTotalUsage
                    title: `Total Usage (${cpuUsage}%)`
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    antialiasing: true
                    backgroundColor: "#140f07"
                    //plotAreaColor: "#EC407A"
                    animationOptions: ChartView.SeriesAnimations

                    LineSeries {
                        id: lineSerie
                        color: "#EC407A"
                        name: ((sliderTimeout.value*(1000-100))+100).toFixed(0) + " ms"
                    }
                } // ChartView
            } // ColumnLayout
        } // RowLayout



        RowLayout {
            Layout.fillWidth: true
            //totalProcessMemoryUsage
            Qaterial.Label {
                id: labelTotalMemoryUsage
                text: taskManager.totalSystemMemoryUsage() + " MB"
            }
            ProgressBar {
                id: progressTotalMemoryUsage
                Layout.fillWidth: true
                from: 0
                to: Number(taskManager.totalSystemMemory())
                value: 0
                Layout.preferredHeight: 20
                height: 20

                background: Rectangle {
                    implicitWidth: 200
                    implicitHeight: progressTotalMemoryUsage.height
                    color: "#880E4F"
                }

                contentItem: Item {
                    implicitWidth: 200
                    implicitHeight: 4

                    Rectangle {
                        width: progressTotalMemoryUsage.visualPosition * parent.width
                        height: progressTotalMemoryUsage.height
                        radius: 2
                        color: "#EC407A"


                    }
                }

                Qaterial.Label {
                    id: progressTotalMemoryUsagePercent
                    anchors.centerIn: progressTotalMemoryUsage
                    z: 100
                    text: (taskManager.totalSystemMemoryUsage() / progressTotalMemoryUsage.value).toFixed(0) + " %"
                }
            }
        } // RowLayout

        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter
            Layout.preferredHeight: 100
            interactive: false

            cellWidth: parent.width / 4
            cellHeight: 50
            clip: true

            //highlight: Rectangle { color: "lightsteelblue"; radius: 5 }

            model: []
            delegate: Column {
                width: grid.cellWidth
                height: grid.cellHeight
                clip: true
                spacing: 8

                Text {
                    text: modelData.type
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#FFF"
                }

                Text {
                    text: modelData.val
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: sliderTimeout.color
                }
            }

        }
    }
}
