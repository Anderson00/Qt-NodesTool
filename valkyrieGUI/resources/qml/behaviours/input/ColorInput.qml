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
        spacing: 8

        // ── Color preview swatch ──────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 6
            color: behaviourObject ? behaviourObject.colorHex : "#FFFFFF"
            border.width: 1
            border.color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.2)

            Text {
                anchors.centerIn: parent
                text: behaviourObject ? behaviourObject.colorHex : "#FFFFFF"
                font.pixelSize: 13; font.family: "Consolas"; font.bold: true
                // Contrasting text: white on dark colors, dark on light
                color: {
                    if (!behaviourObject) return "#000000"
                    var c = Qt.color(behaviourObject.colorHex)
                    var luminance = 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
                    return luminance > 0.55 ? "#222222" : "#FFFFFF"
                }
            }
        }

        // ── ColorPicker component (existing) ──────────────────────────────
        ColorPicker {
            Layout.fillWidth: true
            value: behaviourObject ? Qt.color(behaviourObject.colorHex) : Qt.color("#FFFFFF")
            showHex: false
            onAccepted: function(color) {
                if (behaviourObject)
                    behaviourObject.setColorHex(color.toString().toUpperCase())
            }
        }

        // ── Auto + Send ───────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Text { text: "Auto"; font.pixelSize: 11; color: ThemeManager.textColor; opacity: 0.6; Layout.alignment: Qt.AlignVCenter }
            CustomSwitch {
                checked: behaviourObject ? behaviourObject.autoSend : false
                onCheckedChanged: if (behaviourObject) behaviourObject.setAutoSend(checked)
                Layout.alignment: Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
            NewButton {
                text: "Send"; variant: "filled"; iconSource: Icons.flash
                backgroundColor: ThemeManager.primaryColor
                Layout.preferredHeight: 28; Layout.preferredWidth: 70
                onClicked: if (behaviourObject) behaviourObject.send()
            }
        }
    }
}
