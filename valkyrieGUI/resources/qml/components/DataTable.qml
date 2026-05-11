import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import App.Theme 1.0

// DataTable — sortable, scrollable table with fixed headers.
//
// Usage:
//   DataTable {
//       columns: [
//           { key: "name",  label: "Name",  width: 160 },
//           { key: "value", label: "Value", width: 80  }
//       ]
//       rows: [
//           { name: "Alpha", value: 42 },
//           { name: "Beta",  value: 3.14 }
//       ]
//   }
Item {
    id: root

    property var    columns:      []   // { key, label, width?, sortable? }
    property var    rows:         []
    property int    rowHeight:    34
    property int    headerHeight: 36
    property bool   striped:      true
    property bool   sortable:     true
    property color  headerColor:  Qt.darker(ThemeManager.backgroundColor, 1.4)
    property color  evenColor:    Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.03)
    property color  hoverColor:   Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.07)
    property color  borderColor:  Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.3)
    property int    fontSize:     12

    property string _sortKey: ""
    property bool   _sortAsc: true

    readonly property var _sorted: {
        if (!root._sortKey) return root.rows
        var arr = root.rows.slice()
        arr.sort(function(a, b) {
            var va = a[root._sortKey], vb = b[root._sortKey]
            if (va < vb) return root._sortAsc ? -1 : 1
            if (va > vb) return root._sortAsc ?  1 : -1
            return 0
        })
        return arr
    }

    function _cw(col) { return col.width !== undefined ? col.width : 120 }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: root.borderColor; border.width: 1; radius: 4; clip: true

        // ── Header ─────────────────────────────────────────────────────────────
        Rectangle {
            id: hdr
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: root.headerHeight; color: root.headerColor; z: 2

            Row {
                anchors.fill: parent
                Repeater {
                    model: root.columns
                    delegate: Rectangle {
                        width: root._cw(modelData); height: root.headerHeight; color: "transparent"
                        Rectangle {
                            visible: index < root.columns.length - 1
                            anchors.right: parent.right; width: 1; height: parent.height; color: root.borderColor
                        }
                        RowLayout {
                            anchors { fill: parent; leftMargin: 10; rightMargin: 8 } spacing: 4
                            Text {
                                Layout.fillWidth: true
                                text: modelData.label !== undefined ? modelData.label : modelData.key
                                font.pixelSize: root.fontSize; font.bold: true
                                color: ThemeManager.textColor; elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }
                            Text {
                                visible: root.sortable && root._sortKey === modelData.key
                                text: root._sortAsc ? "↑" : "↓"
                                font.pixelSize: root.fontSize; color: ThemeManager.primaryColor
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: root.sortable && (modelData.sortable !== false)
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root._sortKey === modelData.key) root._sortAsc = !root._sortAsc
                                else { root._sortKey = modelData.key; root._sortAsc = true }
                            }
                        }
                    }
                }
            }
            Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: root.borderColor }
        }

        // ── Body ───────────────────────────────────────────────────────────────
        ListView {
            anchors { top: hdr.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
            clip: true
            model: root._sorted
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: Rectangle {
                property var rd: root._sorted[index]
                width: ListView.view.width; height: root.rowHeight
                color: rowMa.containsMouse
                       ? root.hoverColor
                       : (root.striped && index % 2 === 0 ? root.evenColor : "transparent")
                Behavior on color { ColorAnimation { duration: 80 } }
                Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: root.borderColor; opacity: 0.5 }
                MouseArea { id: rowMa; anchors.fill: parent; hoverEnabled: true }

                Row {
                    anchors.fill: parent
                    Repeater {
                        model: root.columns
                        delegate: Item {
                            width: root._cw(modelData); height: parent.height
                            Rectangle {
                                visible: index < root.columns.length - 1
                                anchors.right: parent.right; width: 1; height: parent.height; color: root.borderColor
                            }
                            Text {
                                anchors { left: parent.left; right: parent.right; leftMargin: 10; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                text: {
                                    var v = rd ? rd[modelData.key] : ""
                                    return v !== undefined && v !== null ? v.toString() : ""
                                }
                                font.pixelSize: root.fontSize; color: ThemeManager.textColor
                                elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
            }
        }
    }
}
