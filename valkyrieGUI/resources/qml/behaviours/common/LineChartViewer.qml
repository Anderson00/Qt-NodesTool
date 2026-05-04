import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtCharts 2.15

import App.Theme 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent

    property var behaviourObject

    // ── Series state ─────────────────────────────────────────────────────────
    // JS arrays; use seriesCount / statsRevision as binding triggers
    property var seriesRefs:    []
    property var seriesStats:   []   // [{min, max, sum, count, last}, …]
    property int seriesCount:   0    // length mirror — drives Repeater
    property int statsRevision: 0    // incremented on each data point

    // ── UI toggles ───────────────────────────────────────────────────────────
    property bool showLegend:  false
    property bool showGrid:    true
    property bool showPoints:  false
    property bool animEnabled: false
    property bool isAutoScale: true

    // ── Colour palette for auto-assigned series colours ───────────────────────
    readonly property var palette: [
        "#e74c3c", "#f39c12", "#2ecc71", "#3498db",
        "#9b59b6", "#1abc9c", "#e67e22", "#ec407a"
    ]

    // ════════════════════════════════════════════════════════════════════════
    // JS helpers
    // ════════════════════════════════════════════════════════════════════════

    function initDefaultSeries() {
        addSeriesInternal("Channel 1", palette[0])
        addSeriesInternal("Channel 2", palette[1])
    }

    function addSeriesInternal(name, color) {
        var s = chart.createSeries(ChartView.SeriesTypeLine, name, axisX, axisY)
        s.color         = color
        s.width         = 2
        s.pointsVisible = showPoints
        seriesRefs.push(s)
        seriesStats.push({ min: Infinity, max: -Infinity, sum: 0, count: 0, last: 0 })
        seriesCount = seriesRefs.length
    }

    function appendToSeries(idx, x, y) {
        if (idx < 0 || idx >= seriesRefs.length) return
        var s      = seriesRefs[idx]
        var maxPts = behaviourObject ? behaviourObject.maxPoints : 500
        while (s.count >= maxPts && s.count > 0)
            s.remove(0)

        s.append(x, y)

        var st = seriesStats[idx]
        if (y < st.min) st.min = y
        if (y > st.max) st.max = y
        st.sum += y
        st.count++
        st.last = y
        seriesStats[idx] = st
        statsRevision++

        if (isAutoScale) autoScaleAxes()
    }

    function appendYAuto(idx, y) {
        if (idx < 0 || idx >= seriesRefs.length) return
        var s     = seriesRefs[idx]
        var nextX = (s.count > 0) ? s.at(s.count - 1).x + 1 : 0
        appendToSeries(idx, nextX, y)
    }

    function autoScaleAxes() {
        var yMin = Infinity, yMax = -Infinity
        var xMin = Infinity, xMax = -Infinity
        for (var i = 0; i < seriesRefs.length; i++) {
            var s = seriesRefs[i]
            if (s.count === 0) continue
            var st = seriesStats[i]
            if (st.min < yMin) yMin = st.min
            if (st.max > yMax) yMax = st.max
            var f = s.at(0);           if (f.x < xMin) xMin = f.x
            var l = s.at(s.count - 1); if (l.x > xMax) xMax = l.x
        }
        if (yMin !== Infinity) {
            var yPad   = Math.max(Math.abs(yMax - yMin) * 0.12, 0.5)
            axisY.min  = yMin - yPad
            axisY.max  = yMax + yPad
        }
        if (xMin !== Infinity) {
            var xPad   = Math.max(Math.abs(xMax - xMin) * 0.05, 1)
            axisX.min  = xMin
            axisX.max  = xMax + xPad
        }
    }

    function clearAll() {
        for (var i = 0; i < seriesRefs.length; i++) {
            seriesRefs[i].clear()
            seriesStats[i] = { min: Infinity, max: -Infinity, sum: 0, count: 0, last: 0 }
        }
        statsRevision++
        axisX.min = 0;  axisX.max = 10
        axisY.min = -1; axisY.max = 1
    }

    function clearOneSeries(idx) {
        if (idx < 0 || idx >= seriesRefs.length) return
        seriesRefs[idx].clear()
        seriesStats[idx] = { min: Infinity, max: -Infinity, sum: 0, count: 0, last: 0 }
        statsRevision++
    }

    // ════════════════════════════════════════════════════════════════════════
    // C++ → QML bridge
    // ════════════════════════════════════════════════════════════════════════

    Connections {
        target: behaviourObject

        function onInternalAppendXY(x, y)                    { appendToSeries(0, x, y) }
        function onInternalappendYAutoIncrementX(y)                    { appendYAuto(0, y) }
        function onInternalAppendYAutoIncrementXChannel2(y)              { appendYAuto(1, y) }
        function onInternalAppendXYToSeries(idx, x, y)        { appendToSeries(idx, x, y) }
        function onInternalAppendYToSeries(idx, y)            { appendYAuto(idx, y) }
        function onInternalClearChart()                       { clearAll() }
        function onInternalClearSeries(idx)                   { clearOneSeries(idx) }
        function onInternalSetXRange(mn, mx)  { isAutoScale = false; axisX.min = mn; axisX.max = mx }
        function onInternalSetYRange(mn, mx)  { isAutoScale = false; axisY.min = mn; axisY.max = mx }
        function onInternalResetZoom()        { chart.zoomReset(); if (isAutoScale) autoScaleAxes() }
        function onAutoScaleChanged()         { isAutoScale = behaviourObject.autoScale }
        function onChartTitleChanged()        { chart.title = behaviourObject.chartTitle || "" }
    }

    Component.onCompleted: {
        chart.legend.visible   = showLegend
        chart.legend.alignment = Qt.AlignBottom
        initDefaultSeries()
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

                // Chart label
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

                // Toggle: legend
                TBBtn {
                    tipText: "Toggle Legend"
                    label: "☰"
                    isActive: showLegend
                    onBtnClicked: { showLegend = !showLegend; chart.legend.visible = showLegend }
                }

                // Toggle: grid
                TBBtn {
                    tipText: "Toggle Grid"
                    label: "⊞"
                    isActive: showGrid
                    onBtnClicked: {
                        showGrid = !showGrid
                        axisX.gridVisible = showGrid
                        axisY.gridVisible = showGrid
                    }
                }

                // Toggle: data points
                TBBtn {
                    tipText: "Show Data Points"
                    label: "◉"
                    isActive: showPoints
                    onBtnClicked: {
                        showPoints = !showPoints
                        for (var i = 0; i < seriesRefs.length; i++)
                            seriesRefs[i].pointsVisible = showPoints
                    }
                }

                // Toggle: animation
                TBBtn {
                    tipText: "Toggle Animation"
                    label: "⚡"
                    isActive: animEnabled
                    onBtnClicked: {
                        animEnabled = !animEnabled
                        chart.animationOptions = animEnabled
                            ? ChartView.SeriesAnimations : ChartView.NoAnimation
                    }
                }

                // Toggle: auto-scale
                TBBtn {
                    tipText: "Auto Scale Axes"
                    label: "⤢"
                    isActive: isAutoScale
                    onBtnClicked: { isAutoScale = !isAutoScale; if (isAutoScale) autoScaleAxes() }
                }

                ToolSep {}

                // Zoom in / out / reset
                TBBtn { tipText: "Zoom In";    label: "+"; onBtnClicked: chart.zoom(1.25) }
                TBBtn { tipText: "Zoom Out";   label: "−"; onBtnClicked: chart.zoom(0.80) }
                TBBtn {
                    tipText: "Reset View"; label: "⟳"
                    onBtnClicked: { chart.zoomReset(); if (isAutoScale) autoScaleAxes() }
                }

                ToolSep {}

                Item { Layout.fillWidth: true }

                // Live point counter
                Text {
                    text: {
                        statsRevision
                        var n = 0
                        for (var i = 0; i < seriesRefs.length; i++) n += seriesRefs[i].count
                        return n + " pts"
                    }
                    color: ThemeManager.textSecondaryColor
                    font.pixelSize: 10
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: 2
                }

                ToolSep {}

                // Clear all
                TBBtn {
                    tipText: "Clear All"
                    label: "✕ Clear"
                    isDanger: true
                    Layout.preferredWidth: 56
                    onBtnClicked: clearAll()
                }
            }
        }

        // ── CHART ─────────────────────────────────────────────────────────────
        Item {
            Layout.fillWidth:  true
            Layout.fillHeight: true

            ChartView {
                id: chart
                anchors.fill:     parent
                antialiasing:     true
                backgroundColor:  ThemeManager.backgroundColor
                plotAreaColor:    "transparent"
                animationOptions: ChartView.NoAnimation
                legend.visible:   false
                legend.alignment: Qt.AlignBottom
                margins.left:     0
                margins.right:    6
                margins.top:      6
                margins.bottom:   0

                ValueAxis {
                    id: axisX
                    min: 0;  max: 10
                    tickCount: 6
                    labelFormat: "%.2f"
                    labelsColor: ThemeManager.textSecondaryColor
                    labelsFont.pixelSize: 10
                    color: Qt.rgba(ThemeManager.borderColor.r,
                                   ThemeManager.borderColor.g,
                                   ThemeManager.borderColor.b, 0.7)
                    gridLineColor: Qt.rgba(ThemeManager.borderColor.r,
                                           ThemeManager.borderColor.g,
                                           ThemeManager.borderColor.b, 0.3)
                    minorGridVisible: false
                }

                ValueAxis {
                    id: axisY
                    min: -1; max: 1
                    tickCount: 6
                    labelFormat: "%.2f"
                    labelsColor: ThemeManager.textSecondaryColor
                    labelsFont.pixelSize: 10
                    color: Qt.rgba(ThemeManager.borderColor.r,
                                   ThemeManager.borderColor.g,
                                   ThemeManager.borderColor.b, 0.7)
                    gridLineColor: Qt.rgba(ThemeManager.borderColor.r,
                                           ThemeManager.borderColor.g,
                                           ThemeManager.borderColor.b, 0.3)
                    minorGridVisible: false
                }
            }

            // Pan & zoom mouse overlay (sits on top of ChartView)
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton

                property real lastX: 0
                property real lastY: 0

                onPressed: function(mouse) {
                    lastX = mouse.x
                    lastY = mouse.y
                    cursorShape = Qt.ClosedHandCursor
                }
                onReleased:  { cursorShape = Qt.ArrowCursor }

                onPositionChanged: function(mouse) {
                    var dx = mouse.x - lastX
                    var dy = mouse.y - lastY
                    chart.scrollLeft(dx)
                    chart.scrollUp(dy)
                    lastX = mouse.x
                    lastY = mouse.y
                    if (isAutoScale) isAutoScale = false
                }

                onWheel: function(wheel) {
                    chart.zoom(wheel.angleDelta.y > 0 ? 1.15 : 0.87)
                    if (isAutoScale) isAutoScale = false
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

                            // Series colour swatch
                            Rectangle {
                                width: 10; height: 10; radius: 2
                                color: index < seriesRefs.length
                                       ? seriesRefs[index].color : "transparent"
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Series name
                            Text {
                                text: index < seriesRefs.length ? seriesRefs[index].name : ""
                                color: ThemeManager.textColor
                                font.pixelSize: 10
                                font.bold: true
                                Layout.preferredWidth: 70
                                elide: Text.ElideRight
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Rectangle { width: 1; height: 14; color: ThemeManager.borderColor; opacity: 0.5 }

                            StatItem {
                                lbl: "last"
                                val: statsRevision >= 0 && index < seriesStats.length
                                     ? seriesStats[index].last : 0
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
                                    return (index < seriesRefs.length
                                            ? seriesRefs[index].count : 0) + " pts"
                                }
                                color: ThemeManager.textSecondaryColor
                                font.pixelSize: 10
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Item { Layout.fillWidth: true }

                            // Per-series clear button
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
                                    onClicked: clearOneSeries(index)
                                }
                            }
                        }
                    }
                }
            }
        }
    } // ColumnLayout

    // ════════════════════════════════════════════════════════════════════════
    // Inline components
    // ════════════════════════════════════════════════════════════════════════

    // Toolbar button
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
            text:  tbbtn.label
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

    // Toolbar separator
    component ToolSep: Rectangle {
        Layout.preferredWidth:  1
        Layout.preferredHeight: 22
        Layout.leftMargin:  2
        Layout.rightMargin: 2
        color:   ThemeManager.borderColor
        opacity: 0.5
    }

    // Stat label + value pair
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

