import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import App.Theme 1.0
import App.Icons 1.0

// ─── CalendarView ──────────────────────────────────────────────────────────────
// Full standalone calendar with month/year navigation, multi-select, range-select,
// event markers, animated month transitions, and hover preview for ranges.
//
// Modes (mutually exclusive — rangeSelect takes priority):
//   multiSelect: true          — click to toggle individual dates
//   rangeSelect: true          — first click sets start, second sets end; generates
//                                all dates in the range and emits rangeChanged(s,e)
//
// Usage:
//   CalendarView {
//       rangeSelect: true
//       onRangeChanged: function(start, end) { ... }
//       onSelectionChanged: function(dates) { ... }
//   }
// ──────────────────────────────────────────────────────────────────────────────

Item {
    id: root

    // ── Public API ────────────────────────────────────────────────────────────
    property bool    multiSelect:   false
    property bool    rangeSelect:   false
    property var     selectedDates: []   // list<string "yyyy-MM-dd">
    property var     markedDates:   []   // list<string "yyyy-MM-dd">  (event dots)
    property color   accentColor:   ThemeManager.primaryColor
    property color   todayRingColor:"#F59E0B"
    property bool    compact:       false

    // Range mode — readable/writable from outside
    property string  rangeStart:    ""   // ISO date
    property string  rangeEnd:      ""   // ISO date

    signal selectionChanged(var dates)
    signal monthChanged(var newMonth)   // {year, month1based}
    signal rangeChanged(string start, string end)

    // ── Internal state ────────────────────────────────────────────────────────
    property int    _viewYear:        new Date().getFullYear()
    property int    _viewMonth:       new Date().getMonth()
    property bool   _showMonthPicker: false
    property string _hoverIso:        ""   // for range hover-preview

    implicitWidth:  compact ? 260 : 320
    implicitHeight: compact ? 240 : 310

    // ── Helpers ───────────────────────────────────────────────────────────────
    function _isoDate(y, m, d) {
        return y + "-" + String(m+1).padStart(2,"0") + "-" + String(d).padStart(2,"0")
    }
    function _isSelected(iso)  { return selectedDates.indexOf(iso) !== -1 }
    function _isMarked(iso)    { return markedDates.indexOf(iso)   !== -1 }
    function _isToday(iso) {
        var t = new Date()
        return iso === _isoDate(t.getFullYear(), t.getMonth(), t.getDate())
    }

    // Range helpers — reactive: bindings re-evaluate when rangeStart/rangeEnd/_hoverIso change
    function _isRangeStart(iso) {
        if (!rangeSelect || rangeStart === "") return false
        return iso === rangeStart
    }
    function _isRangeEnd(iso) {
        if (!rangeSelect || rangeEnd === "") return false
        return iso === rangeEnd
    }
    function _isInRange(iso) {
        if (!rangeSelect || rangeStart === "") return false
        // Use confirmed end, or hoverIso as preview end when range is incomplete
        var effectiveEnd = (rangeEnd !== "") ? rangeEnd : _hoverIso
        if (effectiveEnd === "" || effectiveEnd === rangeStart) return false
        var s = rangeStart < effectiveEnd ? rangeStart : effectiveEnd
        var e = rangeStart < effectiveEnd ? effectiveEnd : rangeStart
        return iso > s && iso < e
    }
    function _isPreviewEndpoint(iso) {
        // Hovered date when range is incomplete (not yet confirmed)
        if (!rangeSelect || rangeStart === "" || rangeEnd !== "") return false
        return iso === _hoverIso && _hoverIso !== rangeStart
    }
    function _rangeIsComplete() {
        return rangeSelect && rangeStart !== "" && rangeEnd !== ""
    }

    function _toggleDate(iso) {
        if (rangeSelect) {
            if (rangeStart === "" || rangeEnd !== "") {
                // Start a new range
                rangeStart = iso
                rangeEnd   = ""
                selectedDates = [iso]
                selectionChanged(selectedDates)
            } else if (iso === rangeStart) {
                // Cancel range
                rangeStart = ""
                rangeEnd   = ""
                selectedDates = []
                selectionChanged(selectedDates)
            } else {
                // Complete range
                var s = rangeStart < iso ? rangeStart : iso
                var e = rangeStart < iso ? iso : rangeStart
                rangeStart = s
                rangeEnd   = e
                _hoverIso  = ""
                // Generate every date in [s, e]
                var arr = []
                var d = new Date(s + "T00:00:00")
                var endDate = new Date(e + "T00:00:00")
                while (d <= endDate) {
                    arr.push(root._isoDate(d.getFullYear(), d.getMonth(), d.getDate()))
                    d.setDate(d.getDate() + 1)
                }
                selectedDates = arr
                selectionChanged(selectedDates)
                rangeChanged(s, e)
            }
            return
        }
        // Multi / single toggle
        var arr2 = selectedDates.slice()
        var idx  = arr2.indexOf(iso)
        if (idx !== -1) arr2.splice(idx, 1)
        else {
            if (!multiSelect) arr2 = [iso]
            else arr2.push(iso)
        }
        selectedDates = arr2
        selectionChanged(selectedDates)
    }

    function _prevMonth() {
        if (_viewMonth === 0) { _viewMonth = 11; _viewYear-- } else _viewMonth--
        monthChanged({year: _viewYear, month: _viewMonth + 1})
    }
    function _nextMonth() {
        if (_viewMonth === 11) { _viewMonth = 0; _viewYear++ } else _viewMonth++
        monthChanged({year: _viewYear, month: _viewMonth + 1})
    }
    function _prevYear() { _viewYear--; monthChanged({year: _viewYear, month: _viewMonth + 1}) }
    function _nextYear() { _viewYear++; monthChanged({year: _viewYear, month: _viewMonth + 1}) }

    readonly property var _monthNames: [
        "Janeiro","Fevereiro","Março","Abril","Maio","Junho",
        "Julho","Agosto","Setembro","Outubro","Novembro","Dezembro"
    ]

    // ── Root ──────────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            anchors.fill: parent
            spacing: 4

            // ── Header ────────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 4; Layout.rightMargin: 4
                spacing: 2

                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: yyBackArea.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                    Text { anchors.centerIn: parent; text: qsTr("«"); color: ThemeManager.textSecondaryColor; font.pixelSize: 11 }
                    MouseArea { id: yyBackArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root._prevYear() }
                }
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: mBackArea.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                    Text { anchors.centerIn: parent; text: qsTr("‹"); color: ThemeManager.textColor; font.pixelSize: 16 }
                    MouseArea { id: mBackArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root._prevMonth() }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 24; radius: 4
                    color: titleArea.containsMouse ? Qt.rgba(1,1,1,0.06) : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: root._monthNames[root._viewMonth] + " " + root._viewYear
                        color: ThemeManager.textColor
                        font.pixelSize: compact ? 12 : 13; font.bold: true
                    }
                    MouseArea { id: titleArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root._showMonthPicker = !root._showMonthPicker }
                }

                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: mFwdArea.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                    Text { anchors.centerIn: parent; text: qsTr("›"); color: ThemeManager.textColor; font.pixelSize: 16 }
                    MouseArea { id: mFwdArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root._nextMonth() }
                }
                Rectangle {
                    width: 24; height: 24; radius: 4
                    color: yyFwdArea.containsMouse ? Qt.rgba(1,1,1,0.08) : "transparent"
                    Text { anchors.centerIn: parent; text: qsTr("»"); color: ThemeManager.textSecondaryColor; font.pixelSize: 11 }
                    MouseArea { id: yyFwdArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root._nextYear() }
                }
            }

            // ── Range selection hint ──────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: rangeHintRow.implicitHeight + 8
                visible: root.rangeSelect
                color: root.rangeStart !== "" && root.rangeEnd === ""
                    ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.1)
                    : Qt.rgba(1,1,1,0.03)
                radius: 5
                border.width: 1
                border.color: root.rangeStart !== "" && root.rangeEnd === ""
                    ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.3)
                    : Qt.rgba(1,1,1,0.07)
                Behavior on border.color { ColorAnimation { duration: 200 } }
                Behavior on color        { ColorAnimation { duration: 200 } }

                RowLayout {
                    id: rangeHintRow
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 8 }
                    spacing: 6

                    Text {
                        text: root.rangeStart !== "" && root.rangeEnd === ""
                            ? "Início: " + root.rangeStart
                            : (root.rangeStart !== "" && root.rangeEnd !== ""
                               ? root.rangeStart + " → " + root.rangeEnd
                               : "Clique para selecionar início do intervalo")
                        color: root.rangeStart !== ""
                            ? ThemeManager.primaryColor
                            : Qt.rgba(1,1,1,0.35)
                        font.pixelSize: compact ? 9 : 10
                        Layout.fillWidth: true
                    }

                    // Clear range button
                    Rectangle {
                        visible: root.rangeStart !== ""
                        width: 16; height: 16; radius: 8
                        color: clearA.containsMouse ? Qt.rgba(1,1,1,0.12) : "transparent"
                        SvgIcon { anchors.centerIn: parent; width: 10; height: 10; source: Icons.close; color: Qt.rgba(1,1,1,0.4) }
                        MouseArea {
                            id: clearA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { root.rangeStart = ""; root.rangeEnd = ""; root.selectedDates = []; root.selectionChanged([]) }
                        }
                    }
                }
            }

            // ── Month/Year quick picker ───────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                visible: root._showMonthPicker
                height: root._showMonthPicker ? (compact ? 110 : 140) : 0
                color: Qt.rgba(0,0,0,0.55)
                radius: 6; clip: true
                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 6; spacing: 4

                    RowLayout {
                        Layout.fillWidth: true; spacing: 4
                        Rectangle {
                            width: 22; height: 22; radius: 4
                            color: yBackA.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                            Text { anchors.centerIn: parent; text: qsTr("‹"); color: ThemeManager.textColor; font.pixelSize: 14 }
                            MouseArea { id: yBackA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root._viewYear-- }
                        }
                        Text {
                            Layout.fillWidth: true; text: root._viewYear
                            color: ThemeManager.textColor; font.pixelSize: 14; font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Rectangle {
                            width: 22; height: 22; radius: 4
                            color: yFwdA.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                            Text { anchors.centerIn: parent; text: qsTr("›"); color: ThemeManager.textColor; font.pixelSize: 14 }
                            MouseArea { id: yFwdA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root._viewYear++ }
                        }
                    }

                    Grid {
                        Layout.fillWidth: true; columns: 4; spacing: 3
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
                                    text: ["Jan","Fev","Mar","Abr","Mai","Jun","Jul","Ago","Set","Out","Nov","Dez"][index]
                                    color: index === root._viewMonth ? "#fff" : ThemeManager.textColor
                                    font.pixelSize: compact ? 10 : 11
                                }
                                MouseArea {
                                    id: mPickArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { root._viewMonth = index; root._showMonthPicker = false }
                                }
                            }
                        }
                    }
                }
            }

            // ── Day-of-week labels ────────────────────────────────────────────
            // CRITICAL: spacing must match dayGrid.columnSpacing so labels align with cells
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 2; Layout.rightMargin: 2
                spacing: compact ? 1 : 2    // ← matches Grid.columnSpacing below
                visible: !root._showMonthPicker

                Repeater {
                    model: ["D","S","T","Q","Q","S","S"]
                    Text {
                        Layout.fillWidth: true
                        text: modelData
                        color: Qt.rgba(1,1,1,0.38)
                        font.pixelSize: compact ? 9 : 10; font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            // ── Day grid ──────────────────────────────────────────────────────
            Grid {
                id: dayGrid
                visible: !root._showMonthPicker
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 2; Layout.rightMargin: 2

                columns: 7
                rowSpacing:    compact ? 1 : 2
                columnSpacing: compact ? 1 : 2

                readonly property int firstDay:      new Date(root._viewYear, root._viewMonth, 1).getDay()
                readonly property int daysInMonth:   new Date(root._viewYear, root._viewMonth + 1, 0).getDate()
                readonly property int prevMonthDays: new Date(root._viewYear, root._viewMonth, 0).getDate()

                Repeater {
                    model: 42

                    Item {
                        id: cellRoot

                        property int    dayNum:     index - dayGrid.firstDay + 1
                        property bool   inMonth:    dayNum >= 1 && dayNum <= dayGrid.daysInMonth
                        property int    overflowDay:inMonth ? dayNum
                                                    : (dayNum < 1
                                                       ? dayGrid.prevMonthDays + dayNum
                                                       : dayNum - dayGrid.daysInMonth)
                        property string isoStr:     inMonth ? root._isoDate(root._viewYear, root._viewMonth, dayNum) : ""

                        property bool isSelected:       inMonth && root._isSelected(isoStr)
                        property bool isMarked:         inMonth && root._isMarked(isoStr)
                        property bool isToday:          inMonth && root._isToday(isoStr)
                        property bool isRangeStart:     inMonth && root._isRangeStart(isoStr)
                        property bool isRangeEnd:       inMonth && root._isRangeEnd(isoStr)
                        property bool isInRange:        inMonth && root._isInRange(isoStr)
                        property bool isPreviewEnd:     inMonth && root._isPreviewEndpoint(isoStr)

                        // A confirmed endpoint = start or end when both are set
                        property bool isConfirmedEndpoint: (isRangeStart || isRangeEnd) && root._rangeIsComplete()

                        width:  (dayGrid.width  - 6 * dayGrid.columnSpacing) / 7
                        height: (dayGrid.height - 5 * dayGrid.rowSpacing)    / 6

                        // ── Range bridge: LEFT half ───────────────────────────
                        // Shown for in-range cells and the range-end cell
                        Rectangle {
                            visible: cellRoot.inMonth &&
                                     (cellRoot.isInRange ||
                                      (cellRoot.isRangeEnd && root._rangeIsComplete())) &&
                                     !cellRoot.isRangeStart
                            anchors.left:           parent.left
                            anchors.right:          parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            height: Math.min(parent.width, parent.height) * 0.76
                            radius: 0
                            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b,
                                           root._rangeIsComplete() ? 0.22 : 0.12)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        // ── Range bridge: RIGHT half ──────────────────────────
                        // Shown for in-range cells and the range-start cell
                        Rectangle {
                            visible: cellRoot.inMonth &&
                                     (cellRoot.isInRange ||
                                      (cellRoot.isRangeStart && root._rangeIsComplete())) &&
                                     !cellRoot.isRangeEnd
                            anchors.left:           parent.horizontalCenter
                            anchors.right:          parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: Math.min(parent.width, parent.height) * 0.76
                            radius: 0
                            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b,
                                           root._rangeIsComplete() ? 0.22 : 0.12)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        // ── Circle highlight ──────────────────────────────────
                        Rectangle {
                            anchors.centerIn: parent
                            width:  Math.min(parent.width, parent.height) - 2
                            height: width
                            radius: width / 2

                            // Solid for confirmed selection/endpoints; ghost for preview
                            property bool solidFill: cellRoot.isSelected ||
                                                     cellRoot.isConfirmedEndpoint
                            property bool ghostFill: cellRoot.isPreviewEnd && !cellRoot.isSelected

                            color: solidFill
                                ? root.accentColor
                                : (ghostFill
                                   ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.45)
                                   : (cellArea.containsMouse && cellRoot.inMonth
                                      ? Qt.rgba(1,1,1,0.08) : "transparent"))
                            Behavior on color { ColorAnimation { duration: 100 } }

                            // Today ring
                            Rectangle {
                                visible: cellRoot.isToday && !cellRoot.isSelected && !cellRoot.isConfirmedEndpoint
                                anchors.fill: parent; radius: parent.radius
                                color: "transparent"
                                border.width: 2; border.color: root.todayRingColor; opacity: 0.85
                            }

                            Text {
                                anchors.centerIn: parent
                                text: cellRoot.inMonth ? cellRoot.dayNum : cellRoot.overflowDay
                                color: (cellRoot.isSelected || cellRoot.isConfirmedEndpoint)
                                    ? "#ffffff"
                                    : (cellRoot.isPreviewEnd
                                       ? "#ffffff"
                                       : (cellRoot.inMonth ? ThemeManager.textColor : Qt.rgba(1,1,1,0.2)))
                                font.pixelSize: compact ? 10 : 12
                                font.bold: cellRoot.isToday
                            }

                            // Event dot
                            Rectangle {
                                visible: cellRoot.isMarked
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: compact ? 1 : 2
                                width: compact ? 3 : 4; height: width; radius: width / 2
                                color: cellRoot.isSelected ? "#fff" : root.accentColor
                            }
                        }

                        // ── Range-start indicator dot (when end not yet set) ──
                        Rectangle {
                            visible: cellRoot.isRangeStart && !root._rangeIsComplete()
                            anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottomMargin: 1
                            width: 4; height: 4; radius: 2
                            color: root.accentColor; opacity: 0.8
                        }

                        MouseArea {
                            id: cellArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: cellRoot.inMonth
                            cursorShape: cellRoot.inMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: if (cellRoot.inMonth) root._toggleDate(cellRoot.isoStr)
                            onEntered: if (cellRoot.inMonth) root._hoverIso = cellRoot.isoStr
                            onExited:  { if (root._hoverIso === cellRoot.isoStr) root._hoverIso = "" }
                        }
                    }
                }
            }
        }
    }
}
