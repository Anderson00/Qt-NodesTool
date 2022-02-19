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

        }
    }

    ColumnLayout {
        anchors.fill: parent

        RowLayout{
            Layout.fillWidth: true
            Layout.fillHeight: true

            Qaterial.Slider
            {
                id: sliderTimeout
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
                    Layout.topMargin: 8
                    value: cpuUsage / 100

                }

                ChartView {
                    id: charTotalUsage
                    title: `Total Usage (${cpuUsage}%)`
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    antialiasing: true
                    backgroundColor: "#140f07"
                    animationOptions: ChartView.SeriesAnimations

                    LineSeries {
                        id: lineSerie
                        name: ((sliderTimeout.value*(1000-100))+100).toFixed(0) + " ms"
                    }
                } // ChartView
            } // ColumnLayout
        } // RowLayout



        RowLayout {
            visible: false
            Repeater{
                id: rowRepeater
                delegate: ChartView {
                    title: "Spline"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    antialiasing: true
                    backgroundColor: "#140f07"

                    // Define x-axis to be used with the series instead of default one
                    ValueAxis {
                        //id: valueAxis
                        min: 2000
                        max: 2011
                        tickCount: 12
                        labelFormat: "%.0f"
                    }

                    AreaSeries {
                        axisX: valueAxis
                        upperSeries: LineSeries {

                        }
                    }
                } // ChartView
            }
        } // RowLayout

    } // ColumnLayout
}
