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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        // ── X / Y fields ──────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true; spacing: 3
                Text { text: qsTr("X"); font.pixelSize: 11; font.bold: true; color: "#EF5350"; Layout.alignment: Qt.AlignHCenter }
                NumericInputField {
                    Layout.fillWidth: true; Layout.preferredHeight: 32
                    // vecX — não usar 'x' (conflito com Behaviours base)
                    value: behaviourObject ? behaviourObject.vecX : 0
                    decimals: 3
                    onValueModified: function(newValue) { if (behaviourObject) behaviourObject.setVecX(newValue) }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 3
                Text { text: qsTr("Y"); font.pixelSize: 11; font.bold: true; color: "#66BB6A"; Layout.alignment: Qt.AlignHCenter }
                NumericInputField {
                    Layout.fillWidth: true; Layout.preferredHeight: 32
                    // vecY — não usar 'y'
                    value: behaviourObject ? behaviourObject.vecY : 0
                    decimals: 3
                    onValueModified: function(newValue) { if (behaviourObject) behaviourObject.setVecY(newValue) }
                }
            }
        }

        // ── Vector arrow preview ──────────────────────────────────────────
        Canvas {
            id: vecCanvas
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            antialiasing: true
            Component.onCompleted: requestPaint()

            property real vx: behaviourObject ? behaviourObject.vecX : 0
            property real vy: behaviourObject ? behaviourObject.vecY : 0

            onVxChanged: requestPaint()
            onVyChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var cx = width  / 2
                var cy = height / 2
                var maxLen = Math.min(width, height) * 0.42

                // grid lines
                ctx.strokeStyle = Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.1)
                ctx.lineWidth = 0.5
                ctx.beginPath(); ctx.moveTo(cx, 4); ctx.lineTo(cx, height - 4); ctx.stroke()
                ctx.beginPath(); ctx.moveTo(4, cy); ctx.lineTo(width - 4, cy); ctx.stroke()

                var mag = Math.sqrt(vx * vx + vy * vy)
                if (mag < 1e-9) return

                var scale = Math.min(maxLen / mag, maxLen)
                var ex = cx + vx * scale
                var ey = cy - vy * scale  // Y flipped (screen coords)
                var angle = Math.atan2(ey - cy, ex - cx)
                var headLen = 8

                // shaft
                ctx.strokeStyle = ThemeManager.primaryColor
                ctx.lineWidth = 2
                ctx.beginPath(); ctx.moveTo(cx, cy); ctx.lineTo(ex, ey); ctx.stroke()

                // arrowhead
                ctx.fillStyle = ThemeManager.primaryColor
                ctx.beginPath()
                ctx.moveTo(ex, ey)
                ctx.lineTo(ex - headLen * Math.cos(angle - 0.4), ey - headLen * Math.sin(angle - 0.4))
                ctx.lineTo(ex - headLen * Math.cos(angle + 0.4), ey - headLen * Math.sin(angle + 0.4))
                ctx.closePath(); ctx.fill()
            }

            // magnitude label
            Text {
                anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                text: behaviourObject
                      ? "|v| = " + Math.sqrt(behaviourObject.vecX * behaviourObject.vecX + behaviourObject.vecY * behaviourObject.vecY).toFixed(2)
                      : "|v| = 0.00"
                font.pixelSize: 10; font.family: "Consolas"
                color: ThemeManager.textColor; opacity: 0.5
            }
        }

        // ── Auto-send toggle ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Text { text: qsTr("Auto-send"); font.pixelSize: 11; color: ThemeManager.textColor; opacity: 0.6; Layout.alignment: Qt.AlignVCenter }
            CustomSwitch {
                checked: behaviourObject ? behaviourObject.autoSend : false
                onCheckedChanged: if (behaviourObject) behaviourObject.setAutoSend(checked)
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // ── Send — full width ─────────────────────────────────────────────
        NewButton {
            Layout.fillWidth: true; Layout.preferredHeight: 36
            text: qsTr("Send"); variant: "filled"; iconSource: Icons.flash
            backgroundColor: ThemeManager.primaryColor
            onClicked: if (behaviourObject) behaviourObject.send()
        }
    }
}
