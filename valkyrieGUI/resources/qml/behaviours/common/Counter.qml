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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 6

        // ── Big counter display ───────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            radius: 6
            color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.2)

            Text {
                anchors.centerIn: parent
                text: behaviourObject ? behaviourObject.count : "0"
                font.pixelSize: 28; font.family: "Consolas"; font.bold: true
                color: ThemeManager.primaryColor
            }
        }

        // ── Step control ──────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 4
            Text { text: "Step"; font.pixelSize: 9; color: ThemeManager.textSecondaryColor; Layout.preferredWidth: 30 }
            CustomSlider {
                Layout.fillWidth: true; Layout.preferredHeight: 32
                from: 1; to: 100
                value: behaviourObject ? behaviourObject.step : 1
                textColor: ThemeManager.textColor
                color: ThemeManager.primaryColor
                onValueChanged: if(behaviourObject) behaviourObject.setStep(Math.round(value))
            }
        }

        // ── Control buttons ───────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 4

            NewButton {
                Layout.fillWidth: true; Layout.preferredHeight: 32
                variant: "outlined"; text: "−"
                backgroundColor: ThemeManager.dangerColor
                onClicked: behaviourObject.decrement()
            }

            NewButton {
                Layout.preferredWidth: 50; Layout.preferredHeight: 32
                variant: "outlined"; text: "⟳"
                backgroundColor: ThemeManager.textSecondaryColor
                onClicked: behaviourObject.reset()
            }

            NewButton {
                Layout.fillWidth: true; Layout.preferredHeight: 32
                variant: "filled"; text: "+"
                backgroundColor: ThemeManager.primaryColor
                onClicked: behaviourObject.increment()
            }
        }
    }
}
