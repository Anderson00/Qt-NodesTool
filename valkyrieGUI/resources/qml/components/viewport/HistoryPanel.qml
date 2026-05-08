import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import App.Theme 1.0
import Qaterial 1.0 as Qaterial

Rectangle {
    id: panel

    property var vp: null
    signal closeRequested()

    // Non-circular height: computed from entry count, not from any anchored child.
    readonly property int _count: vp ? vp.historyCount : 0
    width:  240
    height: Math.min(39 + Math.min(_count * 34 + 12, 334), 400)

    color: Qt.rgba(ThemeManager.backgroundColor.r,
                   ThemeManager.backgroundColor.g,
                   ThemeManager.backgroundColor.b, 0.96)
    radius: 8
    border.width: 1
    border.color: Qt.rgba(ThemeManager.primaryColor.r,
                          ThemeManager.primaryColor.g,
                          ThemeManager.primaryColor.b, 0.45)
    clip: true

    // â”€â”€ Type helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    function _typeColor(text) {
        if (!text || text === "Initial state") return Qt.rgba(ThemeManager.textColor.r,
                                                              ThemeManager.textColor.g,
                                                              ThemeManager.textColor.b, 0.45)
        if (text.indexOf("Move")              !== -1) return "#4A9EF5"
        if (text.indexOf("Resize")            !== -1) return "#9C6AE8"
        if (text.indexOf("Add Node")          !== -1) return "#4CAF50"
        if (text.indexOf("Remove Node")       !== -1) return "#EF5350"
        if (text.indexOf("Add Connection")    !== -1) return "#26C6DA"
        if (text.indexOf("Remove Connection") !== -1) return "#FF9800"
        return Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                       ThemeManager.textColor.b, 0.45)
    }

    function _typeIcon(text) {
        if (!text || text === "Initial state") return Qaterial.Icons.home
        if (text.indexOf("Move")              !== -1) return Qaterial.Icons.cursorMove
        if (text.indexOf("Resize")            !== -1) return Qaterial.Icons.resize
        if (text.indexOf("Add Node")          !== -1) return Qaterial.Icons.plusCircleOutline
        if (text.indexOf("Remove Node")       !== -1) return Qaterial.Icons.closeCircleOutline
        if (text.indexOf("Add Connection")    !== -1) return Qaterial.Icons.link
        if (text.indexOf("Remove Connection") !== -1) return Qaterial.Icons.linkOff
        return Qaterial.Icons.history
    }

    // â”€â”€ Header (38px) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    RowLayout {
        id: headerRow
        anchors.top:   parent.top
        anchors.left:  parent.left
        anchors.right: parent.right
        height: 38
        anchors.leftMargin:  14
        anchors.rightMargin: 4

        Qaterial.ColorIcon {
            source: Qaterial.Icons.history
            color:  ThemeManager.primaryColor
            width: 15; height: 15
        }

        Text {
            text: "Histórico"
            font.pixelSize: 12
            font.bold: true
            color: ThemeManager.textColor
            Layout.leftMargin:  7
            Layout.fillWidth: true
        }

        Text {
            text: vp ? (vp.historyIndex + " / " + (vp.historyCount - 1)) : ""
            font.pixelSize: 9
            color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                           ThemeManager.textColor.b, 0.4)
            Layout.alignment: Qt.AlignVCenter
        }

        Qaterial.AppBarButton {
            icon.source: Qaterial.Icons.close
            icon.color:  ThemeManager.textColor
            opacity: 0.55
            width: 34; height: 34
            onClicked: panel.closeRequested()
        }
    }

    // Divider (1px)
    Rectangle {
        id: topDivider
        anchors.top:   headerRow.bottom
        anchors.left:  parent.left
        anchors.right: parent.right
        height: 1
        color:   ThemeManager.primaryColor
        opacity: 0.18
    }

    // â”€â”€ Entry list â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    // ScrollView fills everything below the header. Height is bounded by
    // panel.height (which is non-circular â€” see _count formula above).
    ScrollView {
        id: scrollView
        anchors.top:    topDivider.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right
        anchors.bottom: parent.bottom
        anchors.topMargin:    4
        anchors.bottomMargin: 4
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy:   ScrollBar.AsNeeded

        ListView {
            id: historyList
            model:   panel._count
            spacing: 1
            clip:    true
            boundsBehavior: Flickable.StopAtBounds

            // Auto-scroll to keep current entry visible after every change.
            Connections {
                target: panel.vp
                function onHistoryChanged() {
                    Qt.callLater(() => {
                        if (panel.vp)
                            historyList.positionViewAtIndex(panel.vp.historyIndex,
                                                            ListView.Contain)
                    })
                }
            }

            delegate: Item {
                id: entryItem
                width:  historyList.width
                height: 34

                readonly property bool   isCurrent: panel.vp !== null && index === panel.vp.historyIndex
                readonly property bool   isFuture:  panel.vp !== null && index >  panel.vp.historyIndex
                readonly property string entryText: panel.vp ? panel.vp.historyText(index) : ""
                readonly property color  dotColor:  panel._typeColor(entryText)
                readonly property string entryIcon: panel._typeIcon(entryText)

                // Row hover / current background
                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: 3; anchors.rightMargin: 3
                    radius: 5
                    color: isCurrent
                           ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
                                     ThemeManager.primaryColor.b, 0.14)
                           : rowMouse.containsMouse
                             ? Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                                       ThemeManager.textColor.b, 0.06)
                             : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                }

                // Timeline connector â€” top half (not drawn on first entry)
                Rectangle {
                    visible: index > 0
                    x: 21; anchors.top: parent.top
                    height: parent.height / 2; width: 2; radius: 1
                    color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                                   ThemeManager.textColor.b, isFuture ? 0.1 : 0.22)
                }
                // Timeline connector â€” bottom half (not drawn on last entry)
                Rectangle {
                    visible: panel.vp && index < panel.vp.historyCount - 1
                    x: 21; anchors.bottom: parent.bottom
                    height: parent.height / 2; width: 2; radius: 1
                    color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                                   ThemeManager.textColor.b,
                                   (index + 1) > panel.vp.historyIndex ? 0.1 : 0.22)
                }

                // Timeline dot
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    x:      isCurrent ? 15 : 18
                    width:  isCurrent ? 14 : 8
                    height: isCurrent ? 14 : 8
                    radius: width / 2
                    color:  isFuture ? "transparent" : dotColor
                    opacity: isFuture ? 0.35 : 1.0
                    border.width: isFuture ? 1.5 : 0
                    border.color: isFuture ? Qt.rgba(dotColor.r, dotColor.g, dotColor.b, 0.5) : "transparent"
                    Behavior on x      { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                    Behavior on width  { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                    Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                    Behavior on color  { ColorAnimation  { duration: 120 } }
                }

                // Type icon
                Qaterial.ColorIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 38
                    source:  entryIcon
                    color:   isCurrent
                             ? ThemeManager.primaryColor
                             : Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                                       ThemeManager.textColor.b, isFuture ? 0.25 : 0.5)
                    width: 13; height: 13
                    Behavior on color { ColorAnimation { duration: 100 } }
                }

                // Entry label
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left:  parent.left
                    anchors.right: currentBadge.left
                    anchors.leftMargin:  56
                    anchors.rightMargin: 4
                    text: entryText === "Initial state" ? "Estado inicial" : entryText
                    font.pixelSize: 11
                    font.bold: isCurrent
                    color: isCurrent
                           ? ThemeManager.textColor
                           : Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                                     ThemeManager.textColor.b, isFuture ? 0.3 : 0.75)
                    elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: 100 } }
                }

                // "atual" badge
                Rectangle {
                    id: currentBadge
                    visible: isCurrent
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 9
                    width:  badgeText.implicitWidth + 10
                    height: 16
                    radius: 3
                    color:   ThemeManager.primaryColor
                    opacity: 0.85

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: "atual"
                        font.pixelSize: 9
                        font.bold: true
                        font.letterSpacing: 0.4
                        color: "white"
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: isCurrent ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: {
                        if (!isCurrent && panel.vp)
                            panel.vp.jumpToHistory(index)
                    }
                }
            }
        }
    }
}
