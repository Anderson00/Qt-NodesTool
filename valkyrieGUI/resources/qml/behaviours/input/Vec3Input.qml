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

        // ── X / Y / Z fields ──────────────────────────────────────────────
        Repeater {
            model: [
                { axis: "X", prop: "vecX", setter: "setVecX", color: "#EF5350" },
                { axis: "Y", prop: "vecY", setter: "setVecY", color: "#66BB6A" },
                { axis: "Z", prop: "vecZ", setter: "setVecZ", color: "#42A5F5" }
            ]

            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: 8
                required property var modelData

                Rectangle {
                    width: 20; height: 20; radius: 3
                    color: modelData.color
                    Text {
                        anchors.centerIn: parent
                        text: modelData.axis
                        font.pixelSize: 11; font.bold: true
                        color: "#FFFFFF"
                    }
                }

                NumericInputField {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    // bind via modelData.prop (vecX/vecY/vecZ)
                    value: behaviourObject ? (behaviourObject[modelData.prop] || 0) : 0
                    decimals: 3
                    onValueModified: function(newValue) {
                        if (behaviourObject) behaviourObject[modelData.setter](newValue)
                    }
                }
            }
        }

        // ── Magnitude display ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            radius: 4
            color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.06)

            Text {
                anchors.centerIn: parent
                text: behaviourObject
                      ? "|v| = " + Math.sqrt(
                            behaviourObject.vecX * behaviourObject.vecX +
                            behaviourObject.vecY * behaviourObject.vecY +
                            behaviourObject.vecZ * behaviourObject.vecZ
                        ).toFixed(3)
                      : "|v| = 0.000"
                font.pixelSize: 11; font.family: "Consolas"
                color: ThemeManager.primaryColor
            }
        }

        // ── Auto + Send ───────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 6
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
