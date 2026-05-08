import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtCharts 2.15
import Qaterial 1.0 as Qaterial
import App.Theme 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    // 0=Moving Average 1=EMA 2=Median 3=Low-pass
    property int    filterMode: 0
    property int    windowSize: 5
    property real   alpha:      0.1    // EMA / low-pass
    property real   rawValue:   0.0
    property real   filtValue:  0.0
    property int    sampleN:    0

    readonly property var modeNames:  ["MA", "EMA", "Median", "LP"]
    readonly property var modeColors: ["#3498db","#2ecc71","#f39c12","#9b59b6"]
    readonly property var modeTips:   ["Moving Average","Exponential MA","Median Filter","Low-Pass RC"]

    // Internal buffer for moving average / median
    property var buffer: []

    function processValue(v) {
        rawValue = v
        var out = v

        if (filterMode === 0) {
            // Moving Average
            buffer.push(v)
            if (buffer.length > windowSize) buffer.splice(0, buffer.length - windowSize)
            var sum = 0
            for (var i = 0; i < buffer.length; i++) sum += buffer[i]
            out = sum / buffer.length

        } else if (filterMode === 1) {
            // EMA
            out = filtValue + alpha * (v - filtValue)

        } else if (filterMode === 2) {
            // Median
            buffer.push(v)
            if (buffer.length > windowSize) buffer.splice(0, buffer.length - windowSize)
            var sorted = buffer.slice().sort(function(a, b) { return a - b })
            var mid = Math.floor(sorted.length / 2)
            out = sorted.length % 2 === 0 ? (sorted[mid - 1] + sorted[mid]) / 2 : sorted[mid]

        } else if (filterMode === 3) {
            // Low-pass (discrete RC)
            out = filtValue + alpha * (v - filtValue)
        }

        filtValue = out
        sampleN++
        if (behaviourObject) behaviourObject.emitFiltered(out)

        // Preview chart
        if (rawSeries.count >= 200)    rawSeries.remove(0)
        if (filtSeries.count >= 200)   filtSeries.remove(0)
        rawSeries.append(sampleN,  rawValue)
        filtSeries.append(sampleN, filtValue)

        var allMin = Math.min(rawValue, filtValue)
        var allMax = Math.max(rawValue, filtValue)
        var pad    = Math.max(Math.abs(allMax - allMin) * 0.15, 0.1)
        axisY.min  = allMin - pad
        axisY.max  = allMax + pad
    }

    Connections {
        target: behaviourObject
        function onInternalSetInput(v) { processValue(v) }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // ── Mode selector ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 30; radius: 4
            color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.04)
            clip: true
            Row {
                anchors.fill: parent; spacing: 0
                Repeater {
                    model: root.modeNames
                    delegate: Rectangle {
                        width: parent.width / root.modeNames.length; height: 30; radius: 4
                        color: root.filterMode === index ? root.modeColors[index] : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            anchors.centerIn: parent; text: modelData; font.pixelSize: 9; font.bold: true
                            color: root.filterMode === index ? ThemeManager.backgroundColor : ThemeManager.textColor
                            opacity: root.filterMode === index ? 1.0 : 0.5
                        }
                        AppToolTip { text: root.modeTips[index]; visible: ma_.containsMouse; delay: 600 }
                        MouseArea { id: ma_; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { root.filterMode = index; root.buffer = [] } }
                    }
                }
            }
        }

        // ── Value display ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 52; radius: 6
            color: Qt.rgba(root.modeColors[root.filterMode].toString(), 0.08)
            border.width: 1
            border.color: Qt.rgba(root.modeColors[root.filterMode].toString(), 0.25)
            Behavior on color        { ColorAnimation { duration: 200 } }
            Behavior on border.color { ColorAnimation { duration: 200 } }

            RowLayout {
                anchors.centerIn: parent; spacing: 16

                Column {
                    spacing: 1
                    Text { text: "Raw";      font.pixelSize: 8; color: ThemeManager.textSecondaryColor; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: root.rawValue.toFixed(4);  font.pixelSize: 14; font.family: "Consolas";
                           color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.6); anchors.horizontalCenter: parent.horizontalCenter }
                }

                Text { text: "→"; font.pixelSize: 14; color: root.modeColors[root.filterMode]; opacity: 0.7 }

                Column {
                    spacing: 1
                    Text { text: "Filtered"; font.pixelSize: 8; color: ThemeManager.textSecondaryColor; anchors.horizontalCenter: parent.horizontalCenter }
                    Text { text: root.filtValue.toFixed(6); font.pixelSize: 18; font.family: "Consolas"; font.bold: true;
                           color: root.modeColors[root.filterMode]; anchors.horizontalCenter: parent.horizontalCenter }
                }
            }
        }

        // ── Preview chart ──────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true; Layout.preferredHeight: 90

            ChartView {
                anchors.fill: parent
                antialiasing: true
                backgroundColor: ThemeManager.backgroundColor
                legend.visible: false
                margins.left: 0; margins.right: 0; margins.top: 0; margins.bottom: 0
                plotAreaColor: "transparent"
                animationOptions: ChartView.NoAnimation

                ValueAxis { id: axisX2; visible: false; min: 0; max: 200 }
                ValueAxis { id: axisY; visible: true; tickCount: 3; labelFormat: "%.2f"
                    labelsColor: ThemeManager.textSecondaryColor; labelsFont.pixelSize: 8
                    color: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.5)
                    gridLineColor: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.2)
                }

                LineSeries { id: rawSeries;  axisX: axisX2; axisY: axisY; color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.3); width: 1 }
                LineSeries { id: filtSeries; axisX: axisX2; axisY: axisY; color: root.modeColors[root.filterMode]; width: 2; Behavior on color { ColorAnimation { duration: 200 } } }
            }

            // Legend overlay
            Column {
                anchors { right: parent.right; top: parent.top; margins: 8 } spacing: 3
                Row { spacing: 4
                    Rectangle { width: 12; height: 2; anchors.verticalCenter: parent.verticalCenter; color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.4) }
                    Text { text: "raw"; font.pixelSize: 8; color: ThemeManager.textSecondaryColor }
                }
                Row { spacing: 4
                    Rectangle { width: 12; height: 2; anchors.verticalCenter: parent.verticalCenter; color: root.modeColors[root.filterMode] }
                    Text { text: "filtered"; font.pixelSize: 8; color: ThemeManager.textSecondaryColor }
                }
            }
        }

        // ── Parameters ─────────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true; spacing: 3
            visible: root.filterMode === 0 || root.filterMode === 2

            RowLayout {
                Layout.fillWidth: true; spacing: 6
                Text { text: "Window"; font.pixelSize: 9; color: ThemeManager.textSecondaryColor; Layout.alignment: Qt.AlignVCenter }
                NumberSpinBox {
                    Layout.fillWidth: true; from: 2; to: 200; stepSize: 1
                    value: root.windowSize; accentColor: root.modeColors[root.filterMode]
                    onValueChanged: { root.windowSize = value; root.buffer = [] }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true; spacing: 3
            visible: root.filterMode === 1 || root.filterMode === 3

            NumericInputField {
                Layout.fillWidth: true; implicitHeight: 34
                label: "α"; value: root.alpha; from: 0.001; to: 1.0; stepSize: 0.01; decimals: 3
                showBar: true; accentColor: root.modeColors[root.filterMode]
                onValueModified: root.alpha = newValue
            }
            Text {
                text: root.filterMode === 1 ? "0=no change  1=no filter" : "0=no change  1=no filter (RC≈" + (1.0/(2*Math.PI*root.alpha)).toFixed(1) + ")"
                font.pixelSize: 8; color: ThemeManager.textSecondaryColor; opacity: 0.7
            }
        }

        // ── Manual input ───────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 4
            NumericInputField {
                Layout.fillWidth: true; implicitHeight: 34
                label: "In"; value: root.rawValue
                from: -1e9; to: 1e9; stepSize: 1; decimals: 4
                accentColor: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.5)
                onValueModified: processValue(newValue)
            }
            NewButton {
                Layout.preferredWidth: 56; Layout.preferredHeight: 34
                variant: "outlined"; text: "Reset"
                backgroundColor: ThemeManager.textSecondaryColor
                onClicked: { root.buffer = []; root.filtValue = root.rawValue; root.sampleN = 0 }
            }
        }
    }
}
