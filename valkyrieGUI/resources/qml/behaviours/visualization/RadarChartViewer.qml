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

    property var  seriesData:  []
    property var  labelsData:  []
    property real maxVal:      1.0
    property bool showGridProp: true
    property real fillOpacityProp: 0.3

    readonly property var seriesColors: [
        "#4e79a7", "#f28e2b", "#e15759", "#76b7b2",
        "#59a14f", "#edc948", "#b07aa1", "#ff9da7"
    ]

    Connections {
        target: behaviourObject
        function onInternalDataChanged() { syncData(); canvas.requestPaint() }
        function onInternalClear()       { syncData(); canvas.requestPaint() }
        function onMaxValueChanged()     { maxVal = behaviourObject ? behaviourObject.maxValue : 1.0; canvas.requestPaint() }
        function onShowGridChanged()     { showGridProp = behaviourObject ? behaviourObject.showGrid : true; canvas.requestPaint() }
        function onFillOpacityChanged()  { fillOpacityProp = behaviourObject ? behaviourObject.fillOpacity : 0.3; canvas.requestPaint() }
    }

    function syncData() {
        if (!behaviourObject) return
        seriesData      = behaviourObject.getSeriesData()
        labelsData      = behaviourObject.getLabels()
        maxVal          = behaviourObject.maxValue
        showGridProp    = behaviourObject.showGrid
        fillOpacityProp = behaviourObject.fillOpacity
    }

    Component.onCompleted: syncData()

    // ── Helper functions ──────────────────────────────────────────────────
    function polygonPoint(cx, cy, r, i, n) {
        var angle = (2 * Math.PI * i / n) - Math.PI / 2
        return { x: cx + r * Math.cos(angle), y: cy + r * Math.sin(angle) }
    }

    function drawGrid(ctx, cx, cy, r, n, steps) {
        ctx.strokeStyle = Qt.rgba(
            ThemeManager.borderColor.r,
            ThemeManager.borderColor.g,
            ThemeManager.borderColor.b, 0.4)
        ctx.lineWidth = 0.8
        for (var s = 1; s <= steps; s++) {
            var rr = r * s / steps
            ctx.beginPath()
            for (var i = 0; i <= n; i++) {
                var p = polygonPoint(cx, cy, rr, i % n, n)
                if (i === 0) ctx.moveTo(p.x, p.y)
                else         ctx.lineTo(p.x, p.y)
            }
            ctx.closePath()
            ctx.stroke()
        }
        // Axis lines
        ctx.strokeStyle = Qt.rgba(
            ThemeManager.borderColor.r,
            ThemeManager.borderColor.g,
            ThemeManager.borderColor.b, 0.6)
        for (var a = 0; a < n; a++) {
            var p2 = polygonPoint(cx, cy, r, a, n)
            ctx.beginPath()
            ctx.moveTo(cx, cy)
            ctx.lineTo(p2.x, p2.y)
            ctx.stroke()
        }
    }

    function drawSeries(ctx, cx, cy, r, vals, maxV, color, alpha) {
        var n = vals.length
        if (n < 2) return
        ctx.beginPath()
        for (var i = 0; i <= n; i++) {
            var idx = i % n
            var ratio = maxV > 0 ? Math.min(1, Math.max(0, vals[idx] / maxV)) : 0
            var p = polygonPoint(cx, cy, r * ratio, idx, n)
            if (i === 0) ctx.moveTo(p.x, p.y)
            else         ctx.lineTo(p.x, p.y)
        }
        ctx.closePath()
        // Fill
        var c = color
        ctx.fillStyle = Qt.rgba(
            parseInt(c.slice(1,3),16)/255,
            parseInt(c.slice(3,5),16)/255,
            parseInt(c.slice(5,7),16)/255,
            alpha)
        ctx.fill()
        // Stroke
        ctx.strokeStyle = color
        ctx.lineWidth = 1.5
        ctx.stroke()
    }

    // ── Layout ────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            height: 30
            color: ThemeManager.surfaceColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Text {
                    text: qsTr("Radar Chart")
                    color: ThemeManager.textColor
                    font.pixelSize: 11
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: seriesData.length + " series"
                    color: ThemeManager.textSecondaryColor
                    font.pixelSize: 10
                    Layout.alignment: Qt.AlignVCenter
                }
                CustomSwitch {
                    checked: showGridProp
                    onCheckedChanged: {
                        if (behaviourObject) behaviourObject.showGrid = checked
                    }
                }
                Text {
                    text: qsTr("Grid")
                    color: ThemeManager.textSecondaryColor
                    font.pixelSize: 9
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        // Canvas
        Canvas {
            id: canvas
            Layout.fillWidth: true
            Layout.fillHeight: true

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var n = labelsData.length
                if (n < 3) {
                    ctx.fillStyle = ThemeManager.textSecondaryColor
                    ctx.font = "11px sans-serif"
                    ctx.textAlign = "center"
                    ctx.fillText("Need ≥ 3 labels", width / 2, height / 2)
                    return
                }

                var margin = 40
                var cx = width / 2
                var cy = (height - 30) / 2 + margin / 2
                var r  = Math.min(cx - margin, cy - margin)

                // Grid
                if (showGridProp) drawGrid(ctx, cx, cy, r, n, 4)

                // Series
                for (var si = 0; si < seriesData.length; si++) {
                    var s = seriesData[si]
                    var col = seriesColors[si % seriesColors.length]
                    drawSeries(ctx, cx, cy, r, s.values, maxVal, col, fillOpacityProp)
                }

                // Labels
                ctx.fillStyle = ThemeManager.textColor
                ctx.font = "9px sans-serif"
                ctx.textAlign = "center"
                for (var li = 0; li < n; li++) {
                    var lp = polygonPoint(cx, cy, r + 14, li, n)
                    ctx.fillText(labelsData[li], lp.x, lp.y + 4)
                }
            }
        }

        // Legend
        Rectangle {
            Layout.fillWidth: true
            height: 30
            color: "transparent"
            visible: seriesData.length > 0

            ListView {
                id: legend
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                orientation: ListView.Horizontal
                spacing: 10
                model: seriesData
                delegate: Row {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        width: 10; height: 10
                        radius: 2
                        color: seriesColors[index % seriesColors.length]
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: modelData.name || ("S" + (index + 1))
                        color: ThemeManager.textSecondaryColor
                        font.pixelSize: 9
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
