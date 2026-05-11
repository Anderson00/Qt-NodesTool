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

    property int   waveMode:  0
    property real  frequency: 1.0
    property real  amplitude: 1.0
    property real  dcOffset:  0.0
    property real  phase:     0.0
    property real  dutyCycle: 50.0

    readonly property var waveNames:  ["Sine", "Square", "Triangle", "Sawtooth", "Noise"]
    readonly property var waveColors: ["#3498db","#e74c3c","#2ecc71","#f39c12","#9b59b6"]

    // single helper — string → color so Qt.rgba can use .r/.g/.b
    property color _wc: waveColors[waveMode]

    property real _t:          0.0
    property real lastValue:   0.0
    property int  sampleCount: 0

    readonly property int chartWindow: 200

    function compute(t) {
        var w    = 2.0 * Math.PI * frequency
        var ph   = phase * Math.PI / 180.0
        var norm = ((w * t + ph) % (2.0 * Math.PI) + 2.0 * Math.PI) % (2.0 * Math.PI)
        var v = 0.0
        switch (waveMode) {
            case 0: v = Math.sin(w * t + ph); break
            case 1: v = (norm < dutyCycle / 100.0 * 2.0 * Math.PI) ? 1.0 : -1.0; break
            case 2: v = 1.0 - 2.0 * Math.abs(norm / Math.PI - 1.0); break
            case 3: v = 1.0 - norm / Math.PI; break
            case 4: v = Math.random() * 2.0 - 1.0; break
        }
        return v * amplitude + dcOffset
    }

    function resetChart() {
        previewSeries.clear()
        root._t = 0.0
        root.sampleCount = 0
        axisX.min = 0
        axisX.max = chartWindow
        var pad = Math.max(amplitude * 0.15, 0.05)
        axisY.min = dcOffset - amplitude - pad
        axisY.max = dcOffset + amplitude + pad
        if (axisY.max <= axisY.min) axisY.max = axisY.min + 0.1
    }

    Timer {
        id: genTimer
        repeat: true
        interval: Math.max(16, Math.round(1000.0 / Math.max(0.01, root.frequency * 20.0)))

        onTriggered: {
            root._t += interval / 1000.0
            var val = compute(root._t)
            root.lastValue   = val
            root.sampleCount++

            if (behaviourObject) behaviourObject.emitValue(val)

            // rolling window: remove oldest, append newest
            if (previewSeries.count >= chartWindow)
                previewSeries.remove(0)
            previewSeries.append(root.sampleCount, val)

            // slide X axis to always show last chartWindow samples
            axisX.min = Math.max(0, root.sampleCount - chartWindow + 1)
            axisX.max = axisX.min + chartWindow

            // Y axis from parameters (no need to scan series)
            var pad = Math.max(amplitude * 0.15, 0.05)
            axisY.min = dcOffset - amplitude - pad
            axisY.max = dcOffset + amplitude + pad
            if (axisY.max <= axisY.min) axisY.max = axisY.min + 0.1
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // ── Waveform selector ──────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 32; radius: 4
            color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.04)
            clip: true

            Row {
                anchors.fill: parent; spacing: 0
                Repeater {
                    model: root.waveNames
                    delegate: Rectangle {
                        width: parent.width / root.waveNames.length; height: 32; radius: 4
                        color: root.waveMode === index ? root.waveColors[index] : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            anchors.centerIn: parent
                            text: modelData; font.pixelSize: 9
                            color: root.waveMode === index
                                   ? ThemeManager.backgroundColor : ThemeManager.textColor
                            opacity: root.waveMode === index ? 1.0 : 0.5
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { root.waveMode = index; resetChart() }
                        }
                    }
                }
            }
        }

        // ── Live value display ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 46; radius: 6
            color: Qt.rgba(root._wc.r, root._wc.g, root._wc.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(root._wc.r, root._wc.g, root._wc.b, 0.30)
            Behavior on color        { ColorAnimation { duration: 200 } }
            Behavior on border.color { ColorAnimation { duration: 200 } }

            RowLayout {
                anchors.centerIn: parent; spacing: 16

                Column {
                    spacing: 1
                    Text {
                        text: "Live"; font.pixelSize: 8
                        color: ThemeManager.textSecondaryColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: root.lastValue.toFixed(4)
                        font.pixelSize: 18; font.family: "Consolas"; font.bold: true
                        color: root.waveColors[root.waveMode]
                        anchors.horizontalCenter: parent.horizontalCenter
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }

                Rectangle { width: 1; height: 30; color: ThemeManager.borderColor; opacity: 0.4 }

                Column {
                    spacing: 1
                    Text {
                        text: "Samples"; font.pixelSize: 8
                        color: ThemeManager.textSecondaryColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: root.sampleCount
                        font.pixelSize: 14; font.family: "Consolas"; font.bold: true
                        color: ThemeManager.textColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }

        // ── Preview chart ──────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 90

            ChartView {
                id: previewChart
                anchors.fill: parent
                antialiasing: true
                backgroundColor: ThemeManager.backgroundColor
                plotAreaColor: "transparent"
                legend.visible: false
                margins.left: 0; margins.right: 0; margins.top: 0; margins.bottom: 0
                animationOptions: ChartView.NoAnimation

                ValueAxis {
                    id: axisX
                    visible: false
                    min: 0; max: chartWindow
                }

                ValueAxis {
                    id: axisY
                    visible: true
                    tickCount: 3
                    labelFormat: "%.2f"
                    labelsColor: ThemeManager.textSecondaryColor
                    labelsFont.pixelSize: 8
                    color: Qt.rgba(ThemeManager.borderColor.r,
                                   ThemeManager.borderColor.g,
                                   ThemeManager.borderColor.b, 0.5)
                    gridLineColor: Qt.rgba(ThemeManager.borderColor.r,
                                           ThemeManager.borderColor.g,
                                           ThemeManager.borderColor.b, 0.18)
                    min: -1.5; max: 1.5
                }

                LineSeries {
                    id: previewSeries
                    axisX: axisX
                    axisY: axisY
                    color: root.waveColors[root.waveMode]
                    width: 1.5
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        // ── Parameters ─────────────────────────────────────────────────────
        NumericInputField {
            Layout.fillWidth: true; implicitHeight: 34
            label: "Hz"; value: root.frequency
            from: 0.001; to: 10000; stepSize: 0.1; decimals: 3
            accentColor: root._wc
            onValueModified: function(newValue) { root.frequency = newValue; resetChart() }
        }

        NumericInputField {
            Layout.fillWidth: true; implicitHeight: 34
            label: "A"; value: root.amplitude
            from: 0; to: 1e6; stepSize: 0.1; decimals: 3
            accentColor: root._wc
            onValueModified: function(newValue) { root.amplitude = newValue }
        }

        NumericInputField {
            Layout.fillWidth: true; implicitHeight: 34
            label: "DC"; value: root.dcOffset
            from: -1e6; to: 1e6; stepSize: 0.1; decimals: 3
            accentColor: ThemeManager.textSecondaryColor
            onValueModified: function(newValue) { root.dcOffset = newValue }
        }

        NumericInputField {
            Layout.fillWidth: true; implicitHeight: 34
            label: "Ï†"; value: root.phase; suffix: "Â°"
            from: 0; to: 360; stepSize: 1; decimals: 1; showBar: true
            accentColor: root._wc
            onValueModified: function(newValue) { root.phase = newValue }
        }

        NumericInputField {
            visible: root.waveMode === 1
            Layout.fillWidth: true; implicitHeight: 34
            label: "D"; value: root.dutyCycle; suffix: "%"
            from: 1; to: 99; stepSize: 1; decimals: 1; showBar: true
            accentColor: root._wc
            onValueModified: function(newValue) { root.dutyCycle = newValue }
        }

        // ── Controls ───────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 4

            NewButton {
                Layout.fillWidth: true; Layout.preferredHeight: 32
                variant: "filled"
                text: genTimer.running ? "■ Stop" : "▶ Generate"
                backgroundColor: genTimer.running
                                 ? ThemeManager.dangerColor
                                 : root.waveColors[root.waveMode]
                onClicked: {
                    if (genTimer.running) {
                        genTimer.stop()
                    } else {
                        resetChart()
                        genTimer.start()
                    }
                }
            }

            NewButton {
                Layout.preferredWidth: 48; Layout.preferredHeight: 32
                variant: "outlined"; text: "Step"
                backgroundColor: root.waveColors[root.waveMode]
                onClicked: {
                    root._t += 1.0 / Math.max(0.01, root.frequency * 20.0)
                    var val = compute(root._t)
                    root.lastValue = val
                    root.sampleCount++
                    if (behaviourObject) behaviourObject.emitValue(val)
                    if (previewSeries.count >= chartWindow) previewSeries.remove(0)
                    previewSeries.append(root.sampleCount, val)
                    axisX.min = Math.max(0, root.sampleCount - chartWindow + 1)
                    axisX.max = axisX.min + chartWindow
                }
            }

            NewButton {
                Layout.preferredWidth: 36; Layout.preferredHeight: 32
                variant: "outlined"; text: "⟳"
                backgroundColor: ThemeManager.textSecondaryColor
                onClicked: resetChart()
            }
        }
    }
}
