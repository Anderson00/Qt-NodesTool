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

    readonly property var modeNames: ["Float", "Int", "Gaussian", "Dice", "Bool", "Sequence"]
    readonly property var modeIcons: [
        Qaterial.Icons.decimalIncrease,
        Qaterial.Icons.numeric,
        Qaterial.Icons.chartBellCurve,
        Qaterial.Icons.diceMultiple,
        Qaterial.Icons.toggleSwitch,
        Qaterial.Icons.formatListNumbered
    ]

    Timer {
        id: autoTimer
        repeat: true
        interval: intervalField.value
        onTriggered: behaviourObject.generate()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // ── Value display ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 54
            radius: 6
            color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.2)

            RowLayout {
                anchors.fill: parent; anchors.margins: 6; spacing: 4

                TextInput {
                    id: valueInput
                    Layout.fillWidth: true; Layout.fillHeight: true
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    font.pixelSize: 22; font.family: "Consolas"; font.bold: true
                    color: ThemeManager.primaryColor
                    selectionColor: ThemeManager.primaryColor
                    selectedTextColor: ThemeManager.backgroundColor
                    text: behaviourObject ? behaviourObject.lastValue.toFixed(behaviourObject.precision) : "0"
                    selectByMouse: true
                    onAccepted: { var v = parseFloat(text); if (!isNaN(v)) behaviourObject.setValue(v) }
                    Connections {
                        target: behaviourObject
                        function onLastValueChanged() {
                            if (!valueInput.activeFocus)
                                valueInput.text = behaviourObject.lastValue.toFixed(behaviourObject.precision)
                        }
                    }
                }

                Rectangle {
                    width: 28; height: 28; radius: 4
                    color: sendMa.containsMouse
                           ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.2)
                           : "transparent"
                    Qaterial.ColorIcon {
                        anchors.centerIn: parent
                        source: Qaterial.Icons.send; width: 14; height: 14
                        color: ThemeManager.primaryColor
                    }
                    MouseArea {
                        id: sendMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { var v = parseFloat(valueInput.text); if (!isNaN(v)) behaviourObject.setValue(v) }
                    }
                }
            }
        }

        // ── Stats bar ──────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 2
            Repeater {
                model: [
                    { label: "n",   value: behaviourObject ? behaviourObject.genCount          : 0 },
                    { label: "min", value: behaviourObject ? behaviourObject.minSeen.toFixed(1) : "-" },
                    { label: "avg", value: behaviourObject ? behaviourObject.avgValue.toFixed(1) : "-" },
                    { label: "max", value: behaviourObject ? behaviourObject.maxSeen.toFixed(1) : "-" }
                ]
                delegate: Rectangle {
                    Layout.fillWidth: true; height: 28; radius: 3
                    color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.05)
                    Column {
                        anchors.centerIn: parent; spacing: 0
                        Text { text: modelData.value; font.pixelSize: 10; font.bold: true; color: ThemeManager.textColor; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: modelData.label; font.pixelSize: 8; color: ThemeManager.textColor; opacity: 0.4; anchors.horizontalCenter: parent.horizontalCenter }
                    }
                }
            }
            Rectangle {
                width: 28; height: 28; radius: 3
                color: rstMa.containsMouse ? Qt.rgba(ThemeManager.dangerColor.r, ThemeManager.dangerColor.g, ThemeManager.dangerColor.b, 0.15) : "transparent"
                Qaterial.ColorIcon { anchors.centerIn: parent; source: Qaterial.Icons.refresh; width: 12; height: 12; color: ThemeManager.textColor; opacity: 0.5 }
                MouseArea { id: rstMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: behaviourObject.resetStats() }
            }
        }

        // ── Mode selector ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 28; radius: 4
            color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.04)
            clip: true
            Row {
                anchors.fill: parent; spacing: 0
                Repeater {
                    model: root.modeNames
                    delegate: Rectangle {
                        width: parent.width / root.modeNames.length; height: 28; radius: 4
                        color: behaviourObject && behaviourObject.mode === index ? ThemeManager.primaryColor : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Column {
                            anchors.centerIn: parent; spacing: 1
                            Qaterial.ColorIcon {
                                source: root.modeIcons[index]; width: 12; height: 12
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: behaviourObject && behaviourObject.mode === index ? ThemeManager.backgroundColor : ThemeManager.textColor
                                opacity: behaviourObject && behaviourObject.mode === index ? 1.0 : 0.5
                            }
                            Text {
                                text: modelData; font.pixelSize: 7
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: behaviourObject && behaviourObject.mode === index ? ThemeManager.backgroundColor : ThemeManager.textColor
                                opacity: behaviourObject && behaviourObject.mode === index ? 1.0 : 0.4
                            }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: behaviourObject.setMode(index) }
                    }
                }
            }
        }

        // ── Float / Int / Gaussian / Sequence: Min & Max ───────────────────
        ColumnLayout {
            Layout.fillWidth: true
            visible: behaviourObject && (behaviourObject.mode <= 2 || behaviourObject.mode === 5)
            spacing: 3

            NumericInputField {
                Layout.fillWidth: true; implicitHeight: 34
                label: "Min"
                value: behaviourObject ? behaviourObject.rangeMin : 0
                from: -1e9; to: 1e9; stepSize: 1.0; decimals: 2
                accentColor: "#3498db"
                onValueModified: if (behaviourObject) behaviourObject.setRangeMin(newValue)
            }
            NumericInputField {
                Layout.fillWidth: true; implicitHeight: 34
                label: "Max"
                value: behaviourObject ? behaviourObject.rangeMax : 100
                from: -1e9; to: 1e9; stepSize: 1.0; decimals: 2
                accentColor: "#2ecc71"
                onValueModified: if (behaviourObject) behaviourObject.setRangeMax(newValue)
            }
        }

        // ── Gaussian: Mean & StdDev ────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            visible: behaviourObject && behaviourObject.mode === 2
            spacing: 3

            NumericInputField {
                Layout.fillWidth: true; implicitHeight: 34
                label: "μ"; value: behaviourObject ? behaviourObject.mean : 50
                from: -1e6; to: 1e6; stepSize: 1.0; decimals: 2
                accentColor: "#7C4DFF"
                onValueModified: if (behaviourObject) behaviourObject.setMean(newValue)
            }
            NumericInputField {
                Layout.fillWidth: true; implicitHeight: 34
                label: "σ"; value: behaviourObject ? behaviourObject.stddev : 15
                from: 0.001; to: 1e6; stepSize: 1.0; decimals: 3
                accentColor: "#7C4DFF"
                onValueModified: if (behaviourObject) behaviourObject.setStddev(newValue)
            }
        }

        // ── Dice: Count & Sides ────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            visible: behaviourObject && behaviourObject.mode === 3
            spacing: 3

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: behaviourObject ? behaviourObject.diceCount + "d" + behaviourObject.diceSides : "1d6"
                font.pixelSize: 16; font.bold: true; color: "#FF6D00"
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 6
                NumberSpinBox {
                    Layout.fillWidth: true; from: 1; to: 100; stepSize: 1
                    value: behaviourObject ? behaviourObject.diceCount : 1
                    accentColor: "#FF6D00"
                    onValueChanged: if (behaviourObject) behaviourObject.setDiceCount(value)
                }
                Text { text: "d"; font.pixelSize: 14; color: "#FF6D00"; Layout.alignment: Qt.AlignVCenter }
                NumberSpinBox {
                    Layout.fillWidth: true; from: 2; to: 1000; stepSize: 1
                    value: behaviourObject ? behaviourObject.diceSides : 6
                    accentColor: "#FF6D00"
                    onValueChanged: if (behaviourObject) behaviourObject.setDiceSides(value)
                }
            }
        }

        // ── Bool: Probability ──────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            visible: behaviourObject && behaviourObject.mode === 4
            spacing: 3

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: behaviourObject ? (behaviourObject.probability * 100).toFixed(1) + "% true" : "50%"
                font.pixelSize: 14; font.bold: true
                color: behaviourObject && behaviourObject.lastValue ? "#00C853" : "#FF1744"
            }
            NumericInputField {
                Layout.fillWidth: true; implicitHeight: 34
                label: "P"
                value: behaviourObject ? behaviourObject.probability * 100 : 50
                from: 0; to: 100; stepSize: 1; decimals: 1; suffix: "%"
                showBar: true; accentColor: "#00C853"
                onValueModified: if (behaviourObject) behaviourObject.setProbability(newValue / 100.0)
            }
        }

        // ── Precision (non-Dice, non-Bool) ─────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 4
            visible: behaviourObject && behaviourObject.mode !== 3 && behaviourObject.mode !== 4

            Text { text: ".0"; font.pixelSize: 9; color: ThemeManager.textSecondaryColor; Layout.alignment: Qt.AlignVCenter }

            Rectangle {
                Layout.fillWidth: true; height: 28; radius: 4
                color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.04)
                clip: true
                Row {
                    anchors.fill: parent; spacing: 0
                    Repeater {
                        model: 9
                        delegate: Rectangle {
                            width: parent.width / 9; height: 28; radius: 4
                            property bool active: behaviourObject && behaviourObject.precision === index
                            color: active ? ThemeManager.primaryColor : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text {
                                anchors.centerIn: parent; text: index; font.pixelSize: 9
                                color: active ? ThemeManager.backgroundColor : ThemeManager.textColor
                                opacity: active ? 1.0 : 0.5
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (behaviourObject) behaviourObject.setPrecision(index) }
                        }
                    }
                }
            }
        }

        // ── Interval ───────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Text { text: "⏱"; font.pixelSize: 12; Layout.alignment: Qt.AlignVCenter }
            NumericInputField {
                id: intervalField
                Layout.fillWidth: true; implicitHeight: 34
                value: 500; from: 10; to: 60000; stepSize: 50; decimals: 0; suffix: "ms"
                showBar: true; accentColor: ThemeManager.textSecondaryColor
            }
        }

        // ── Control buttons ────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 4
            NewButton {
                Layout.fillWidth: true; Layout.preferredHeight: 32
                variant: "filled"
                text: autoTimer.running ? "■ Stop" : "▶ Auto"
                backgroundColor: autoTimer.running ? ThemeManager.dangerColor : ThemeManager.primaryColor
                onClicked: { if (autoTimer.running) autoTimer.stop(); else autoTimer.start() }
            }
            NewButton {
                Layout.preferredWidth: 56; Layout.preferredHeight: 32
                variant: "outlined"; text: "Step"
                backgroundColor: ThemeManager.primaryColor
                onClicked: behaviourObject.generate()
            }
        }
    }
}
