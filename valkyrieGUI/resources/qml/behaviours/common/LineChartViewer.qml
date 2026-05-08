import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import App.Theme 1.0
import App.Widgets 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent

    property var behaviourObject

    // ── Stats state (for stats bar — updated on main thread alongside FastLineChart) ──
    property var seriesStats:   []   // [{min, max, sum, count, last}, …]
    property int seriesCount:   2    // Channel 1 + Channel 2
    property int statsRevision: 0

    // ── UI toggles ───────────────────────────────────────────────────────────
    property bool showGrid:    true
    property bool isAutoScale: true

    // ── Series names ─────────────────────────────────────────────────────────
    readonly property var seriesNames: ["Channel 1", "Channel 2"]

    // ════════════════════════════════════════════════════════════════════════
    // Stats helpers (keep stats bar in sync with FastLineChart data)
    // ════════════════════════════════════════════════════════════════════════

    function initStats() {
        seriesStats = []
        for (var i = 0; i < seriesCount; ++i)
            seriesStats.push({ min: Infinity, max: -Infinity, sum: 0, count: 0, last: 0 })
    }

    function recordStat(idx, y) {
        if (idx < 0 || idx >= seriesStats.length) return
        var st = seriesStats[idx]
        if (y < st.min) st.min = y
        if (y > st.max) st.max = y
        st.sum += y
        st.count++
        st.last = y
        seriesStats[idx] = st
        statsRevision++
    }

    function resetStats(idx) {
        if (idx < 0 || idx >= seriesStats.length) return
        seriesStats[idx] = { min: Infinity, max: -Infinity, sum: 0, count: 0, last: 0 }
        statsRevision++
    }

    function resetAllStats() {
        for (var i = 0; i < seriesStats.length; ++i)
            seriesStats[i] = { min: Infinity, max: -Infinity, sum: 0, count: 0, last: 0 }
        statsRevision++
    }

    // ── Pan / zoom ────────────────────────────────────────────────────────────

    function panChart(dx, dy) {
        if (fastChart.width <= 0 || fastChart.height <= 0) return
        var xpp = (fastChart.xMax - fastChart.xMin) / fastChart.width
        var ypp = (fastChart.yMax - fastChart.yMin) / fastChart.height
        fastChart.setXRange(fastChart.xMin - dx * xpp, fastChart.xMax - dx * xpp)
        fastChart.setYRange(fastChart.yMin + dy * ypp, fastChart.yMax + dy * ypp)
        isAutoScale = false
    }

    function zoomChart(factor) {
        var cx    = (fastChart.xMin + fastChart.xMax) * 0.5
        var cy    = (fastChart.yMin + fastChart.yMax) * 0.5
        var xHalf = (fastChart.xMax - fastChart.xMin) * 0.5 / factor
        var yHalf = (fastChart.yMax - fastChart.yMin) * 0.5 / factor
        fastChart.setXRange(cx - xHalf, cx + xHalf)
        fastChart.setYRange(cy - yHalf, cy + yHalf)
        isAutoScale = false
    }

    function resetZoom() {
        isAutoScale = true
        fastChart.autoScale = true
    }

    // ════════════════════════════════════════════════════════════════════════
    // C++ → QML bridge
    // ════════════════════════════════════════════════════════════════════════

    Connections {
        target: behaviourObject

        function onInternalAppendXY(x, y)                       { fastChart.appendPoint(0, x, y);       recordStat(0, y) }
        function onInternalappendYAutoIncrementX(y)              { fastChart.appendPointAutoX(0, y);     recordStat(0, y) }
        function onInternalAppendYAutoIncrementXChannel2(y)      { fastChart.appendPointAutoX(1, y);     recordStat(1, y) }
        function onInternalAppendXYToSeries(idx, x, y)           { fastChart.appendPoint(idx, x, y);    recordStat(idx, y) }
        function onInternalAppendYToSeries(idx, y)               { fastChart.appendPointAutoX(idx, y);  recordStat(idx, y) }
        function onInternalClearChart()                          { fastChart.clearAll();  resetAllStats() }
        function onInternalClearSeries(idx)                      { fastChart.clearSeries(idx); resetStats(idx) }
        function onInternalSetXRange(mn, mx)                     { isAutoScale = false; fastChart.autoScale = false; fastChart.setXRange(mn, mx) }
        function onInternalSetYRange(mn, mx)                     { isAutoScale = false; fastChart.autoScale = false; fastChart.setYRange(mn, mx) }
        function onInternalResetZoom()                           { resetZoom() }
        function onAutoScaleChanged()                            { isAutoScale = behaviourObject.autoScale; fastChart.autoScale = isAutoScale }
        function onMaxPointsChanged()                            { fastChart.maxPoints = behaviourObject.maxPoints }
    }

    Component.onCompleted: {
        initStats()
        fastChart.setSeriesColor(0, "#e74c3c")
        fastChart.setSeriesColor(1, "#f39c12")
        if (behaviourObject) fastChart.maxPoints = behaviourObject.maxPoints
    }

    // ════════════════════════════════════════════════════════════════════════
    // UI
    // ════════════════════════════════════════════════════════════════════════

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── TOOLBAR ──────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 34
            color: ThemeManager.surfaceColor

            RowLayout {
                anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                spacing: 2

                Text {
                    text: (behaviourObject && behaviourObject.chartTitle !== "")
                          ? behaviourObject.chartTitle : "Line Chart"
                    color: ThemeManager.textColor
                    font.pixelSize: 11
                    font.bold: true
                    Layout.rightMargin: 4
                    Layout.alignment: Qt.AlignVCenter
                }

                ToolSep {}

                TBBtn {
                    tipText: "Toggle Grid"
                    label: "⊞"
                    isActive: showGrid
                    onBtnClicked: {
                        showGrid = !showGrid
                        fastChart.gridCountX = showGrid ? 5 : 0
                        fastChart.gridCountY = showGrid ? 5 : 0
                    }
                }

                TBBtn {
                    tipText: "Auto Scale Axes"
                    label: "⤢"
                    isActive: isAutoScale
                    onBtnClicked: {
                        isAutoScale = !isAutoScale
                        fastChart.autoScale = isAutoScale
                    }
                }

                ToolSep {}

                TBBtn { tipText: "Zoom In";  label: "+"; onBtnClicked: zoomChart(1.25) }
                TBBtn { tipText: "Zoom Out"; label: "−"; onBtnClicked: zoomChart(0.80) }
                TBBtn { tipText: "Reset View"; label: "⟳"; onBtnClicked: resetZoom() }

                ToolSep {}

                Item { Layout.fillWidth: true }

                // Live point counter (calls fastChart.pointCount — re-evaluates via statsRevision)
                Text {
                    text: {
                        statsRevision
                        var n = 0
                        for (var i = 0; i < seriesCount; ++i) n += fastChart.pointCount(i)
                        return n + " pts"
                    }
                    color: ThemeManager.textSecondaryColor
                    font.pixelSize: 10
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: 2
                }

                ToolSep {}

                TBBtn {
                    tipText: "Clear All"
                    label: "✕ Clear"
                    isDanger: true
                    Layout.preferredWidth: 56
                    onBtnClicked: { fastChart.clearAll(); resetAllStats() }
                }
            }
        }

        // ── CHART AREA ────────────────────────────────────────────────────────
        Item {
            Layout.fillWidth:  true
            Layout.fillHeight: true

            // Y-axis label width + X-axis label height define the margins
            readonly property int yLabelW: 40
            readonly property int xLabelH: 16

            // Direct scene graph chart — zero QtCharts layers
            FastLineChart {
                id: fastChart
                x:      parent.yLabelW
                y:      4
                width:  parent.width  - parent.yLabelW - 6
                height: parent.height - 4 - parent.xLabelH

                autoScale:   isAutoScale
                maxPoints:   behaviourObject ? behaviourObject.maxPoints : 500
                gridColor:   Qt.rgba(ThemeManager.borderColor.r,
                                     ThemeManager.borderColor.g,
                                     ThemeManager.borderColor.b, 0.25)
                gridCountX:  showGrid ? 5 : 0
                gridCountY:  showGrid ? 5 : 0
                lineWidth:   2

                onAutoScaleChanged: isAutoScale = fastChart.autoScale
            }

            // Plot-area border
            Rectangle {
                x:      fastChart.x;      y:      fastChart.y
                width:  fastChart.width;  height: fastChart.height
                color:  "transparent"
                border.color: Qt.rgba(ThemeManager.borderColor.r,
                                      ThemeManager.borderColor.g,
                                      ThemeManager.borderColor.b, 0.4)
                border.width: 1
            }

            // Y-axis tick labels
            Repeater {
                model: fastChart.yTicks
                Text {
                    x: 0
                    y: fastChart.y + fastChart.height * (1.0 - modelData.pos) - height / 2
                    width: parent.yLabelW - 4
                    horizontalAlignment: Text.AlignRight
                    text:  modelData.label
                    color: ThemeManager.textSecondaryColor
                    font.pixelSize: 9
                    font.family: "Consolas"
                }
            }

            // X-axis tick labels
            Repeater {
                model: fastChart.xTicks
                Text {
                    x: fastChart.x + fastChart.width * modelData.pos - width / 2
                    y: fastChart.y + fastChart.height + 2
                    text:  modelData.label
                    color: ThemeManager.textSecondaryColor
                    font.pixelSize: 9
                    font.family: "Consolas"
                }
            }

            // Pan & zoom mouse overlay
            MouseArea {
                x: fastChart.x; y: fastChart.y
                width: fastChart.width; height: fastChart.height
                acceptedButtons: Qt.LeftButton

                property real lastX: 0
                property real lastY: 0

                onPressed: function(mouse) {
                    lastX = mouse.x; lastY = mouse.y
                    cursorShape = Qt.ClosedHandCursor
                }
                onReleased: { cursorShape = Qt.ArrowCursor }
                onPositionChanged: function(mouse) {
                    panChart(mouse.x - lastX, mouse.y - lastY)
                    lastX = mouse.x; lastY = mouse.y
                }
                onWheel: function(wheel) {
                    zoomChart(wheel.angleDelta.y > 0 ? 1.15 : 0.87)
                }
            }
        }

        // ── STATS BAR ─────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight:   seriesCount > 0 ? 26 * Math.min(seriesCount, 4) : 0
            visible:          seriesCount > 0
            color: Qt.rgba(ThemeManager.surfaceColor.r,
                           ThemeManager.surfaceColor.g,
                           ThemeManager.surfaceColor.b, 0.88)

            Column {
                anchors.fill: parent

                Repeater {
                    model: seriesCount

                    delegate: Item {
                        width:  parent.width
                        height: 26

                        RowLayout {
                            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                            spacing: 6

                            // Colour swatch
                            Rectangle {
                                width: 10; height: 10; radius: 2
                                color: index === 0 ? "#e74c3c" : "#f39c12"
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Series name
                            Text {
                                text: index < seriesNames.length ? seriesNames[index] : "Ch " + (index + 1)
                                color: ThemeManager.textColor
                                font.pixelSize: 10; font.bold: true
                                Layout.preferredWidth: 70
                                elide: Text.ElideRight
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Rectangle { width: 1; height: 14; color: ThemeManager.borderColor; opacity: 0.5 }

                            StatItem {
                                lbl: "last"
                                val: statsRevision >= 0 && index < seriesStats.length ? seriesStats[index].last : 0
                            }
                            StatItem {
                                lbl: "min"
                                val: {
                                    statsRevision
                                    if (index >= seriesStats.length) return 0
                                    var v = seriesStats[index].min
                                    return (v === Infinity) ? 0 : v
                                }
                            }
                            StatItem {
                                lbl: "max"
                                val: {
                                    statsRevision
                                    if (index >= seriesStats.length) return 0
                                    var v = seriesStats[index].max
                                    return (v === -Infinity) ? 0 : v
                                }
                            }
                            StatItem {
                                lbl: "avg"
                                val: {
                                    statsRevision
                                    if (index >= seriesStats.length) return 0
                                    var st = seriesStats[index]
                                    return st.count > 0 ? st.sum / st.count : 0
                                }
                            }

                            Rectangle { width: 1; height: 14; color: ThemeManager.borderColor; opacity: 0.5 }

                            Text {
                                text: {
                                    statsRevision
                                    return fastChart.pointCount(index) + " pts"
                                }
                                color: ThemeManager.textSecondaryColor
                                font.pixelSize: 10
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                id: clrLbl
                                text: "✕"
                                color: ThemeManager.dangerColor
                                font.pixelSize: 12
                                opacity: clrHover.containsMouse ? 1.0 : 0.45
                                Layout.alignment: Qt.AlignVCenter

                                ToolTip.visible: clrHover.containsMouse
                                ToolTip.text:    "Clear series"
                                ToolTip.delay:   600

                                MouseArea {
                                    id: clrHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { fastChart.clearSeries(index); resetStats(index) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // Inline components
    // ════════════════════════════════════════════════════════════════════════

    component TBBtn: Rectangle {
        id: tbbtn
        property string tipText:  ""
        property string label:    ""
        property bool   isActive: false
        property bool   isDanger: false
        signal btnClicked()

        Layout.preferredWidth:  28
        Layout.preferredHeight: 26
        radius: 4

        color: tbMouse.containsMouse
            ? Qt.rgba(
                isDanger ? ThemeManager.dangerColor.r   : ThemeManager.primaryColor.r,
                isDanger ? ThemeManager.dangerColor.g   : ThemeManager.primaryColor.g,
                isDanger ? ThemeManager.dangerColor.b   : ThemeManager.primaryColor.b,
                0.22)
            : (isActive
                ? Qt.rgba(ThemeManager.primaryColor.r,
                          ThemeManager.primaryColor.g,
                          ThemeManager.primaryColor.b, 0.14)
                : "transparent")

        border.color: isActive ? ThemeManager.primaryColor : "transparent"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: tbbtn.label
            font.pixelSize: 12
            color: tbbtn.isDanger  ? ThemeManager.dangerColor
                 : tbbtn.isActive  ? ThemeManager.primaryColor
                 :                   ThemeManager.textSecondaryColor
        }

        ToolTip.visible: tbMouse.containsMouse && tipText !== ""
        ToolTip.text:    tipText
        ToolTip.delay:   700

        MouseArea {
            id: tbMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor
            onClicked:    tbbtn.btnClicked()
        }
    }

    component ToolSep: Rectangle {
        Layout.preferredWidth:  1
        Layout.preferredHeight: 22
        Layout.leftMargin:  2
        Layout.rightMargin: 2
        color:   ThemeManager.borderColor
        opacity: 0.5
    }

    component StatItem: RowLayout {
        property string lbl: ""
        property real   val: 0
        spacing: 2
        Layout.preferredWidth: 92

        Text {
            text: lbl + ":"
            color: ThemeManager.textSecondaryColor
            font.pixelSize: 9
            Layout.alignment: Qt.AlignVCenter
        }
        Text {
            text:        val.toFixed(3)
            color:       ThemeManager.textColor
            font.pixelSize: 10
            font.family: "Consolas"
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
