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
            Layout.preferredHeight: 52
            radius: 6
            color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.25)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 2

                // Decrement button
                Rectangle {
                    width: 32; height: 36; radius: 4
                    color: decMouse.containsMouse
                           ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.2)
                           : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "−"; font.pixelSize: 18; font.bold: true
                        color: ThemeManager.primaryColor
                    }
                    MouseArea {
                        id: decMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: if (behaviourObject) behaviourObject.setValue(behaviourObject.value - behaviourObject.stepSize)
                    }
                }

                // Value input
                TextInput {
                    Layout.fillWidth: true
                    horizontalAlignment: TextInput.AlignHCenter
                    verticalAlignment: TextInput.AlignVCenter
                    font.pixelSize: 20; font.family: "Consolas"; font.bold: true
                    color: ThemeManager.primaryColor
                    text: behaviourObject ? behaviourObject.value.toFixed(2) : "0.00"
                    selectByMouse: true
                    validator: DoubleValidator {}
                    onAccepted: { var v = parseFloat(text); if (!isNaN(v) && behaviourObject) behaviourObject.setValue(v) }
                }

                // Increment button
                Rectangle {
                    width: 32; height: 36; radius: 4
                    color: incMouse.containsMouse
                           ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.2)
                           : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "+"; font.pixelSize: 18; font.bold: true
                        color: ThemeManager.primaryColor
                    }
                    MouseArea {
                        id: incMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: if (behaviourObject) behaviourObject.setValue(behaviourObject.value + behaviourObject.stepSize)
                    }
                }
            }
        }

        // ── Step / range row ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text { text: "Step"; font.pixelSize: 10; color: ThemeManager.textColor; opacity: 0.5; Layout.alignment: Qt.AlignVCenter }
            NumericInputField {
                Layout.preferredWidth: 60; Layout.preferredHeight: 26
                value: behaviourObject ? behaviourObject.stepSize : 1
                decimals: 2
                // onValueModified — NÃO usar onValueChanged: sobrescreve o handler
                // interno que sincroniza o texto do campo
                onValueModified: function(newValue) { if (behaviourObject) behaviourObject.setStepSize(newValue) }
            }
            Item { Layout.fillWidth: true }
            Text { text: "Min"; font.pixelSize: 10; color: ThemeManager.textColor; opacity: 0.5; Layout.alignment: Qt.AlignVCenter }
            NumericInputField {
                Layout.preferredWidth: 55; Layout.preferredHeight: 26
                value: behaviourObject ? behaviourObject.minValue : -1e9
                decimals: 1
                onValueModified: function(newValue) { if (behaviourObject) behaviourObject.setMinValue(newValue) }
            }
            Text { text: "Max"; font.pixelSize: 10; color: ThemeManager.textColor; opacity: 0.5; Layout.alignment: Qt.AlignVCenter }
            NumericInputField {
                Layout.preferredWidth: 55; Layout.preferredHeight: 26
                value: behaviourObject ? behaviourObject.maxValue : 1e9
                decimals: 1
                onValueModified: function(newValue) { if (behaviourObject) behaviourObject.setMaxValue(newValue) }
            }
        }

        // ── Auto-send + Send ──────────────────────────────────────────────
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
