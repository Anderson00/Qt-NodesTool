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

        // ── X / Y fields ──────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // X
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Text {
                    text: "X"
                    font.pixelSize: 11; font.bold: true
                    color: "#EF5350"
                    Layout.alignment: Qt.AlignHCenter
                }
                NumericInputField {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    value: behaviourObject ? behaviourObject.xValue : 0
                    decimals: 3
                    onValueModified: function(newValue) { if (behaviourObject) behaviourObject.setXValue(newValue) }
                }
            }

            // Y
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3
                Text {
                    text: "Y"
                    font.pixelSize: 11; font.bold: true
                    color: "#66BB6A"
                    Layout.alignment: Qt.AlignHCenter
                }
                NumericInputField {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    value: behaviourObject ? behaviourObject.yValue : 0
                    decimals: 3
                    onValueModified: function(newValue) { if (behaviourObject) behaviourObject.setYValue(newValue) }
                }
            }
        }

        // ── Preview label ─────────────────────────────────────────────────
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: behaviourObject ? "(" + behaviourObject.xValue.toFixed(2) + ", " + behaviourObject.yValue.toFixed(2) + ")" : "(0, 0)"
            font.pixelSize: 11; font.family: "Consolas"
            color: ThemeManager.textColor; opacity: 0.5
        }

        // ── Auto-send toggle ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Text { text: "Auto-send"; font.pixelSize: 11; color: ThemeManager.textColor; opacity: 0.6; Layout.alignment: Qt.AlignVCenter }
            CustomSwitch {
                checked: behaviourObject ? behaviourObject.autoSend : false
                onCheckedChanged: if (behaviourObject) behaviourObject.setAutoSend(checked)
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // ── Send — full width ─────────────────────────────────────────────
        NewButton {
            Layout.fillWidth: true; Layout.preferredHeight: 36
            text: "Send"; variant: "filled"; iconSource: Icons.flash
            backgroundColor: ThemeManager.primaryColor
            onClicked: if (behaviourObject) behaviourObject.send()
        }
    }
}
