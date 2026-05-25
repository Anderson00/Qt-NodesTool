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

        // ── Formatted output preview ──────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 6
            color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.2)
            Text {
                anchors.centerIn: parent
                text: behaviourObject ? behaviourObject.dateStr : "—"
                font.pixelSize: 13; font.family: "Consolas"; font.bold: true
                color: ThemeManager.primaryColor
            }
        }

        // ── Date picker ───────────────────────────────────────────────────
        // CustomDatePicker emits: signal dateChanged(date date)
        // JS Date.getMonth() é 0-indexado → +1
        CustomDatePicker {
            Layout.fillWidth: true
            onDateChanged: function(d) {
                if (behaviourObject)
                    behaviourObject.setDate(d.getFullYear(), d.getMonth() + 1, d.getDate())
            }
        }

        // ── Time picker ───────────────────────────────────────────────────
        TimePicker {
            Layout.fillWidth: true
            onTimeChanged: function(h, m, s) {
                if (behaviourObject) behaviourObject.setTime(h, m, s)
            }
        }

        // ── Format selector ───────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Text { text: qsTr("Format"); font.pixelSize: 10; color: ThemeManager.textColor; opacity: 0.55; Layout.alignment: Qt.AlignVCenter }
            CustomComboBox {
                Layout.fillWidth: true
                model: ["yyyy-MM-dd HH:mm:ss", "dd/MM/yyyy", "MM/dd/yyyy", "yyyy-MM-dd", "HH:mm:ss", "ISO 8601"]
                onCurrentTextChanged: if (behaviourObject) behaviourObject.setFormat(currentText)
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
