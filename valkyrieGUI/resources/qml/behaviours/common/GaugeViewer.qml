import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import Qaterial 1.0 as Qaterial
import App.Theme 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    property real gaugeValue: 0.0
    property real gaugeMin:   0.0
    property real gaugeMax:   100.0
    property real warnThresh: 70.0
    property real critThresh: 90.0
    property string unitLabel: ""
    property int    decimals:  1

    property color colorLow:  "#2ecc71"
    property color colorWarn: "#f39c12"
    property color colorCrit: "#e74c3c"

    property real normalized: Math.max(0, Math.min(1, (gaugeValue - gaugeMin) / Math.max(0.001, gaugeMax - gaugeMin)))
    property color needleColor: normalized >= critThresh / (gaugeMax - gaugeMin)
                                ? colorCrit
                                : normalized >= warnThresh / (gaugeMax - gaugeMin)
                                  ? colorWarn : colorLow

    Connections {
        target: behaviourObject
        function onInternalSetValue(v)    { gaugeValue = v }
        function onInternalSetMin(v)      { gaugeMin = v }
        function onInternalSetMax(v)      { gaugeMax = v }
        function onInternalSetWarn(v)     { warnThresh = v }
        function onInternalSetCrit(v)     { critThresh = v }
        function onInternalSetUnit(s)     { unitLabel = s }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 6

        // ── Gauge canvas ───────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 140

            Canvas {
                id: canvas
                anchors.fill: parent
                anchors.margins: 4

                property real animValue: root.normalized

                Behavior on animValue { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                onAnimValueChanged: requestPaint()
                Component.onCompleted: requestPaint()

                Connections {
                    target: root
                    function onNormalizedChanged() { canvas.animValue = root.normalized }
                }

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    var cx     = width  / 2
                    var cy     = height * 0.62
                    var r      = Math.min(width, height * 1.2) * 0.44
                    var startA = Math.PI * 0.75
                    var endA   = Math.PI * 2.25
                    var span   = endA - startA

                    // Track background
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, startA, endA, false)
                    ctx.lineWidth   = 14
                    ctx.strokeStyle = Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.1)
                    ctx.stroke()

                    // Color zones
                    function drawZone(from_n, to_n, col) {
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, startA + from_n * span, startA + to_n * span, false)
                        ctx.lineWidth   = 14
                        ctx.strokeStyle = col
                        ctx.globalAlpha = 0.35
                        ctx.stroke()
                        ctx.globalAlpha = 1.0
                    }

                    var wn = (root.warnThresh - root.gaugeMin) / Math.max(0.001, root.gaugeMax - root.gaugeMin)
                    var cn = (root.critThresh - root.gaugeMin) / Math.max(0.001, root.gaugeMax - root.gaugeMin)
                    wn = Math.max(0, Math.min(1, wn))
                    cn = Math.max(0, Math.min(1, cn))

                    drawZone(0,  wn, root.colorLow)
                    drawZone(wn, cn, root.colorWarn)
                    drawZone(cn, 1,  root.colorCrit)

                    // Value arc
                    var fillColor = animValue >= cn ? root.colorCrit
                                  : animValue >= wn ? root.colorWarn
                                  : root.colorLow
                    if (animValue > 0) {
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, startA, startA + animValue * span, false)
                        ctx.lineWidth   = 14
                        ctx.strokeStyle = fillColor
                        ctx.globalAlpha = 0.9
                        ctx.stroke()
                        ctx.globalAlpha = 1.0
                    }

                    // Needle
                    var angle = startA + animValue * span
                    var nr    = r * 0.82
                    var nx    = cx + Math.cos(angle) * nr
                    var ny    = cy + Math.sin(angle) * nr

                    ctx.beginPath()
                    ctx.moveTo(cx, cy)
                    ctx.lineTo(nx, ny)
                    ctx.lineWidth   = 3
                    ctx.strokeStyle = fillColor
                    ctx.lineCap     = "round"
                    ctx.stroke()

                    // Center hub
                    ctx.beginPath()
                    ctx.arc(cx, cy, 7, 0, Math.PI * 2)
                    ctx.fillStyle = fillColor
                    ctx.fill()

                    // Min / Max tick labels
                    ctx.font      = "bold 9px Consolas"
                    ctx.fillStyle = Qt.rgba(ThemeManager.textSecondaryColor.r, ThemeManager.textSecondaryColor.g, ThemeManager.textSecondaryColor.b, 0.8)
                    ctx.textAlign = "center"

                    var minX = cx + Math.cos(startA) * (r + 18)
                    var minY = cy + Math.sin(startA) * (r + 18)
                    ctx.fillText(root.gaugeMin.toFixed(root.decimals), minX, minY)

                    var maxX = cx + Math.cos(endA) * (r + 18)
                    var maxY = cy + Math.sin(endA) * (r + 18)
                    ctx.fillText(root.gaugeMax.toFixed(root.decimals), maxX, maxY)
                }
            }

            // Digital readout overlay
            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                spacing: 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.gaugeValue.toFixed(root.decimals)
                    font.pixelSize: 26; font.family: "Consolas"; font.bold: true
                    color: root.needleColor
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.unitLabel
                    font.pixelSize: 10; color: ThemeManager.textSecondaryColor
                    visible: root.unitLabel !== ""
                }
            }
        }

        // ── Config row ─────────────────────────────────────────────────────
        GridLayout {
            Layout.fillWidth: true; columns: 2; columnSpacing: 6; rowSpacing: 3

            Text { text: "Min";  font.pixelSize: 9; color: ThemeManager.textSecondaryColor }
            NumericInputField {
                Layout.fillWidth: true; implicitHeight: 30
                value: root.gaugeMin; from: -1e9; to: 1e9; stepSize: 1; decimals: root.decimals
                accentColor: root.colorLow
                onValueModified: root.gaugeMin = newValue
            }

            Text { text: "Max";  font.pixelSize: 9; color: ThemeManager.textSecondaryColor }
            NumericInputField {
                Layout.fillWidth: true; implicitHeight: 30
                value: root.gaugeMax; from: -1e9; to: 1e9; stepSize: 1; decimals: root.decimals
                accentColor: root.colorCrit
                onValueModified: root.gaugeMax = newValue
            }

            Text { text: "Warn"; font.pixelSize: 9; color: root.colorWarn }
            NumericInputField {
                Layout.fillWidth: true; implicitHeight: 30
                value: root.warnThresh; from: root.gaugeMin; to: root.gaugeMax; stepSize: 1; decimals: root.decimals
                accentColor: root.colorWarn
                onValueModified: root.warnThresh = newValue
            }

            Text { text: "Crit"; font.pixelSize: 9; color: root.colorCrit }
            NumericInputField {
                Layout.fillWidth: true; implicitHeight: 30
                value: root.critThresh; from: root.gaugeMin; to: root.gaugeMax; stepSize: 1; decimals: root.decimals
                accentColor: root.colorCrit
                onValueModified: root.critThresh = newValue
            }
        }

        // ── Manual set + unit ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 4
            NumericInputField {
                Layout.fillWidth: true; implicitHeight: 34
                value: root.gaugeValue
                from: root.gaugeMin; to: root.gaugeMax; stepSize: 1; decimals: root.decimals
                showBar: true; accentColor: ThemeManager.primaryColor
                onValueModified: root.gaugeValue = newValue
            }
            Rectangle {
                Layout.preferredWidth: 60; Layout.preferredHeight: 34; radius: 4
                color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.06)
                border.width: 1; border.color: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.3)
                TextInput {
                    anchors { fill: parent; margins: 6 }
                    verticalAlignment: TextInput.AlignVCenter; horizontalAlignment: TextInput.AlignHCenter
                    font.pixelSize: 11; color: ThemeManager.textSecondaryColor
                    text: root.unitLabel; selectByMouse: true
                    onEditingFinished: root.unitLabel = text
                }
            }
        }
    }
}
