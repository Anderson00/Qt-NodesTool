import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import App.Theme 1.0

// ─── CalendarView ──────────────────────────────────────────────────────────────
// Full standalone calendar component with month/year navigation, multi-select,
// event markers, and animated month transitions.
//
// Usage:
//   CalendarView {
//       multiSelect: true
//       selectedDates: []        // list<string> ISO date "yyyy-MM-dd"
//       markedDates:   []        // list<string> ISO date — show event dot
//       onSelectionChanged: function(dates) { ... }
//   }
// ──────────────────────────────────────────────────────────────────────────────

Item {
    id: root

    // ── Public API ────────────────────────────────────────────────────────────
    property bool    multiSelect:    false
    property var     selectedDates:  []   // list<string "yyyy-MM-dd">
    property var     markedDates:    []   // list<string "yyyy-MM-dd">  (event dots)
    property color   accentColor:    ThemeManager.primaryColor
    property color   todayRingColor: "#F59E0B"
    property bool    compact:        false  // reduces cell size

    signal selectionChanged(var dates)
    signal monthChanged(var newMonth)  // {year, month1based}

    // ── Internal state ────────────────────────────────────────────────────────
    property int  _viewYear:  new Date().getFullYear()
    property int  _viewMonth: new Date().getMonth()   // 0-based
    property bool _showMonthPicker: false

    implicitWidth:  compact ? 260 : 320
    implicitHeight: compact ? 240 : 310

    // ── Helpers ───────────────────────────────────────────────────────────────
    function _isoDate(y, m, d) {
        return y + "-" + String(m+1).padStart(2,"0") + "-" + String(d).padStart(2,"0")
    }
    function _isSelected(iso) { return selectedDates.indexOf(iso) !== -1 }
    function _isMarked(iso)   { return markedDates.indexOf(iso)   !== -1 }
    function _isToday(iso) {
        var t = new Date();
        return iso === _isoDate(t.getFullYear(), t.getMonth(), t.getDate())
    }
    function _toggleDate(iso) {
        var arr = selectedDates.slice()
        var idx = arr.indexOf(iso)
        if (idx !== -1) arr.splice(idx, 1)
        else {
            if (!multiSelect) arr = [iso]
            else arr.push(iso)
        }
        selectedDates = arr
        selectionChanged(selectedDates)
    }
    function _prevMonth() {
        if (_viewMonth === 0) { _viewMonth = 11; _viewYear-- }
        else _viewMonth--
        monthChanged({year: _viewYear, month: _viewMonth + 1})
    }
    function _nextMonth() {
        if (_viewMonth === 11) { _viewMonth = 0; _viewYear++ }
        else _viewMonth++
        monthChanged({year: _viewYear, month: _viewMonth + 1})
    }
    function _prevYear() { _viewYear--; monthChanged({year: _viewYear, month: _viewMonth + 1}) }
    function _nextYear() { _viewYear++; monthChanged({year: _viewYear, month: _viewMonth + 1}) }

    // ── Month names ───────────────────────────────────────────────────────────
    readonly property var _monthNames: [
        "Janeiro","Fevereiro","Março","Abril","Maio","Junho",
        "Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"
    ]

    // ── Root background ───────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            spacing: 4

            // ── Header ────────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                spacing: 2

                // << year back
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: yyBackArea.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                    Text { anchors.centerIn: parent; text: "«"; color: ThemeManager.textSecondaryColor; font.pixelSize: 11 }
                    MouseArea { id: yyBackArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root._prevYear() }
                }
                // < month back
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: mBackArea.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                    Text { anchors.centerIn: parent; text: "‹"; color: ThemeManager.textColor; font.pixelSize: 16 }
                    MouseArea { id: mBackArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root._prevMonth() }
                }

                // Title — clickable to open month/year picker
                Rectangle {
                    Layout.fillWidth: true; height: 24; radius: 4
                    color: titleArea.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: root._monthNames[root._viewMonth] + " " + root._viewYear
                        color: ThemeManager.textColor
                        font.pixelSize: compact ? 12 : 13
                        font.bold: true
                    }
                    MouseArea { id: titleArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor;
                        onClicked: root._showMonthPicker = !root._showMonthPicker }
                }

                // > month forward
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: mFwdArea.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                    Text { anchors.centerIn: parent; text: "›"; color: ThemeManager.textColor; font.pixelSize: 16 }
                    MouseArea { id: mFwdArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root._nextMonth() }
                }
                // >> year forward
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: yyFwdArea.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                    Text { anchors.centerIn: parent; text: "»"; color: ThemeManager.textSecondaryColor; font.pixelSize: 11 }
                    MouseArea { id: yyFwdArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root._nextYear() }
                }
            }

            // ── Month/Year quick picker (overlay) ─────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                visible: root._showMonthPicker
                height: root._showMonthPicker ? (compact ? 110 : 140) : 0
                color: Qt.rgba(0,0,0,0.55)
                radius: 6
                clip: true

                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4

                    // Year spinner
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Rectangle {
                            width: 22; height: 22; radius: 4
                            color: yBackA.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                            Text { anchors.centerIn: parent; text: "‹"; color: ThemeManager.textColor; font.pixelSize: 14 }
                            MouseArea { id: yBackA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root._viewYear-- }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root._viewYear
                            color: ThemeManager.textColor; font.pixelSize: 14; font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Rectangle {
                            width: 22; height: 22; radius: 4
                            color: yFwdA.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                            Text { anchors.centerIn: parent; text: "›"; color: ThemeManager.textColor; font.pixelSize: 14 }
                            MouseArea { id: yFwdA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root._viewYear++ }
                        }
                    }

                    // Month grid 4×3
                    Grid {
                        Layout.fillWidth: true
                        columns: 4
                        spacing: 3
                        Repeater {
                            model: 12
                            Rectangle {
                                width: (parent.width - 9) / 4
                                height: compact ? 22 : 26
                                radius: 4
                                color: index === root._viewMonth
                                    ? root.accentColor
                                    : (mPickArea.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.04))
                                Text {
                                    anchors.centerIn: parent
                                    text: ["Jan","Fev","Mar","Abr","Mai","Jun",
                                           "Jul","Ago","Set","Out","Nov","Dez"][index]
                                    color: index === root._viewMonth ? "#fff" : ThemeManager.textColor
                                    font.pixelSize: compact ? 10 : 11
                                }
                                MouseArea {
                                    id: mPickArea; anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { root._viewMonth = index; root._showMonthPicker = false }
                                }
                            }
                        }
                    }
                }
            }

            // ── Day-of-week labels ────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 2; Layout.rightMargin: 2
                spacing: 0
                visible: !root._showMonthPicker
                Repeater {
                    model: ["D","S","T","Q","Q","S","S"]
                    Text {
                        Layout.fillWidth: true
                        text: modelData
                        color: Qt.rgba(1,1,1,0.38)
                        font.pixelSize: compact ? 9 : 10
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // ── Day grid ─────────────────────────────────────────────────────
            Grid {
                id: dayGrid
                visible: !root._showMonthPicker
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 2; Layout.rightMargin: 2

                columns: 7
                rowSpacing: compact ? 1 : 2
                columnSpacing: compact ? 1 : 2

                readonly property int firstDay: new Date(root._viewYear, root._viewMonth, 1).getDay()
                readonly property int daysInMonth: new Date(root._viewYear, root._viewMonth + 1, 0).getDate()
                // Previous month overflow days
                readonly property int prevMonthDays: new Date(root._viewYear, root._viewMonth, 0).getDate()

                Repeater {
                    model: 42
                    Item {
                        id: cellRoot
                        property int  dayNum:   index - dayGrid.firstDay + 1
                        property bool inMonth:  dayNum >= 1 && dayNum <= dayGrid.daysInMonth
                        property int  overflowDay: inMonth ? dayNum
                            : (dayNum < 1 ? dayGrid.prevMonthDays + dayNum : dayNum - dayGrid.daysInMonth)
                        property string isoStr:  inMonth ? root._isoDate(root._viewYear, root._viewMonth, dayNum) : ""
                        property bool isSelected: inMonth && root._isSelected(isoStr)
                        property bool isMarked:   inMonth && root._isMarked(isoStr)
                        property bool isToday:    inMonth && root._isToday(isoStr)

                        width:  (dayGrid.width  - 6*dayGrid.columnSpacing) / 7
                        height: (dayGrid.height - 5*dayGrid.rowSpacing)    / 6

                        Rectangle {
                            anchors.centerIn: parent
                            width:  Math.min(parent.width, parent.height) - 2
                            height: width
                            radius: width / 2

                            color: cellRoot.isSelected
                                ? root.accentColor
                                : (cellArea.containsMouse && cellRoot.inMonth
                                   ? Qt.rgba(1,1,1,0.08) : "transparent")

                            // Today ring
                            Rectangle {
                                visible: cellRoot.isToday && !cellRoot.isSelected
                                anchors.fill: parent
                                radius: parent.radius
                                color: "transparent"
                                border.width: 2
                                border.color: root.todayRingColor
                                opacity: 0.85
                            }

                            Text {
                                anchors.centerIn: parent
                                text: cellRoot.inMonth ? cellRoot.dayNum : cellRoot.overflowDay
                                color: cellRoot.isSelected
                                    ? "#ffffff"
                                    : (cellRoot.inMonth ? ThemeManager.textColor : Qt.rgba(1,1,1,0.2))
                                font.pixelSize: compact ? 10 : 12
                                font.bold: cellRoot.isToday
                            }

                            // Event marker dot
                            Rectangle {
                                visible: cellRoot.isMarked
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: compact ? 1 : 2
                                width: compact ? 3 : 4; height: width; radius: width / 2
                                color: cellRoot.isSelected ? "#fff" : root.accentColor
                            }
                        }

                        MouseArea {
                            id: cellArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: cellRoot.inMonth
                            cursorShape: cellRoot.inMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: if (cellRoot.inMonth) root._toggleDate(cellRoot.isoStr)
                        }
                    }
                }
            }
        }
    }
}
