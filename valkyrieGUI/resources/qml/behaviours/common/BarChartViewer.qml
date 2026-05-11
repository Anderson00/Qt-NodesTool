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

    property bool horizontal: false
    property bool stacked:    false
    property bool showValues: false
    property int  statsRev:   0

    readonly property var palette: [
        "#3498db","#e74c3c","#2ecc71","#f39c12",
        "#9b59b6","#1abc9c","#e67e22","#ec407a"
    ]

    // barSets[i] = { set: BarSet, values: [] }
    property var barSets: []

    function addSet(name) {
        var bs = barSeries.append(name, [])
        bs.color = palette[barSets.length % palette.length]
        bs.labelColor = ThemeManager.textColor
        bs.borderColor = "transparent"
        barSets.push({ set: bs, values: [] })
    }

    function appendToSet(setIdx, value) {
        if (setIdx < 0 || setIdx >= barSets.length) return
        var entry = barSets[setIdx]
        entry.values.push(value)
        var vals = entry.values.slice()
        entry.set.remove(0, entry.set.count)
        for (var i = 0; i < vals.length; i++) entry.set.append(vals[i])
        axisY.max = Math.max(axisY.max, value * 1.15)
        statsRev++
    }

    function clearAll() {
        for (var i = 0; i < barSets.length; i++) {
            barSets[i].values = []
            barSets[i].set.remove(0, barSets[i].set.count)
        }
        axisY.min = 0; axisY.max = 10
        statsRev++
    }

    Connections {
        target: behaviourObject
        function onInternalAppendToSet(idx, val)  { appendToSet(idx, val) }
        function onInternalClearChart()            { clearAll() }
        function onInternalAddSet(name)            { addSet(name) }
    }

    Component.onCompleted: {
        addSet("Set A")
        addSet("Set B")
        appendToSet(0, 42); appendToSet(0, 28); appendToSet(0, 65)
        appendToSet(1, 18); appendToSet(1, 44); appendToSet(1, 31)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Toolbar ────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 34
            color: ThemeManager.surfaceColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6; anchors.rightMargin: 6
                spacing: 2

                Text { text: "Bar Chart"; color: ThemeManager.textColor; font.pixelSize: 11; font.bold: true; Layout.rightMargin: 4 }

                component TBBtn: Rectangle {
                    id: tb
                    property string tip: ""; property string lbl: ""; property bool active: false
                    signal clicked()
                    Layout.preferredWidth: 28; Layout.preferredHeight: 26; radius: 4
                    color: tbm.containsMouse ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.2)
                                             : (active ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.14) : "transparent")
                    border.color: active ? ThemeManager.primaryColor : "transparent"; border.width: 1
                    Text { anchors.centerIn: parent; text: tb.lbl; font.pixelSize: 11; color: tb.active ? ThemeManager.primaryColor : ThemeManager.textSecondaryColor }
                    AppToolTip { text: tip; visible: tbm.containsMouse && tip !== ""; delay: 700 }
                    MouseArea { id: tbm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tb.clicked() }
                }

                TBBtn { tip: "Horizontal"; lbl: "⇄"; active: horizontal; onClicked: {
                    horizontal = !horizontal
                    chart.removeAllSeries()
                    barSets = []
                    // rebuild
                } }
                TBBtn { tip: "Stacked"; lbl: "⊞"; active: stacked; onClicked: { stacked = !stacked } }
                TBBtn { tip: "Show Values"; lbl: "#"; active: showValues; onClicked: {
                    showValues = !showValues
                    barSeries.labelsVisible = showValues
                } }

                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 22; Layout.leftMargin: 2; Layout.rightMargin: 2; color: ThemeManager.borderColor; opacity: 0.5 }

                TBBtn { tip: "Clear"; lbl: "✕"; onClicked: clearAll() }

                Item { Layout.fillWidth: true }

                Text {
                    text: {
                        statsRev
                        var n = 0
                        for (var i = 0; i < barSets.length; i++) n += barSets[i].values.length
                        return n + " pts"
                    }
                    color: ThemeManager.textSecondaryColor; font.pixelSize: 10
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        // ── Chart ──────────────────────────────────────────────────────────
        ChartView {
            id: chart
            Layout.fillWidth: true; Layout.fillHeight: true
            antialiasing: true
            backgroundColor: ThemeManager.backgroundColor
            legend.visible: true; legend.alignment: Qt.AlignBottom
            legend.color: ThemeManager.backgroundColor; legend.labelColor: ThemeManager.textColor
            legend.font.pixelSize: 10
            margins.left: 0; margins.right: 6; margins.top: 4; margins.bottom: 0
            animationOptions: ChartView.SeriesAnimations

            BarSeries {
                id: barSeries
                axisX: BarCategoryAxis {
                    id: axisX
                    labelsColor: ThemeManager.textSecondaryColor
                    gridLineColor: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.3)
                    color: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.7)
                    labelsFont.pixelSize: 10
                }
                axisY: ValueAxis {
                    id: axisY
                    min: 0; max: 100; tickCount: 6; labelFormat: "%.1f"
                    labelsColor: ThemeManager.textSecondaryColor
                    gridLineColor: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.3)
                    color: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.7)
                    minorGridVisible: false; labelsFont.pixelSize: 10
                }
            }
        }

        // ── Append row ─────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 38
            color: Qt.rgba(ThemeManager.surfaceColor.r, ThemeManager.surfaceColor.g, ThemeManager.surfaceColor.b, 0.8)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6; anchors.rightMargin: 6
                anchors.topMargin: 4; anchors.bottomMargin: 4
                spacing: 4

                Text { text: "Set"; font.pixelSize: 9; color: ThemeManager.textSecondaryColor; Layout.alignment: Qt.AlignVCenter }

                NumberSpinBox {
                    id: setIdx; Layout.preferredWidth: 70
                    from: 0; to: Math.max(0, barSets.length - 1); stepSize: 1; value: 0
                    accentColor: ThemeManager.primaryColor
                }

                NumericInputField {
                    id: appendVal
                    Layout.fillWidth: true; implicitHeight: 30
                    value: 0; from: -1e9; to: 1e9; stepSize: 1; decimals: 1
                    accentColor: ThemeManager.primaryColor
                }

                NewButton {
                    Layout.preferredWidth: 40; Layout.fillHeight: true
                    variant: "filled"; text: "+"
                    backgroundColor: ThemeManager.primaryColor
                    onClicked: appendToSet(setIdx.value, appendVal.value)
                }
            }
        }
    }
}
