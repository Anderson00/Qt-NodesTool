import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0

// Pagination — page navigation control: < 1 2 3 … n >
//
// Usage:
//   Pagination {
//       currentPage: 1
//       totalPages:  20
//       onPageChanged: function(p) { myList.loadPage(p) }
//   }
Item {
    id: root

    property int    currentPage:  1
    property int    totalPages:   1
    property int    maxVisible:   7     // max page buttons shown (odd recommended)
    property color  accentColor:  ThemeManager.primaryColor
    property color  textColor:    ThemeManager.textColor
    property color  borderColor:  ThemeManager.borderColor
    property color  hoverColor:   Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.12)
    property int    btnSize:      32
    property int    fontSize:     13
    property int    radius:       6

    signal pageChanged(int page)

    implicitWidth: row.implicitWidth
    implicitHeight: root.btnSize

    // Build array of page numbers with -1 meaning ellipsis
    readonly property var _pages: {
        var total = root.totalPages, cur = root.currentPage, max = root.maxVisible
        if (total <= max) {
            var arr = []
            for (var i = 1; i <= total; i++) arr.push(i)
            return arr
        }
        // Always show first, last, current-1, current, current+1 + ellipsis
        var half = Math.floor((max - 4) / 2)   // pages around current
        var left = cur - half, right = cur + half
        if (left < 2) { right += (2 - left); left = 2 }
        if (right > total - 1) { left -= (right - (total - 1)); right = total - 1 }
        left  = Math.max(left, 2)
        right = Math.min(right, total - 1)
        var out = [1]
        if (left > 2)            out.push(-1)
        for (var p = left; p <= right; p++) out.push(p)
        if (right < total - 1)   out.push(-1)
        out.push(total)
        return out
    }

    function _go(p) {
        if (p < 1 || p > root.totalPages || p === root.currentPage) return
        root.currentPage = p
        root.pageChanged(p)
    }

    Row {
        id: row
        spacing: 4

        // ← Prev
        NavBtn {
            label: "‹"; enabled: root.currentPage > 1
            accentColor: root.accentColor; hoverColor: root.hoverColor
            borderColor: root.borderColor; textColor: root.textColor
            btnSize: root.btnSize; fontSize: root.fontSize + 2; radius: root.radius
            onClicked: root._go(root.currentPage - 1)
        }

        // Page buttons
        Repeater {
            model: root._pages
            delegate: Item {
                width: modelData === -1 ? root.btnSize * 0.75 : root.btnSize
                height: root.btnSize

                // Ellipsis
                Text {
                    visible: modelData === -1
                    anchors.centerIn: parent
                    text: "…"; color: root.textColor; font.pixelSize: root.fontSize
                }

                // Page button
                Rectangle {
                    visible: modelData !== -1
                    anchors.fill: parent; radius: root.radius
                    color: modelData === root.currentPage ? root.accentColor : (pageMa.containsMouse ? root.hoverColor : "transparent")
                    border.color: modelData === root.currentPage ? root.accentColor : root.borderColor; border.width: 1
                    Behavior on color { ColorAnimation { duration: 80 } }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.toString()
                        font.pixelSize: root.fontSize
                        color: modelData === root.currentPage ? "#FFFFFF" : root.textColor
                        font.bold: modelData === root.currentPage
                    }

                    MouseArea {
                        id: pageMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: root._go(modelData)
                    }
                }
            }
        }

        // → Next
        NavBtn {
            label: "›"; enabled: root.currentPage < root.totalPages
            accentColor: root.accentColor; hoverColor: root.hoverColor
            borderColor: root.borderColor; textColor: root.textColor
            btnSize: root.btnSize; fontSize: root.fontSize + 2; radius: root.radius
            onClicked: root._go(root.currentPage + 1)
        }
    }

    // Internal reusable nav button
    component NavBtn: Rectangle {
        property string label: ""
        property bool   enabled: true
        property color  accentColor
        property color  hoverColor
        property color  borderColor
        property color  textColor
        property int    btnSize: 32
        property int    fontSize: 15
        signal clicked()

        width: btnSize; height: btnSize; radius: 6
        color: ma.containsMouse && enabled ? hoverColor : "transparent"
        border.color: borderColor; border.width: 1
        opacity: enabled ? 1.0 : 0.35
        Behavior on color { ColorAnimation { duration: 80 } }

        Text { anchors.centerIn: parent; text: label; font.pixelSize: fontSize; color: textColor }

        MouseArea {
            id: ma; anchors.fill: parent; hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (enabled) parent.clicked()
        }
    }
}

