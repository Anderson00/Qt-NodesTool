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

    property var    tableHeaders: []
    property var    tableRows:    []
    property string filterStr:    ""
    property int    sortCol:      -1
    property bool   sortAsc:      true

    // Filtered + sorted rows as indices into tableRows
    property var visibleRows: []

    function rebuildVisible() {
        var result = []
        for (var i = 0; i < tableRows.length; i++) {
            var row = tableRows[i]
            if (filterStr !== "") {
                var match = false
                for (var c = 0; c < row.length; c++) {
                    if (String(row[c]).toLowerCase().indexOf(filterStr.toLowerCase()) >= 0) {
                        match = true
                        break
                    }
                }
                if (!match) continue
            }
            result.push(i)
        }
        if (sortCol >= 0) {
            var sc = sortCol
            var sa = sortAsc
            result.sort(function(a, b) {
                var va = String(tableRows[a][sc] !== undefined ? tableRows[a][sc] : "")
                var vb = String(tableRows[b][sc] !== undefined ? tableRows[b][sc] : "")
                var na = parseFloat(va), nb = parseFloat(vb)
                if (!isNaN(na) && !isNaN(nb)) return sa ? na - nb : nb - na
                return sa ? va.localeCompare(vb) : vb.localeCompare(va)
            })
        }
        visibleRows = result
    }

    onFilterStrChanged: rebuildVisible()
    onSortColChanged:   rebuildVisible()
    onSortAscChanged:   rebuildVisible()
    onTableRowsChanged: rebuildVisible()

    Connections {
        target: behaviourObject

        function onInternalSetHeaders(headers) {
            tableHeaders = headers.slice()
            rebuildVisible()
        }

        function onInternalAddRow(row) {
            var arr = tableRows.slice()
            arr.push(row.slice !== undefined ? row.slice() : row)
            tableRows = arr
        }

        function onInternalClear() {
            tableHeaders = []
            tableRows    = []
            visibleRows  = []
        }

        function onInternalRemoveRow(index) {
            var arr = tableRows.slice()
            arr.splice(index, 1)
            tableRows = arr
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Toolbar ────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 34
            color: ThemeManager.surfaceColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 4

                Text {
                    text: qsTr("Data Table")
                    color: ThemeManager.textColor
                    font.pixelSize: 11
                    font.bold: true
                }

                Text {
                    text: visibleRows.length + " / " + tableRows.length + " rows"
                    color: ThemeManager.textSecondaryColor
                    font.pixelSize: 9
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                // CSV Export
                NewButton {
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 24
                    variant: "outlined"
                    text: qsTr("CSV")
                    onClicked: {
                        var lines = []
                        if (tableHeaders.length > 0)
                            lines.push(tableHeaders.join(","))
                        for (var i = 0; i < tableRows.length; i++)
                            lines.push(tableRows[i].join(","))
                        console.log(lines.join("\n"))
                    }
                }

                // Clear button
                NewButton {
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 24
                    variant: "outlined"
                    text: qsTr("Clear")
                    onClicked: { if (behaviourObject) behaviourObject.clear() }
                }
            }
        }

        // ── Filter row ─────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 34
            color: Qt.rgba(ThemeManager.surfaceColor.r, ThemeManager.surfaceColor.g,
                           ThemeManager.surfaceColor.b, 0.5)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 4

                SvgIcon {
                    source: Icons.magnify
                    color: ThemeManager.textSecondaryColor
                    width: 14; height: 14
                    Layout.alignment: Qt.AlignVCenter
                }

                CustomTextField {
                    id: filterField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Filter rows…")
                    onTextChanged: root.filterStr = text
                }
            }
        }

        // ── Column headers ─────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: tableHeaders.length > 0 ? 26 : 0
            visible: tableHeaders.length > 0
            color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
                           ThemeManager.primaryColor.b, 0.12)

            Row {
                anchors.fill: parent

                Repeater {
                    model: tableHeaders
                    delegate: Rectangle {
                        width: tableHeaders.length > 0
                               ? (parent.parent.width / tableHeaders.length)
                               : 80
                        height: parent.height
                        color: sortCol === index
                               ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
                                         ThemeManager.primaryColor.b, 0.25)
                               : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 4
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: modelData
                                color: ThemeManager.textColor
                                font.pixelSize: 10
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                visible: sortCol === index
                                text: sortAsc ? "▲" : "▼"
                                color: ThemeManager.primaryColor
                                font.pixelSize: 8
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (sortCol === index) {
                                    root.sortAsc = !root.sortAsc
                                } else {
                                    root.sortCol = index
                                    root.sortAsc = true
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Data rows ──────────────────────────────────────────────────────
        ListView {
            id: tableList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: visibleRows.length
            ScrollBar.vertical: ScrollBar {}

            delegate: Rectangle {
                width: tableList.width
                height: 26
                color: (mouseArea.containsMouse)
                       ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
                                 ThemeManager.primaryColor.b, 0.12)
                       : (index % 2 === 0
                          ? Qt.rgba(ThemeManager.surfaceColor.r, ThemeManager.surfaceColor.g,
                                    ThemeManager.surfaceColor.b, 0.3)
                          : "transparent")

                property int    rowIdx:  visibleRows[index]
                property var    rowData: tableRows[rowIdx] !== undefined ? tableRows[rowIdx] : []

                Row {
                    anchors.fill: parent

                    Repeater {
                        model: tableHeaders.length > 0
                               ? tableHeaders.length
                               : (rowData.length > 0 ? rowData.length : 0)

                        delegate: Item {
                            width: (tableHeaders.length > 0 ? tableHeaders.length : rowData.length) > 0
                                   ? (parent.parent.width / (tableHeaders.length > 0 ? tableHeaders.length : rowData.length))
                                   : 80
                            height: parent.height

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 6
                                anchors.rightMargin: 4
                                text: rowData[index] !== undefined ? String(rowData[index]) : ""
                                color: ThemeManager.textColor
                                font.pixelSize: 10
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var cellVal = rowData[index] !== undefined
                                                  ? String(rowData[index]) : ""
                                    if (behaviourObject)
                                        behaviourObject.cellClicked(rowIdx, index, cellVal)
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (behaviourObject)
                            behaviourObject.rowClicked(rowIdx, rowData)
                    }
                }
            }
        }

        // ── Empty state ────────────────────────────────────────────────────
        Rectangle {
            visible: tableRows.length === 0
            Layout.fillWidth: true
            height: 40
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: qsTr("No data — send rows via addRow()")
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 10
            }
        }
    }
}
