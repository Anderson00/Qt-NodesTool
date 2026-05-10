import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import Qt.labs.platform 1.1 as Platform

import App.Theme 1.0
import App.Widgets 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent

    property var behaviourObject

    // ── Series stats (maintained alongside FastLineChart for the stats bar) ─
    property var seriesStats:   []
    property int statsRevision: 0

    // ── UI state ─────────────────────────────────────────────────────────────
    property bool showGrid:       true
    property bool isAutoScale:    true
    property bool showFill:       false
    property bool showMovingAvg:  false
    property bool antialiasOn:    true
    property bool oscMode:        false     // oscilloscope window
    property bool crosshairMode:  true      // hover = crosshair
    property int  interactMode:   0         // 0=pan, 1=rubberband

    // ════════════════════════════════════════════════════════════════════════
    // Stats helpers
    // ════════════════════════════════════════════════════════════════════════

    function ensureStats(idx) {
        while (seriesStats.length <= idx)
            seriesStats.push({ min: Infinity, max: -Infinity, sum: 0, count: 0, last: 0 })
    }

    function recordStat(idx, y) {
        ensureStats(idx)
        var st = seriesStats[idx]
        if (y < st.min) st.min = y
        if (y > st.max) st.max = y
        st.sum += y; st.count++; st.last = y
        seriesStats[idx] = st
        statsRevision++
    }

    function resetStats(idx) {
        ensureStats(idx)
        seriesStats[idx] = { min: Infinity, max: -Infinity, sum: 0, count: 0, last: 0 }
        statsRevision++
    }

    function resetAllStats() {
        for (var i = 0; i < seriesStats.length; ++i)
            seriesStats[i] = { min: Infinity, max: -Infinity, sum: 0, count: 0, last: 0 }
        statsRevision++
    }

    // ── Pan / zoom helpers ────────────────────────────────────────────────────

    function panChart(dx, dy) {
        if (fastChart.width <= 0 || fastChart.height <= 0) return
        var xpp = (fastChart.xMax - fastChart.xMin) / fastChart.width
        var ypp = (fastChart.yMax - fastChart.yMin) / fastChart.height
        fastChart.setXRange(fastChart.xMin - dx * xpp, fastChart.xMax - dx * xpp)
        fastChart.setYRange(fastChart.yMin + dy * ypp, fastChart.yMax + dy * ypp)
        isAutoScale = false
    }

    function zoomChart(factor, centerX, centerY) {
        var cx = (centerX !== undefined)
            ? fastChart.xMin + (centerX / fastChart.width) * (fastChart.xMax - fastChart.xMin)
            : (fastChart.xMin + fastChart.xMax) * 0.5
        var cy = (centerY !== undefined)
            ? fastChart.yMax - (centerY / fastChart.height) * (fastChart.yMax - fastChart.yMin)
            : (fastChart.yMin + fastChart.yMax) * 0.5
        var xHalf = (fastChart.xMax - fastChart.xMin) * 0.5 / factor
        var yHalf = (fastChart.yMax - fastChart.yMin) * 0.5 / factor
        fastChart.setXRange(cx - xHalf, cx + xHalf)
        fastChart.setYRange(cy - yHalf, cy + yHalf)
        isAutoScale = false
    }

    function resetView() {
        isAutoScale = true
        fastChart.autoScale = true
    }

    // ════════════════════════════════════════════════════════════════════════
    // C++ → QML bridge
    // ════════════════════════════════════════════════════════════════════════

    Connections {
        target: behaviourObject

        function onInternalAppendXY(x, y)                  { fastChart.appendPoint(0,x,y);      recordStat(0,y) }
        function onInternalappendYAutoIncrementX(y)         { fastChart.appendPointAutoX(0,y);   recordStat(0,y) }
        function onInternalAppendYAutoIncrementXChannel2(y) { fastChart.appendPointAutoX(1,y);   recordStat(1,y) }
        function onInternalAppendXYToSeries(idx, x, y)     { fastChart.appendPoint(idx,x,y);    recordStat(idx,y) }
        function onInternalAppendYToSeries(idx, y)         { fastChart.appendPointAutoX(idx,y); recordStat(idx,y) }
        function onInternalClearChart()                    { fastChart.clearAll();  resetAllStats() }
        function onInternalClearSeries(idx)                { fastChart.clearSeries(idx); resetStats(idx) }
        function onInternalSetXRange(mn, mx)               { isAutoScale=false; fastChart.autoScale=false; fastChart.setXRange(mn,mx) }
        function onInternalSetYRange(mn, mx)               { isAutoScale=false; fastChart.autoScale=false; fastChart.setYRange(mn,mx) }
        function onInternalResetZoom()                     { resetView() }
        function onAutoScaleChanged()                      { isAutoScale=behaviourObject.autoScale; fastChart.autoScale=isAutoScale }
        function onMaxPointsChanged()                      { fastChart.maxPoints=behaviourObject.maxPoints }
    }

    Component.onCompleted: {
        fastChart.addSeries("Channel 1", "#e74c3c")
        fastChart.addSeries("Channel 2", "#f39c12")
        if (behaviourObject) fastChart.maxPoints = behaviourObject.maxPoints
    }

    // ════════════════════════════════════════════════════════════════════════
    // Layout
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
                    font { pixelSize: 11; bold: true }
                    Layout.rightMargin: 4; Layout.alignment: Qt.AlignVCenter
                }

                ToolSep {}

                // Grid
                TBBtn { tipText: "Toggle Grid"; label: "⊞"; isActive: showGrid
                    onBtnClicked: { showGrid=!showGrid; fastChart.gridCountX=showGrid?5:0; fastChart.gridCountY=showGrid?5:0 } }

                // Fill under curve
                TBBtn { tipText: "Fill Area"; label: "▨"; isActive: showFill
                    onBtnClicked: {
                        showFill=!showFill
                        for (var i=0;i<fastChart.seriesCount;i++) fastChart.setSeriesFillOpacity(i, showFill?0.35:0)
                    } }

                // Moving average
                TBBtn { tipText: "Moving Average (20 pts)"; label: "~"; isActive: showMovingAvg
                    onBtnClicked: {
                        showMovingAvg=!showMovingAvg
                        for (var i=0;i<fastChart.seriesCount;i++)
                            fastChart.setSeriesMovingAvg(i, showMovingAvg?20:0,
                                Qt.rgba(fastChart.seriesColor(i).r, fastChart.seriesColor(i).g, fastChart.seriesColor(i).b, 0.7))
                    } }

                // Anti-alias
                TBBtn { tipText: "Anti-alias"; label: "◎"; isActive: antialiasOn
                    onBtnClicked: { antialiasOn=!antialiasOn; fastChart.antialias=antialiasOn } }

                // Oscilloscope mode
                TBBtn { tipText: "Oscilloscope (last 200 pts)"; label: "⏱"; isActive: oscMode
                    onBtnClicked: {
                        oscMode=!oscMode
                        fastChart.oscilloscopeWindow = oscMode ? 200 : 0
                        fastChart.autoScale=true; isAutoScale=true
                    } }

                ToolSep {}

                // Interaction mode
                TBBtn { tipText: "Pan mode"; label: "✥"; isActive: interactMode===0
                    onBtnClicked: interactMode=0 }
                TBBtn { tipText: "Rubber-band zoom"; label: "⬚"; isActive: interactMode===1
                    onBtnClicked: interactMode=1 }
                TBBtn { tipText: "Crosshair"; label: "⊕"; isActive: crosshairMode
                    onBtnClicked: crosshairMode=!crosshairMode }

                ToolSep {}

                // Auto-scale
                TBBtn { tipText: "Auto Scale"; label: "⤢"; isActive: isAutoScale
                    onBtnClicked: { isAutoScale=!isAutoScale; fastChart.autoScale=isAutoScale } }

                // Zoom in/out/reset
                TBBtn { tipText: "Zoom In";   label: "+"; onBtnClicked: zoomChart(1.25) }
                TBBtn { tipText: "Zoom Out";  label: "−"; onBtnClicked: zoomChart(0.80) }
                TBBtn { tipText: "Reset View"; label: "⟳"; onBtnClicked: resetView() }

                ToolSep {}

                Item { Layout.fillWidth: true }

                // Point counter
                Text {
                    text: {
                        statsRevision
                        var n=0; for (var i=0;i<fastChart.seriesCount;i++) n+=fastChart.pointCount(i)
                        return n+" pts"
                    }
                    color: ThemeManager.textSecondaryColor; font.pixelSize: 10
                    Layout.alignment: Qt.AlignVCenter; Layout.rightMargin: 2
                }

                ToolSep {}

                // Export
                TBBtn { tipText: "Export PNG"; label: "↓"
                    onBtnClicked: exportDialog.open() }

                // Clear
                TBBtn { tipText: "Clear All"; label: "✕ Clear"; isDanger: true
                    Layout.preferredWidth: 56
                    onBtnClicked: { fastChart.clearAll(); resetAllStats() } }
            }
        }

        // ── CHART AREA ────────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            readonly property int yLabelW: 42
            readonly property int yRLabelW: fastChart.hasRightAxis ? 42 : 6
            readonly property int xLabelH: 16

            // ── FastLineChart (SGG renderer) ──────────────────────────────────
            FastLineChart {
                id: fastChart
                x:      parent.yLabelW
                y:      4
                width:  parent.width  - parent.yLabelW - parent.yRLabelW
                height: parent.height - 4 - parent.xLabelH

                autoScale:   isAutoScale
                antialias:   antialiasOn
                maxPoints:   behaviourObject ? behaviourObject.maxPoints : 500
                gridColor:   Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g,
                                     ThemeManager.borderColor.b, 0.25)
                gridCountX:  showGrid ? 5 : 0
                gridCountY:  showGrid ? 5 : 0
                lineWidth:   2.2

                // Melhoria de suavização e resolução (Super Sampling local)
                layer.enabled: antialiasOn
                layer.smooth:  true
                layer.samples: 8
                layer.textureSize: Qt.size(width * Screen.devicePixelRatio * 1.5, 
                                           height * Screen.devicePixelRatio * 1.5)

                onAutoScaleChanged: isAutoScale = fastChart.autoScale
            }

            // Plot border
            Rectangle {
                x: fastChart.x; y: fastChart.y
                width: fastChart.width; height: fastChart.height
                color: "transparent"
                border.color: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g,
                                      ThemeManager.borderColor.b, 0.4)
                border.width: 1
            }

            // ── Left Y-axis tick labels ───────────────────────────────────────
            Repeater {
                model: fastChart.yTicks
                Text {
                    x: 0
                    y: fastChart.y + fastChart.height*(1.0-modelData.pos) - height/2
                    width: parent.yLabelW - 4; horizontalAlignment: Text.AlignRight
                    text: modelData.label; color: ThemeManager.textSecondaryColor
                    font { pixelSize: 9; family: "Consolas" }
                }
            }

            // ── Right Y-axis tick labels ──────────────────────────────────────
            Repeater {
                model: fastChart.hasRightAxis ? fastChart.yRightTicks : []
                Text {
                    x: fastChart.x + fastChart.width + 4
                    y: fastChart.y + fastChart.height*(1.0-modelData.pos) - height/2
                    text: modelData.label; color: ThemeManager.textSecondaryColor
                    font { pixelSize: 9; family: "Consolas" }
                }
            }

            // ── X-axis tick labels ────────────────────────────────────────────
            Repeater {
                model: fastChart.xTicks
                Text {
                    x: fastChart.x + fastChart.width*modelData.pos - width/2
                    y: fastChart.y + fastChart.height + 2
                    text: modelData.label; color: ThemeManager.textSecondaryColor
                    font { pixelSize: 9; family: "Consolas" }
                }
            }

            // ── Ref line labels ───────────────────────────────────────────────
            Repeater {
                model: fastChart.refLines
                delegate: Text {
                    required property var modelData
                    property double v:   modelData.value
                    property bool   isH: modelData.isH
                    x: isH ? fastChart.x + 4
                           : fastChart.x + fastChart.width*(v-fastChart.xMin)/(fastChart.xMax-fastChart.xMin) + 2
                    y: isH ? fastChart.y + fastChart.height*(1-(v-fastChart.yMin)/(fastChart.yMax-fastChart.yMin)) - height - 2
                           : fastChart.y + 2
                    text: modelData.label; color: modelData.color
                    font { pixelSize: 9; bold: true }
                    visible: text !== ""
                }
            }

            // ── Marker labels ─────────────────────────────────────────────────
            Repeater {
                model: fastChart.markers
                delegate: Item {
                    required property var modelData
                    property real sx: fastChart.x + fastChart.width * (modelData.x - fastChart.xMin)
                                      / (fastChart.xMax - fastChart.xMin)
                    visible: sx >= fastChart.x && sx <= fastChart.x + fastChart.width

                    // Tick at top
                    Rectangle { x: parent.sx - 1; y: fastChart.y; width: 2; height: 6; color: modelData.color }

                    // Label
                    Text {
                        x: parent.sx + 3; y: fastChart.y + 2
                        text: modelData.label; color: modelData.color
                        font { pixelSize: 8; bold: true }
                        visible: text !== ""
                    }
                }
            }

            // ── Interaction & crosshair overlay ───────────────────────────────
            MouseArea {
                id: interactArea
                x: fastChart.x; y: fastChart.y
                width: fastChart.width; height: fastChart.height
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton

                property real pressX: 0;  property real pressY: 0
                property real lastX: 0;   property real lastY: 0
                property bool isDragging: false

                onPressed: function(mouse) {
                    pressX=mouse.x; pressY=mouse.y
                    lastX=mouse.x;  lastY=mouse.y
                    isDragging=false
                }

                onPositionChanged: function(mouse) {
                    var ddx=mouse.x-pressX, ddy=mouse.y-pressY
                    if (pressed && !isDragging && ddx*ddx+ddy*ddy>16) isDragging=true

                    if (pressed && isDragging) {
                        if (interactMode===1) {
                            // Rubber-band
                            selRect.visible=true
                            selRect.x=Math.min(pressX,mouse.x)
                            selRect.y=Math.min(pressY,mouse.y)
                            selRect.width=Math.abs(mouse.x-pressX)
                            selRect.height=Math.abs(mouse.y-pressY)
                        } else {
                            // Pan
                            panChart(mouse.x-lastX, mouse.y-lastY)
                        }
                    }
                    lastX=mouse.x; lastY=mouse.y
                }

                onReleased: function(mouse) {
                    if (selRect.visible) {
                        var x1=fastChart.xMin+(selRect.x/fastChart.width)*(fastChart.xMax-fastChart.xMin)
                        var x2=fastChart.xMin+((selRect.x+selRect.width)/fastChart.width)*(fastChart.xMax-fastChart.xMin)
                        var yf1=1-(selRect.y+selRect.height)/fastChart.height
                        var yf2=1-selRect.y/fastChart.height
                        fastChart.setXRange(x1,x2)
                        fastChart.setYRange(fastChart.yMin+yf1*(fastChart.yMax-fastChart.yMin),
                                            fastChart.yMin+yf2*(fastChart.yMax-fastChart.yMin))
                        isAutoScale=false
                        selRect.visible=false
                    }
                }

                onWheel: function(w){ zoomChart(w.angleDelta.y>0?1.15:0.87, mouseX, mouseY) }

                // Rubber-band selection rect
                Rectangle {
                    id: selRect
                    visible: false
                    color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
                                   ThemeManager.primaryColor.b, 0.12)
                    border.color: ThemeManager.primaryColor; border.width: 1
                }

                // Crosshair
                Item {
                    id: crosshair
                    anchors.fill: parent
                    visible: crosshairMode && interactArea.containsMouse && !selRect.visible

                    // Vertical line
                    Rectangle {
                        x: interactArea.mouseX; y: 0
                        width: 1; height: parent.height
                        color: Qt.rgba(1,1,1,0.35)
                    }
                    // Horizontal line
                    Rectangle {
                        x: 0; y: interactArea.mouseY
                        width: parent.width; height: 1
                        color: Qt.rgba(1,1,1,0.35)
                    }

                    // Nearest point dots (one per visible series)
                    Repeater {
                        model: fastChart.seriesCount
                        delegate: Item {
                            property var pt: fastChart.nearestPoint(index, interactArea.mouseX)
                            property real dotX: fastChart.width>0
                                ? (pt.x-fastChart.xMin)/(fastChart.xMax-fastChart.xMin)*fastChart.width : 0
                            property real dotY: fastChart.height>0
                                ? fastChart.height-(pt.y-fastChart.yMin)/(fastChart.yMax-fastChart.yMin)*fastChart.height : 0
                            visible: fastChart.seriesVisible(index)

                            Rectangle {
                                x: parent.dotX-4; y: parent.dotY-4
                                width: 8; height: 8; radius: 4
                                color: fastChart.seriesColor(index)
                                border.color: "white"; border.width: 1.5
                            }
                        }
                    }

                    // Value tooltip
                    Rectangle {
                        id: valTip
                        x: Math.min(interactArea.mouseX+10, parent.width-width-4)
                        y: Math.max(interactArea.mouseY-height-10, 4)
                        width: tipCol.width+16; height: tipCol.height+10; radius: 4
                        color: Qt.rgba(ThemeManager.surfaceColor.r, ThemeManager.surfaceColor.g,
                                       ThemeManager.surfaceColor.b, 0.95)
                        border.color: ThemeManager.borderColor; border.width: 1

                        Column {
                            id: tipCol
                            anchors.centerIn: parent
                            spacing: 2

                            // X coordinate
                            Text {
                                property double dataX: fastChart.xMin
                                    + interactArea.mouseX/fastChart.width*(fastChart.xMax-fastChart.xMin)
                                text: "x: " + dataX.toFixed(2)
                                color: ThemeManager.textSecondaryColor
                                font { pixelSize: 9; family: "Consolas" }
                            }

                            // One row per series
                            Repeater {
                                model: fastChart.seriesCount
                                delegate: RowLayout {
                                    spacing: 4
                                    visible: fastChart.seriesVisible(index)
                                    property var pt: fastChart.nearestPoint(index, interactArea.mouseX)
                                    Rectangle { width:8;height:8;radius:4; color: fastChart.seriesColor(index); Layout.alignment: Qt.AlignVCenter }
                                    Text {
                                        text: fastChart.seriesName(index)+": "+parent.pt.y.toFixed(3)
                                        color: ThemeManager.textColor; font { pixelSize: 9; family: "Consolas" }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } // chart area

        // ── STATS BAR ─────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: fastChart.seriesCount > 0 ? 26*Math.min(fastChart.seriesCount,4) : 0
            visible: fastChart.seriesCount > 0
            color: Qt.rgba(ThemeManager.surfaceColor.r, ThemeManager.surfaceColor.g,
                           ThemeManager.surfaceColor.b, 0.88)

            Column {
                anchors.fill: parent

                Repeater {
                    model: fastChart.seriesCount

                    delegate: Item {
                        width: parent.width; height: 26

                        RowLayout {
                            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                            spacing: 6

                            // Visibility toggle (click to hide/show)
                            Rectangle {
                                width: 10; height: 10; radius: 2
                                color: fastChart.seriesColor(index)
                                opacity: fastChart.seriesVisible(index) ? 1.0 : 0.25
                                Layout.alignment: Qt.AlignVCenter

                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: fastChart.setSeriesVisible(index, !fastChart.seriesVisible(index))
                                }
                            }

                            // Series name
                            Text {
                                text: fastChart.seriesName(index)
                                color: ThemeManager.textColor
                                opacity: fastChart.seriesVisible(index) ? 1.0 : 0.4
                                font { pixelSize: 10; bold: true }
                                Layout.preferredWidth: 70; elide: Text.ElideRight
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Rectangle { width:1;height:14;color:ThemeManager.borderColor;opacity:0.5 }

                            StatItem { lbl:"last"; val: statsRevision>=0&&index<seriesStats.length?seriesStats[index].last:0 }
                            StatItem {
                                lbl:"min"
                                val: { statsRevision; if(index>=seriesStats.length)return 0; var v=seriesStats[index].min; return v===Infinity?0:v }
                            }
                            StatItem {
                                lbl:"max"
                                val: { statsRevision; if(index>=seriesStats.length)return 0; var v=seriesStats[index].max; return v===-Infinity?0:v }
                            }
                            StatItem {
                                lbl:"avg"
                                val: { statsRevision; if(index>=seriesStats.length)return 0; var st=seriesStats[index]; return st.count>0?st.sum/st.count:0 }
                            }

                            Rectangle { width:1;height:14;color:ThemeManager.borderColor;opacity:0.5 }

                            Text {
                                text: { statsRevision; return fastChart.pointCount(index)+" pts" }
                                color: ThemeManager.textSecondaryColor; font.pixelSize: 10
                                Layout.alignment: Qt.AlignVCenter
                            }

                            // Right-axis indicator
                            Text {
                                visible: fastChart.hasRightAxis
                                text: "R"
                                color: fastChart.seriesColor(index); font { pixelSize: 8; bold: true }
                                opacity: 0.6; Layout.alignment: Qt.AlignVCenter
                            }

                            Item { Layout.fillWidth: true }

                            // Per-series clear
                            Text {
                                text:"✕"; color:ThemeManager.dangerColor; font.pixelSize:12
                                opacity: clrH.containsMouse?1.0:0.4; Layout.alignment:Qt.AlignVCenter
                                AppToolTip { text:"Clear series"; visible: clrH.containsMouse; delay: 600 }
                                MouseArea { id:clrH; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor
                                    onClicked:{ fastChart.clearSeries(index); resetStats(index) } }
                            }
                        }
                    }
                }
            }
        }
    } // ColumnLayout

    // ── File dialog for export ────────────────────────────────────────────────
    Platform.FileDialog {
        id: exportDialog
        title: "Export chart as PNG"
        fileMode: Platform.FileDialog.SaveFile
        nameFilters: ["PNG images (*.png)"]
        defaultSuffix: "png"
        onAccepted: fastChart.grabToFile(currentFile.toString().replace("file:///",""))
    }

    // ════════════════════════════════════════════════════════════════════════
    // Inline components
    // ════════════════════════════════════════════════════════════════════════

    component TBBtn: Rectangle {
        id: tbbtn
        property string tipText: ""; property string label: ""
        property bool isActive: false; property bool isDanger: false
        signal btnClicked()
        Layout.preferredWidth: label.length>2?label.length*7+8:28; Layout.preferredHeight: 26; radius: 4
        color: tbMouse.containsMouse
            ? Qt.rgba(isDanger?ThemeManager.dangerColor.r:ThemeManager.primaryColor.r,
                      isDanger?ThemeManager.dangerColor.g:ThemeManager.primaryColor.g,
                      isDanger?ThemeManager.dangerColor.b:ThemeManager.primaryColor.b, 0.22)
            : isActive ? Qt.rgba(ThemeManager.primaryColor.r,ThemeManager.primaryColor.g,ThemeManager.primaryColor.b,0.14) : "transparent"
        border.color: isActive?ThemeManager.primaryColor:"transparent"; border.width:1
        Text { anchors.centerIn:parent; text:tbbtn.label; font.pixelSize:11
            color: tbbtn.isDanger?ThemeManager.dangerColor:tbbtn.isActive?ThemeManager.primaryColor:ThemeManager.textSecondaryColor }
        AppToolTip { text: tipText; visible: tbMouse.containsMouse && tipText !== ""; delay: 700 }
        MouseArea { id:tbMouse; anchors.fill:parent; hoverEnabled:true; cursorShape:Qt.PointingHandCursor; onClicked:tbbtn.btnClicked() }
    }

    component ToolSep: Rectangle {
        Layout.preferredWidth:1; Layout.preferredHeight:22; Layout.leftMargin:2; Layout.rightMargin:2
        color:ThemeManager.borderColor; opacity:0.5
    }

    component StatItem: RowLayout {
        property string lbl:""; property real val:0
        spacing:2; Layout.preferredWidth:92
        Text { text:lbl+":"; color:ThemeManager.textSecondaryColor; font.pixelSize:9; Layout.alignment:Qt.AlignVCenter }
        Text { text:val.toFixed(3); color:ThemeManager.textColor; font.pixelSize:10; font.family:"Consolas"; Layout.alignment:Qt.AlignVCenter }
    }
}
