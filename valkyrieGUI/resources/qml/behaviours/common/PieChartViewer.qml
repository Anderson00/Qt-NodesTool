import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtCharts 2.15
import App.Theme 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    property bool  donut:      false
    property bool  showLabels: true
    property int   explodedSlice: -1

    readonly property var palette: [
        "#e74c3c","#f39c12","#2ecc71","#3498db",
        "#9b59b6","#1abc9c","#e67e22","#ec407a",
        "#00bcd4","#8bc34a","#ff5722","#607d8b"
    ]

    function addSlice(label, value) {
        var slice = pieSeries.append(label, value)
        slice.color = palette[pieSeries.count % palette.length]
        slice.labelVisible = showLabels
        slice.borderColor = "transparent"
    }

    function removeSlice(idx) {
        if (idx >= 0 && idx < pieSeries.count)
            pieSeries.remove(pieSeries.at(idx))
    }

    function clearSlices() {
        pieSeries.clear()
    }

    function setSliceValue(idx, val) {
        if (idx >= 0 && idx < pieSeries.count)
            pieSeries.at(idx).value = val
    }

    Connections {
        target: behaviourObject
        function onInternalAddSlice(label, value) { addSlice(label, value) }
        function onInternalSetSliceValue(idx, val) { setSliceValue(idx, val) }
        function onInternalClearSlices()            { clearSlices() }
        function onInternalRemoveSlice(idx)         { removeSlice(idx) }
    }

    Component.onCompleted: {
        addSlice("A", 42)
        addSlice("B", 28)
        addSlice("C", 20)
        addSlice("D", 10)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Toolbar ────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 34
            color: ThemeManager.surfaceColor

            RowLayout {
                anchors { fill: parent; leftMargin: 6; rightMargin: 6 } spacing: 2

                Text {
                    text: "Pie Chart"; color: ThemeManager.textColor
                    font.pixelSize: 11; font.bold: true; Layout.rightMargin: 4
                }

                component TBBtn: Rectangle {
                    id: btn_
                    property string tip: ""; property string lbl: ""; property bool active: false
                    signal clicked()
                    Layout.preferredWidth: 28; Layout.preferredHeight: 26; radius: 4
                    color: bm.containsMouse ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.2)
                                            : (active ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.14) : "transparent")
                    border.color: active ? ThemeManager.primaryColor : "transparent"; border.width: 1
                    Text { anchors.centerIn: parent; text: btn_.lbl; font.pixelSize: 12
                        color: btn_.active ? ThemeManager.primaryColor : ThemeManager.textSecondaryColor }
                    AppToolTip { text: tip; visible: bm.containsMouse && tip !== ""; delay: 700 }
                    MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: btn_.clicked() }
                }

                TBBtn { tip: "Toggle Donut"; lbl: "◎"; active: donut; onClicked: {
                    donut = !donut; pieSeries.holeSize = donut ? 0.45 : 0 } }
                TBBtn { tip: "Toggle Labels"; lbl: "☰"; active: showLabels; onClicked: {
                    showLabels = !showLabels
                    for (var i = 0; i < pieSeries.count; i++) pieSeries.at(i).labelVisible = showLabels
                } }

                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 22; Layout.leftMargin: 2; Layout.rightMargin: 2; color: ThemeManager.borderColor; opacity: 0.5 }

                TBBtn { tip: "Clear All"; lbl: "✕"; onClicked: clearSlices() }

                Item { Layout.fillWidth: true }

                Text {
                    text: pieSeries.count + " slices"
                    color: ThemeManager.textSecondaryColor; font.pixelSize: 10
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        // ── Chart ──────────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true

            ChartView {
                id: chart
                anchors.fill: parent
                antialiasing: true
                backgroundColor: ThemeManager.backgroundColor
                legend.visible: true
                legend.alignment: Qt.AlignRight
                legend.color: ThemeManager.backgroundColor
                legend.labelColor: ThemeManager.textColor
                legend.font.pixelSize: 10
                margins.left: 0; margins.right: 0; margins.top: 4; margins.bottom: 0
                animationOptions: ChartView.AllAnimations

                PieSeries {
                    id: pieSeries
                    holeSize: 0
                    size: 0.85

                    onClicked: function(slice) {
                        var idx = -1
                        for (var i = 0; i < pieSeries.count; i++) {
                            if (pieSeries.at(i) === slice) { idx = i; break }
                        }
                        if (explodedSlice === idx) {
                            slice.exploded = false
                            explodedSlice = -1
                        } else {
                            if (explodedSlice >= 0 && explodedSlice < pieSeries.count)
                                pieSeries.at(explodedSlice).exploded = false
                            slice.exploded = true
                            explodedSlice = idx
                        }
                    }
                }
            }
        }

        // ── Add slice row ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 38
            color: Qt.rgba(ThemeManager.surfaceColor.r, ThemeManager.surfaceColor.g, ThemeManager.surfaceColor.b, 0.8)

            RowLayout {
                anchors { fill: parent; leftMargin: 6; rightMargin: 6; topMargin: 4; bottomMargin: 4 }
                spacing: 4

                Rectangle {
                    Layout.fillWidth: true; Layout.fillHeight: true; radius: 4
                    color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.05)
                    border.width: 1; border.color: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.3)
                    TextInput {
                        id: newLabel
                        anchors { fill: parent; leftMargin: 6; rightMargin: 6 }
                        verticalAlignment: TextInput.AlignVCenter
                        font.pixelSize: 11; color: ThemeManager.textColor
                        placeholderText: "Label"; selectByMouse: true
                    }
                }

                NumericInputField {
                    id: newValue
                    Layout.preferredWidth: 90; implicitHeight: 30
                    value: 10; from: 0; to: 1e9; stepSize: 1; decimals: 1
                    accentColor: ThemeManager.primaryColor
                }

                NewButton {
                    Layout.preferredWidth: 40; Layout.fillHeight: true
                    variant: "filled"; text: "+"
                    backgroundColor: ThemeManager.primaryColor
                    onClicked: {
                        var lbl = newLabel.text.trim() || ("S" + (pieSeries.count + 1))
                        addSlice(lbl, newValue.value)
                        newLabel.text = ""
                    }
                }
            }
        }
    }
}
