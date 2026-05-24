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

        // ── Main value display ────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 6
            color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.25)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 4

                // Decrement
                Rectangle {
                    Layout.preferredWidth: 34; Layout.fillHeight: true; radius: 5
                    color: decMouse.containsMouse
                           ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.25)
                           : Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.08)
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { anchors.centerIn: parent; text: "−"; font.pixelSize: 20; font.bold: true; color: ThemeManager.primaryColor }
                    MouseArea {
                        id: decMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: if (behaviourObject) behaviourObject.setValue(behaviourObject.value - behaviourObject.stepSize)
                    }
                }

                // Value input — centered in available space
                TextInput {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment:   TextInput.AlignVCenter
                    font.pixelSize: 22; font.family: "Consolas"; font.bold: true
                    color: ThemeManager.primaryColor
                    text: behaviourObject ? behaviourObject.value.toFixed(2) : "0.00"
                    selectByMouse: true
                    validator: DoubleValidator {}
                    onAccepted: {
                        var v = parseFloat(text)
                        if (!isNaN(v) && behaviourObject) behaviourObject.setValue(v)
                    }
                }

                // Increment
                Rectangle {
                    Layout.preferredWidth: 34; Layout.fillHeight: true; radius: 5
                    color: incMouse.containsMouse
                           ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.25)
                           : Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.08)
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text { anchors.centerIn: parent; text: "+"; font.pixelSize: 20; font.bold: true; color: ThemeManager.primaryColor }
                    MouseArea {
                        id: incMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: if (behaviourObject) behaviourObject.setValue(behaviourObject.value + behaviourObject.stepSize)
                    }
                }
            }
        }

        // ── Step ─────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Text {
                text: "Step"
                font.pixelSize: 11; color: ThemeManager.textColor; opacity: 0.55
                Layout.preferredWidth: 32; Layout.alignment: Qt.AlignVCenter
            }
            NumericInputField {
                Layout.fillWidth: true; Layout.preferredHeight: 30
                value: behaviourObject ? behaviourObject.stepSize : 1
                decimals: 3; from: 0.001
                onValueModified: function(v) { if (behaviourObject) behaviourObject.setStepSize(v) }
            }
        }

        // ── Min / Max ─────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Text {
                text: "Min"
                font.pixelSize: 11; color: ThemeManager.textColor; opacity: 0.55
                Layout.preferredWidth: 32; Layout.alignment: Qt.AlignVCenter
            }
            NumericInputField {
                Layout.fillWidth: true; Layout.preferredHeight: 30
                value: behaviourObject ? behaviourObject.minValue : -1e9
                decimals: 2
                onValueModified: function(v) { if (behaviourObject) behaviourObject.setMinValue(v) }
            }
            Text {
                text: "Max"
                font.pixelSize: 11; color: ThemeManager.textColor; opacity: 0.55
                Layout.alignment: Qt.AlignVCenter
            }
            NumericInputField {
                Layout.fillWidth: true; Layout.preferredHeight: 30
                value: behaviourObject ? behaviourObject.maxValue : 1e9
                decimals: 2
                onValueModified: function(v) { if (behaviourObject) behaviourObject.setMaxValue(v) }
            }
        }

        // ── Auto toggle ───────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Text { text: "Auto-send"; font.pixelSize: 11; color: ThemeManager.textColor; opacity: 0.6; Layout.alignment: Qt.AlignVCenter }
            CustomSwitch {
                checked: behaviourObject ? behaviourObject.autoSend : false
                onCheckedChanged: if (behaviourObject) behaviourObject.setAutoSend(checked)
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // ── Send button — full width ──────────────────────────────────────
        NewButton {
            Layout.fillWidth: true; Layout.preferredHeight: 36
            text: "Send"; variant: "filled"; iconSource: Icons.flash
            backgroundColor: ThemeManager.primaryColor
            onClicked: if (behaviourObject) behaviourObject.send()
        }
    }
}
