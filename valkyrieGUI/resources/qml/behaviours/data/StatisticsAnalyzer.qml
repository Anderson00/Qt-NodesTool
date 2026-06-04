import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import App.Icons 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    // Local copies updated via Connections
    property double lMean:   0.0
    property double lStddev: 0.0
    property double lMin:    0.0
    property double lMax:    0.0
    property double lMedian: 0.0
    property double lP95:    0.0
    property double lP99:    0.0
    property int    lCount:  0

    // Histogram data (30 bins)
    property var histBins: []

    Connections {
        target: behaviourObject
        function onInternalStatsUpdated(mean, stddev, min, max) {
            lMean   = mean
            lStddev = stddev
            lMin    = min
            lMax    = max
            if (behaviourObject) {
                lMedian = behaviourObject.median
                lP95    = behaviourObject.p95
                lP99    = behaviourObject.p99
                lCount  = behaviourObject.count
            }
            histCanvas.requestPaint()
        }
        function onInternalOutlier(value) {
            outlierFlash.visible = true
            outlierLabel.text = "Outlier: " + value.toFixed(4)
            outlierTimer.restart()
        }
    }

    Timer {
        id: outlierTimer
        interval: 2000
        onTriggered: outlierFlash.visible = false
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // ── Title + count ─────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: qsTr("Statistics Analyzer")
                color: ThemeManager.textColor
                font.pixelSize: 11
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: countLabel.width + 12
                height: 20
                radius: 10
                color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
                               ThemeManager.primaryColor.b, 0.18)

                Text {
                    id: countLabel
                    anchors.centerIn: parent
                    text: qsTr("n=") + lCount
                    color: ThemeManager.primaryColor
                    font.pixelSize: 9
                    font.bold: true
                }
            }
        }

        // ── Stats grid ─────────────────────────────────────────────────────
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            rowSpacing: 3
            columnSpacing: 6

            // Row 1
            StatCell { lbl: "mean";   val: lMean   }
            StatCell { lbl: "stddev"; val: lStddev }
            StatCell { lbl: "min";    val: lMin    }
            StatCell { lbl: "max";    val: lMax    }

            // Row 2
            StatCell { lbl: "median"; val: lMedian }
            StatCell { lbl: "p95";    val: lP95    }
            StatCell { lbl: "p99";    val: lP99    }

            // Window size spinbox in the last grid slot
            RowLayout {
                spacing: 3
                Text {
                    text: "win"
                    color: ThemeManager.textSecondaryColor
                    font.pixelSize: 9
                }
                NumberSpinBox {
                    value: behaviourObject ? behaviourObject.windowSize : 100
                    from: 1
                    to: 10000
                    Layout.preferredWidth: 64
                    onValueChanged: {
                        if (behaviourObject && behaviourObject.windowSize !== value)
                            behaviourObject.windowSize = value
                    }
                }
            }
        }

        // ── Outlier flash ──────────────────────────────────────────────────
        Rectangle {
            id: outlierFlash
            Layout.fillWidth: true
            height: 20
            radius: 3
            color: Qt.rgba(ThemeManager.warningColor.r, ThemeManager.warningColor.g,
                           ThemeManager.warningColor.b, 0.18)
            border.color: ThemeManager.warningColor
            border.width: 1
            visible: false

            Text {
                id: outlierLabel
                anchors.centerIn: parent
                text: ""
                color: ThemeManager.warningColor
                font.pixelSize: 9
                font.bold: true
            }
        }

        // ── Mini histogram ─────────────────────────────────────────────────
        Canvas {
            id: histCanvas
            Layout.fillWidth: true
            Layout.fillHeight: true

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                if (!behaviourObject || behaviourObject.count < 2) {
                    ctx.fillStyle = Qt.rgba(ThemeManager.textSecondaryColor.r,
                                            ThemeManager.textSecondaryColor.g,
                                            ThemeManager.textSecondaryColor.b, 0.3)
                    ctx.fillRect(0, 0, width, height)
                    ctx.fillStyle = ThemeManager.textSecondaryColor.toString()
                    ctx.font = "10px sans-serif"
                    ctx.textAlign = "center"
                    ctx.fillText("Push values to see distribution", width / 2, height / 2)
                    return
                }

                // Background
                ctx.fillStyle = Qt.rgba(ThemeManager.surfaceColor.r,
                                        ThemeManager.surfaceColor.g,
                                        ThemeManager.surfaceColor.b, 0.4)
                ctx.fillRect(0, 0, width, height)

                var binCount = 30
                var range = lMax - lMin
                if (range <= 0) range = 1

                // Build bins from behaviourObject properties
                // We'll draw a simple uniform estimate based on stats shape
                var bins = new Array(binCount).fill(0)
                // Use a Gaussian approximation for display
                for (var b = 0; b < binCount; b++) {
                    var binCenter = lMin + (b + 0.5) * range / binCount
                    var z = (binCenter - lMean) / (lStddev > 0 ? lStddev : 1)
                    bins[b] = Math.exp(-0.5 * z * z)
                }

                var maxBin = Math.max.apply(null, bins)
                if (maxBin <= 0) return

                var barW = (width - 2) / binCount
                var primaryR = ThemeManager.primaryColor.r
                var primaryG = ThemeManager.primaryColor.g
                var primaryB = ThemeManager.primaryColor.b

                for (var i = 0; i < binCount; i++) {
                    var barH = (bins[i] / maxBin) * (height - 4)
                    var bx = 1 + i * barW
                    var by = height - barH - 1
                    ctx.fillStyle = Qt.rgba(primaryR, primaryG, primaryB,
                                            0.35 + 0.55 * bins[i] / maxBin)
                    ctx.fillRect(bx, by, Math.max(barW - 1, 1), barH)
                }

                // Mean line
                var meanX = 1 + ((lMean - lMin) / range) * (width - 2)
                ctx.strokeStyle = ThemeManager.successColor.toString()
                ctx.lineWidth = 1.5
                ctx.beginPath()
                ctx.moveTo(meanX, 0)
                ctx.lineTo(meanX, height)
                ctx.stroke()

                // ±2σ lines
                if (lStddev > 0) {
                    var lo2 = 1 + ((lMean - 2 * lStddev - lMin) / range) * (width - 2)
                    var hi2 = 1 + ((lMean + 2 * lStddev - lMin) / range) * (width - 2)
                    ctx.strokeStyle = Qt.rgba(ThemeManager.warningColor.r,
                                              ThemeManager.warningColor.g,
                                              ThemeManager.warningColor.b, 0.7)
                    ctx.lineWidth = 1
                    ctx.setLineDash([3, 3])
                    ctx.beginPath(); ctx.moveTo(lo2, 0); ctx.lineTo(lo2, height); ctx.stroke()
                    ctx.beginPath(); ctx.moveTo(hi2, 0); ctx.lineTo(hi2, height); ctx.stroke()
                    ctx.setLineDash([])
                }
            }
        }
    }

    // ── Inline StatCell component ──────────────────────────────────────────
    component StatCell: ColumnLayout {
        property string lbl: ""
        property double val: 0.0
        spacing: 1

        Text {
            text: lbl
            color: ThemeManager.textSecondaryColor
            font.pixelSize: 8
        }
        Text {
            text: val.toFixed(4)
            color: ThemeManager.textColor
            font.family: "Consolas, monospace"
            font.pixelSize: 10
            font.bold: true
        }
    }
}
