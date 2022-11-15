import QtQuick 2.14
import QtQuick.Layouts 1.0
import QtQuick.Controls 2.0
import Qt.labs.qmlmodels 1.0
import QtCharts 2.15

import '../../components'

Item {
    anchors.fill: parent

    property var behaviourObject
    property int autoCount: 0

    Component.onCompleted: {
        debounce.start();

        charTotalUsage.axes[1].labelFormat = "%.2f"
        charTotalUsage.axes[0].labelFormat = "%.2f"
    }

    Timer {
        id: debounce
        repeat: false

        interval: 50

        onTriggered: {

        }
    }

    Connections {
        target: behaviourObject

        function onInternalappendYAutoIncrementX(y){
            lineSerieAutoIncremented.append(autoCount++, y)

            charTotalUsage.axes[0].min = 0
            charTotalUsage.axes[0].max = autoCount
            charTotalUsage.axes[1].max = Math.max(charTotalUsage.axes[1].max, y)
            charTotalUsage.axes[0].tickCount = 5
            charTotalUsage.axes[1].min = 0

            charTotalUsage.update()
        }
    }

    Rectangle{
        id: bo
        anchors.fill: parent
        color: "#140f07"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        ChartView {
            id: charTotalUsage
            Layout.margins: 0
            title: `X`
            Layout.fillWidth: true
            Layout.fillHeight: true
            antialiasing: true
            backgroundColor: "#140f07"
            animationOptions: ChartView.NoAnimation

            LineSeries {
                id: lineSerie
                color: "#EC407A"
                name: "test"
            }

            LineSeries {
                id: lineSerieAutoIncremented
                color: "red"
                name: "auto Increment"
            }
        }

    }
}
