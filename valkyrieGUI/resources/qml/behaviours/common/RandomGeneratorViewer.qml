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

    // ── Mode names / icons ───────────────────────────────────────────────
    readonly property var modeNames: ["Float", "Integer", "Gaussian", "Dice", "Bool", "Sequence"]
    readonly property var modeIcons: [
        Qaterial.Icons.decimalIncrease,
        Qaterial.Icons.numeric,
        Qaterial.Icons.chartBellCurve,
        Qaterial.Icons.diceMultiple,
        Qaterial.Icons.toggleSwitch,
        Qaterial.Icons.formatListNumbered
    ]

    // ── Timer ────────────────────────────────────────────────────────────
    Timer {
        id: autoTimer
        repeat: true
        interval: intervalSlider.value
        onTriggered: behaviourObject.generate()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // ═══════════════════════════════════════════════════════════════════
        // VALUE DISPLAY
        // ═══════════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 54
            radius: 6
            color: Qt.rgba(ThemeManager.primaryColor.r,
                           ThemeManager.primaryColor.g,
                           ThemeManager.primaryColor.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.primaryColor.r,
                                  ThemeManager.primaryColor.g,
                                  ThemeManager.primaryColor.b, 0.2)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 4

                // Editable value field
                TextInput {
                    id: valueInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    font.pixelSize: 22
                    font.family: "Consolas"
                    font.bold: true
                    color: ThemeManager.primaryColor
                    selectionColor: ThemeManager.primaryColor
                    selectedTextColor: ThemeManager.backgroundColor
                    text: behaviourObject ? behaviourObject.lastValue.toFixed(behaviourObject.precision) : "0"
                    selectByMouse: true

                    onAccepted: {
                        let val = parseFloat(text)
                        if (!isNaN(val)) behaviourObject.setValue(val)
                    }

                    Connections {
                        target: behaviourObject
                        function onLastValueChanged() {
                            if (!valueInput.activeFocus) {
                                valueInput.text = behaviourObject.lastValue.toFixed(behaviourObject.precision)
                            }
                        }
                    }
                }

                // Send button (push manual value)
                Rectangle {
                    width: 28; height: 28; radius: 4
                    color: sendMa.containsMouse
                           ? Qt.rgba(ThemeManager.primaryColor.r,
                                     ThemeManager.primaryColor.g,
                                     ThemeManager.primaryColor.b, 0.2)
                           : "transparent"
                    Qaterial.ColorIcon {
                        anchors.centerIn: parent
                        source: Qaterial.Icons.send; width: 14; height: 14
                        color: ThemeManager.primaryColor
                    }
                    MouseArea {
                        id: sendMa
                        anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let val = parseFloat(valueInput.text)
                            if (!isNaN(val)) behaviourObject.setValue(val)
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // STATS BAR
        // ═══════════════════════════════════════════════════════════════════
        RowLayout {
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: [
                    { label: "n", value: behaviourObject ? behaviourObject.genCount : 0 },
                    { label: "min", value: behaviourObject ? behaviourObject.minSeen.toFixed(1) : "-" },
                    { label: "avg", value: behaviourObject ? behaviourObject.avgValue.toFixed(1) : "-" },
                    { label: "max", value: behaviourObject ? behaviourObject.maxSeen.toFixed(1) : "-" }
                ]

                delegate: Rectangle {
                    Layout.fillWidth: true; height: 28; radius: 3
                    color: Qt.rgba(ThemeManager.textColor.r,
                                   ThemeManager.textColor.g,
                                   ThemeManager.textColor.b, 0.05)
                    Column {
                        anchors.centerIn: parent; spacing: 0
                        Text {
                            text: modelData.value; font.pixelSize: 10; font.bold: true
                            color: ThemeManager.textColor; anchors.horizontalCenter: parent.horizontalCenter
                        }
                        Text {
                            text: modelData.label; font.pixelSize: 8
                            color: ThemeManager.textColor; opacity: 0.4
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

            // Reset stats button
            Rectangle {
                width: 28; height: 28; radius: 3
                color: resetMa.containsMouse
                       ? Qt.rgba(ThemeManager.dangerColor.r,
                                 ThemeManager.dangerColor.g,
                                 ThemeManager.dangerColor.b, 0.15) : "transparent"
                Qaterial.ColorIcon {
                    anchors.centerIn: parent
                    source: Qaterial.Icons.refresh; width: 12; height: 12
                    color: ThemeManager.textColor; opacity: 0.5
                }
                MouseArea {
                    id: resetMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: behaviourObject.resetStats()
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // MODE SELECTOR (pill tabs)
        // ═══════════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true; height: 28; radius: 4
            color: Qt.rgba(ThemeManager.textColor.r,
                           ThemeManager.textColor.g,
                           ThemeManager.textColor.b, 0.04)
            clip: true

            Row {
                anchors.fill: parent; spacing: 0

                Repeater {
                    model: root.modeNames

                    delegate: Rectangle {
                        width: parent.width / root.modeNames.length; height: 28
                        radius: 4
                        color: behaviourObject && behaviourObject.mode === index
                               ? ThemeManager.primaryColor : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Column {
                            anchors.centerIn: parent; spacing: 1
                            Qaterial.ColorIcon {
                                source: root.modeIcons[index]
                                width: 12; height: 12
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: behaviourObject && behaviourObject.mode === index
                                       ? ThemeManager.backgroundColor : ThemeManager.textColor
                                opacity: behaviourObject && behaviourObject.mode === index ? 1.0 : 0.5
                            }
                            Text {
                                text: modelData; font.pixelSize: 7
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: behaviourObject && behaviourObject.mode === index
                                       ? ThemeManager.backgroundColor : ThemeManager.textColor
                                opacity: behaviourObject && behaviourObject.mode === index ? 1.0 : 0.4
                            }
                        }

                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: behaviourObject.setMode(index)
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // MODE-SPECIFIC PARAMETERS
        // ═══════════════════════════════════════════════════════════════════

        // ── Float / Integer / Gaussian / Sequence: Min & Max ─────────────
        ColumnLayout {
            Layout.fillWidth: true
            visible: behaviourObject && (behaviourObject.mode <= 2 || behaviourObject.mode === 5)
            spacing: 0

            // Min
            RowLayout {
                Layout.fillWidth: true; spacing: 4
                Text { text: "Min"; font.pixelSize: 9; color: ThemeManager.textColor; opacity: 0.5; Layout.preferredWidth: 24 }
                CustomSlider {
                    id: minSlider
                    Layout.fillWidth: true; Layout.preferredHeight: 32
                    from: -10000; to: 10000
                    value: behaviourObject ? behaviourObject.rangeMin : 0
                    textColor: ThemeManager.textColor
                    color: ThemeManager.primaryColor
                    onValueChanged: if (behaviourObject) behaviourObject.setRangeMin(value)
                }
            }

            // Max
            RowLayout {
                Layout.fillWidth: true; spacing: 4
                Text { text: "Max"; font.pixelSize: 9; color: ThemeManager.textColor; opacity: 0.5; Layout.preferredWidth: 24 }
                CustomSlider {
                    id: maxSlider
                    Layout.fillWidth: true; Layout.preferredHeight: 32
                    from: minSlider.value; to: minSlider.value + 20000
                    value: behaviourObject ? behaviourObject.rangeMax : 100
                    textColor: ThemeManager.textColor
                    color: ThemeManager.primaryColor
                    onValueChanged: if (behaviourObject) behaviourObject.setRangeMax(value)
                }
            }
        }

        // ── Gaussian: Mean & StdDev ──────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            visible: behaviourObject && behaviourObject.mode === 2
            spacing: 0

            RowLayout {
                Layout.fillWidth: true; spacing: 4
                Text { text: "μ"; font.pixelSize: 11; color: ThemeManager.textColor; opacity: 0.5; Layout.preferredWidth: 24 }
                CustomSlider {
                    Layout.fillWidth: true; Layout.preferredHeight: 32
                    from: -1000; to: 1000
                    value: behaviourObject ? behaviourObject.mean : 50
                    textColor: ThemeManager.textColor
                    color: "#7C4DFF"
                    onValueChanged: if (behaviourObject) behaviourObject.setMean(value)
                }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 4
                Text { text: "σ"; font.pixelSize: 11; color: ThemeManager.textColor; opacity: 0.5; Layout.preferredWidth: 24 }
                CustomSlider {
                    Layout.fillWidth: true; Layout.preferredHeight: 32
                    from: 1; to: 500
                    value: behaviourObject ? behaviourObject.stddev : 15
                    textColor: ThemeManager.textColor
                    color: "#7C4DFF"
                    onValueChanged: if (behaviourObject) behaviourObject.setStddev(value)
                }
            }
        }

        // ── Dice: Count & Sides ──────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            visible: behaviourObject && behaviourObject.mode === 3
            spacing: 2

            // Visual dice display
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: behaviourObject ? behaviourObject.diceCount + "d" + behaviourObject.diceSides : "1d6"
                font.pixelSize: 16; font.bold: true
                color: "#FF6D00"
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 4
                Text { text: "×"; font.pixelSize: 10; color: ThemeManager.textColor; opacity: 0.5; Layout.preferredWidth: 24 }
                CustomSlider {
                    Layout.fillWidth: true; Layout.preferredHeight: 32
                    from: 1; to: 20
                    value: behaviourObject ? behaviourObject.diceCount : 1
                    textColor: ThemeManager.textColor
                    color: "#FF6D00"
                    onValueChanged: if (behaviourObject) behaviourObject.setDiceCount(Math.round(value))
                }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 4
                Text { text: "d"; font.pixelSize: 10; color: ThemeManager.textColor; opacity: 0.5; Layout.preferredWidth: 24 }
                CustomSlider {
                    Layout.fillWidth: true; Layout.preferredHeight: 32
                    from: 2; to: 100
                    value: behaviourObject ? behaviourObject.diceSides : 6
                    textColor: ThemeManager.textColor
                    color: "#FF6D00"
                    onValueChanged: if (behaviourObject) behaviourObject.setDiceSides(Math.round(value))
                }
            }
        }

        // ── Boolean: Probability ─────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            visible: behaviourObject && behaviourObject.mode === 4
            spacing: 2

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: behaviourObject ? (behaviourObject.probability * 100).toFixed(0) + "% true" : "50%"
                font.pixelSize: 14; font.bold: true
                color: behaviourObject && behaviourObject.lastValue ? "#00C853" : "#FF1744"
            }

            RowLayout {
                Layout.fillWidth: true; spacing: 4
                Text { text: "P"; font.pixelSize: 10; color: ThemeManager.textColor; opacity: 0.5; Layout.preferredWidth: 24 }
                CustomSlider {
                    Layout.fillWidth: true; Layout.preferredHeight: 32
                    from: 0; to: 100
                    value: behaviourObject ? behaviourObject.probability * 100 : 50
                    textColor: ThemeManager.textColor
                    color: "#00C853"
                    onValueChanged: if (behaviourObject) behaviourObject.setProbability(value / 100.0)
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // PRECISION (all modes except Bool & Dice)
        // ═══════════════════════════════════════════════════════════════════
        RowLayout {
            Layout.fillWidth: true; spacing: 4
            visible: behaviourObject && behaviourObject.mode !== 3 && behaviourObject.mode !== 4

            Text { text: ".0"; font.pixelSize: 9; color: ThemeManager.textColor; opacity: 0.5; Layout.preferredWidth: 24 }
            CustomSlider {
                Layout.fillWidth: true; Layout.preferredHeight: 32
                from: 0; to: 8
                value: behaviourObject ? behaviourObject.precision : 2
                textColor: ThemeManager.textColor
                color: ThemeManager.textColor
                prefix: " dec"
                onValueChanged: if (behaviourObject) behaviourObject.setPrecision(Math.round(value))
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // INTERVAL
        // ═══════════════════════════════════════════════════════════════════
        RowLayout {
            Layout.fillWidth: true; spacing: 4
            Text { text: "⏱"; font.pixelSize: 10; Layout.preferredWidth: 24 }
            CustomSlider {
                id: intervalSlider
                Layout.fillWidth: true; Layout.preferredHeight: 32
                from: 10; to: 5000
                value: 500
                textColor: ThemeManager.textColor
                color: ThemeManager.textColor
                prefix: "ms"
            }
        }

        // ═══════════════════════════════════════════════════════════════════
        // CONTROL BUTTONS
        // ═══════════════════════════════════════════════════════════════════
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            // Start / Stop
            NewButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                variant: "filled"
                text: autoTimer.running ? "■ Stop" : "▶ Auto"
                backgroundColor: autoTimer.running ? ThemeManager.dangerColor : ThemeManager.primaryColor

                onClicked: {
                    if (autoTimer.running) autoTimer.stop()
                    else autoTimer.start()
                }
            }

            // Step (single shot)
            NewButton {
                Layout.preferredWidth: 56
                Layout.preferredHeight: 32
                variant: "outlined"
                text: "Step"
                backgroundColor: ThemeManager.primaryColor
                onClicked: behaviourObject.generate()
            }
        }
    }
}
