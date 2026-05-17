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

    property int    localRows:   behaviourObject ? behaviourObject.rows   : 8
    property int    localCols:   behaviourObject ? behaviourObject.cols   : 8
    property double localMin:    behaviourObject ? behaviourObject.minValue : 0
    property double localMax:    behaviourObject ? behaviourObject.maxValue : 1
    property string localScheme: behaviourObject ? behaviourObject.colorScheme : "heat"
    property var    cellData:    []
    property string tooltipText: ""
    property bool   tooltipVisible: false
    property real   tooltipX: 0
    property real   tooltipY: 0

    Connections {
        target: behaviourObject
        function onInternalSetValue(row, col, val) {
            if (cellData.length === localRows * localCols) {
                var arr = cellData.slice()
                arr[row * localCols + col] = val
                cellData = arr
            }
            canvas.requestPaint()
        }
        function onInternalSetGrid(rows, cols) {
            localRows = rows
            localCols = cols
            cellData = new Array(rows * cols).fill(0)
            canvas.requestPaint()
        }
        function onInternalSetData(data) {
            cellData = data.slice(0, localRows * localCols)
            canvas.requestPaint()
        }
        function onInternalClear() {
            cellData = new Array(localRows * localCols).fill(0)
            canvas.requestPaint()
        }
        function onMinValueChanged() { localMin = behaviourObject.minValue; canvas.requestPaint() }
        function onMaxValueChanged() { localMax = behaviourObject.maxValue; canvas.requestPaint() }
        function onColorSchemeChanged() { localScheme = behaviourObject.colorScheme; canvas.requestPaint() }
    }

    Component.onCompleted: {
        if (behaviourObject) {
            localRows   = behaviourObject.rows
            localCols   = behaviourObject.cols
            localMin    = behaviourObject.minValue
            localMax    = behaviourObject.maxValue
            localScheme = behaviourObject.colorScheme
            cellData    = new Array(localRows * localCols).fill(0)
        }
    }

    function colorForValue(v, mn, mx, scheme) {
        var t = (mx === mn) ? 0.5 : Math.max(0, Math.min(1, (v - mn) / (mx - mn)))
        if (scheme === "heat") {
            // black -> red -> yellow -> white
            if (t < 0.33) {
                var r1 = t / 0.33
                return Qt.rgba(r1, 0, 0, 1)
            } else if (t < 0.66) {
                var r2 = 1.0
                var g2 = (t - 0.33) / 0.33
                return Qt.rgba(r2, g2, 0, 1)
            } else {
                var g3 = 1.0
                var b3 = (t - 0.66) / 0.34
                return Qt.rgba(1, g3, b3, 1)
            }
        } else if (scheme === "cool") {
            // cyan -> magenta
            return Qt.rgba(t, 1.0 - t, 1.0, 1)
        } else if (scheme === "plasma") {
            // dark purple -> orange -> yellow
            var r4 = Math.min(1, 0.05 + t * 1.8)
            var g4 = Math.max(0, Math.min(1, t * 1.5 - 0.2))
            var b4 = Math.max(0, 0.55 - t * 0.8)
            return Qt.rgba(r4, g4, b4, 1)
        } else {
            // viridis: dark purple -> teal -> yellow
            var r5 = Math.max(0, Math.min(1, 0.27 + t * 0.55))
            var g5 = Math.max(0, Math.min(1, t * 0.92))
            var b5 = Math.max(0, Math.min(1, 0.63 - t * 0.55))
            return Qt.rgba(r5, g5, b5, 1)
        }
    }

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
                    text: "Heat Map"
                    color: ThemeManager.textColor
                    font.pixelSize: 11
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: localRows + "×" + localCols
                    color: ThemeManager.textSecondaryColor
                    font.pixelSize: 10
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        // Color scheme selector
        Rectangle {
            Layout.fillWidth: true
            height: 30
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 4

                Repeater {
                    model: ["heat", "cool", "plasma", "viridis"]
                    delegate: Rectangle {
                        height: 20
                        width: 52
                        radius: 10
                        color: localScheme === modelData
                               ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.25)
                               : "transparent"
                        border.color: localScheme === modelData ? ThemeManager.primaryColor : ThemeManager.borderColor
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 9
                            font.capitalization: Font.Capitalize
                            color: localScheme === modelData ? ThemeManager.primaryColor : ThemeManager.textSecondaryColor
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (behaviourObject)
                                    behaviourObject.colorScheme = modelData
                            }
                        }
                    }
                }
            }
        }

        // Canvas + scale bar
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            Layout.bottomMargin: 4

            Canvas {
                id: canvas
                Layout.fillWidth: true
                Layout.fillHeight: true

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    if (localRows <= 0 || localCols <= 0) return

                    var cellW = width  / localCols
                    var cellH = height / localRows

                    for (var r = 0; r < localRows; r++) {
                        for (var c = 0; c < localCols; c++) {
                            var idx = r * localCols + c
                            var val = (idx < cellData.length) ? cellData[idx] : 0
                            var col = colorForValue(val, localMin, localMax, localScheme)
                            ctx.fillStyle = col
                            ctx.fillRect(c * cellW, r * cellH, cellW, cellH)
                        }
                    }

                    // Grid lines
                    ctx.strokeStyle = Qt.rgba(0, 0, 0, 0.15)
                    ctx.lineWidth = 0.5
                    for (var ci = 0; ci <= localCols; ci++) {
                        ctx.beginPath()
                        ctx.moveTo(ci * cellW, 0)
                        ctx.lineTo(ci * cellW, height)
                        ctx.stroke()
                    }
                    for (var ri = 0; ri <= localRows; ri++) {
                        ctx.beginPath()
                        ctx.moveTo(0, ri * cellH)
                        ctx.lineTo(width, ri * cellH)
                        ctx.stroke()
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true

                    onPositionChanged: (mouse) => {
                        if (localCols <= 0 || localRows <= 0) return
                        var cellW = canvas.width  / localCols
                        var cellH = canvas.height / localRows
                        var c = Math.floor(mouse.x / cellW)
                        var r = Math.floor(mouse.y / cellH)
                        if (r >= 0 && r < localRows && c >= 0 && c < localCols) {
                            var idx = r * localCols + c
                            var val = (idx < cellData.length) ? cellData[idx] : 0
                            tooltipText = "(" + r + ", " + c + "): " + val.toFixed(3)
                            tooltipX = mouse.x + 10
                            tooltipY = mouse.y - 20
                            tooltipVisible = true
                        }
                    }
                    onExited: { tooltipVisible = false }

                    onClicked: (mouse) => {
                        if (!behaviourObject) return
                        if (localCols <= 0 || localRows <= 0) return
                        var cellW = canvas.width  / localCols
                        var cellH = canvas.height / localRows
                        var c = Math.floor(mouse.x / cellW)
                        var r = Math.floor(mouse.y / cellH)
                        if (r >= 0 && r < localRows && c >= 0 && c < localCols)
                            behaviourObject.notifyCellClick(r, c)
                    }
                }

                // Tooltip
                Rectangle {
                    visible: tooltipVisible
                    x: Math.min(tooltipX, canvas.width - width - 4)
                    y: Math.max(0, tooltipY)
                    width: tipLabel.implicitWidth + 10
                    height: 20
                    radius: 4
                    color: Qt.rgba(0, 0, 0, 0.75)

                    Text {
                        id: tipLabel
                        anchors.centerIn: parent
                        text: tooltipText
                        color: "white"
                        font.pixelSize: 9
                    }
                }
            }

            // Color scale bar
            Canvas {
                id: scaleBar
                width: 14
                Layout.fillHeight: true
                Layout.bottomMargin: 2

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var steps = height
                    for (var i = 0; i < steps; i++) {
                        var t = 1.0 - i / steps
                        var col = colorForValue(localMin + t * (localMax - localMin), localMin, localMax, localScheme)
                        ctx.fillStyle = col
                        ctx.fillRect(0, i, width - 4, 1)
                    }
                    // border
                    ctx.strokeStyle = Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.5)
                    ctx.lineWidth = 1
                    ctx.strokeRect(0, 0, width - 4, height)
                }

                Connections {
                    target: root
                    function onLocalSchemeChanged() { scaleBar.requestPaint() }
                    function onLocalMinChanged()    { scaleBar.requestPaint() }
                    function onLocalMaxChanged()    { scaleBar.requestPaint() }
                }
            }
        }

        // Min/max labels
        RowLayout {
            Layout.fillWidth: true
            height: 16
            Layout.leftMargin: 6
            Layout.rightMargin: 6

            Text {
                text: "min: " + localMin.toFixed(2)
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 9
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "max: " + localMax.toFixed(2)
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 9
            }
        }
    }
}
