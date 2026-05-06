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
        spacing: 4

        // ── Result display ────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 52; radius: 6
            color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.2)

            RowLayout {
                anchors.centerIn: parent; spacing: 12
                Column {
                    spacing: 1
                    Text { text: "Clamped"; font.pixelSize: 8; color: ThemeManager.textSecondaryColor; anchors.horizontalCenter: parent.horizontalCenter }
                    Text {
                        text: behaviourObject ? behaviourObject.clampedValue.toFixed(3) : "0"
                        font.pixelSize: 16; font.family: "Consolas"; font.bold: true
                        color: ThemeManager.primaryColor; anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                Rectangle { width: 1; height: 30; color: ThemeManager.borderColor; opacity: 0.4 }

                Column {
                    spacing: 1
                    Text { text: "Normalized"; font.pixelSize: 8; color: ThemeManager.textSecondaryColor; anchors.horizontalCenter: parent.horizontalCenter }
                    Text {
                        text: behaviourObject ? behaviourObject.normalized.toFixed(4) : "0"
                        font.pixelSize: 16; font.family: "Consolas"; font.bold: true
                        color: "#f39c12"; anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }

        // ── Progress bar visualization ────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 8; radius: 4
            color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.1)
            Rectangle {
                width: parent.width * (behaviourObject ? behaviourObject.normalized : 0)
                height: parent.height; radius: 4
                color: ThemeManager.primaryColor
                Behavior on width { NumberAnimation { duration: 100 } }
            }
        }

        // ── Min slider ────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 4
            Text { text: "Min"; font.pixelSize: 9; color: ThemeManager.textSecondaryColor; Layout.preferredWidth: 24 }
            CustomSlider {
                Layout.fillWidth: true; Layout.preferredHeight: 32
                from: -1000; to: 1000
                value: behaviourObject ? behaviourObject.rangeMin : 0
                textColor: ThemeManager.textColor; color: "#e74c3c"
                onMoved: if(behaviourObject) behaviourObject.setMin(value)
            }
        }

        // ── Max slider ────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 4
            Text { text: "Max"; font.pixelSize: 9; color: ThemeManager.textSecondaryColor; Layout.preferredWidth: 24 }
            CustomSlider {
                Layout.fillWidth: true; Layout.preferredHeight: 32
                from: -1000; to: 1000
                value: behaviourObject ? behaviourObject.rangeMax : 1
                textColor: ThemeManager.textColor; color: "#2ecc71"
                onMoved: if(behaviourObject) behaviourObject.setMax(value)
            }
        }
    }
}
