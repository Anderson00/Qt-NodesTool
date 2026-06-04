import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.0
import App.Theme 1.0
import App.Desktop 1.0
import App.Icons 1.0

import ".."

// Fullscreen overlay showing every virtual desktop as a thumbnail tile.
// Activated via Ctrl+Tab. Click a thumbnail to switch to that desktop.
// Inspired by Windows Task View / macOS Mission Control.
Popup {
    id: root
    modal: true
    dim: true
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    z: 5000

    // The nodes Repeater from ViewPortWindow; used to render real-position
    // mini-previews per desktop. Optional — falls back to a count when null.
    property var nodes: null

    // Bumped to force re-evaluation of the thumbnail bindings when desktops
    // or node positions change while the overview is open.
    property int refreshTick: 0
    onAboutToShow: refreshTick++

    Connections {
        target: DesktopManager
        function onDesktopListChanged()              { root.refreshTick++ }
        function onNodeDesktopMembershipChanged()    { root.refreshTick++ }
        function onPinnedNodesChanged()              { root.refreshTick++ }
    }

    // Fullscreen sizing relative to the parent
    width:  parent ? parent.width  : 800
    height: parent ? parent.height : 600
    x: 0
    y: 0

    background: Rectangle {
        color:  Qt.rgba(0, 0, 0, 0.82)
    }

    Overlay.modal: Rectangle { color: "transparent" }

    contentItem: Item {
        anchors.fill: parent

        // Header
        Column {
            anchors.top:               parent.top
            anchors.horizontalCenter:  parent.horizontalCenter
            anchors.topMargin:         28
            spacing: 6

            Text {
                text: qsTr("Desktops")
                font.pixelSize: 22
                font.bold: true
                color: "white"
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: qsTr("Click a desktop or use Ctrl + 1…") + DesktopManager.desktopCount + "  ·  Esc to dismiss"
                font.pixelSize: 11
                color: "white"
                opacity: 0.55
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        // Tile grid
        Flickable {
            anchors.top:    parent.top
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.bottom: addRow.top
            anchors.topMargin: 100
            anchors.margins: 60
            contentHeight: tileFlow.implicitHeight
            clip: true

            Flow {
                id: tileFlow
                width: parent.width
                spacing: 20

                Repeater {
                    model: DesktopManager.desktopList

                    delegate: Rectangle {
                        id: tile
                        readonly property bool isActive: modelData.id === DesktopManager.currentDesktopId
                        readonly property string desktopId: modelData.id
                        readonly property color desktopColor: modelData.color

                        width: 280
                        height: 200
                        radius: 12
                        color: ThemeManager.surfaceColor
                        border.width: isActive ? 3 : 1
                        border.color: isActive ? modelData.color : Qt.rgba(1, 1, 1, 0.18)

                        scale: tileMa.containsMouse ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutQuad } }

                        // Color strip (top edge)
                        Rectangle {
                            id: colorStrip
                            anchors.top:   parent.top
                            anchors.left:  parent.left
                            anchors.right: parent.right
                            height: 6
                            radius: 3
                            color: modelData.color
                        }

                        // ── Mini-preview area ───────────────────────────────────────
                        // Renders each node belonging to this desktop as a tiny
                        // rectangle, mapped from its world (canvas) bounds to the
                        // 248×148 preview canvas with 8px padding.
                        Rectangle {
                            id: previewBox
                            anchors.top:        colorStrip.bottom
                            anchors.left:       parent.left
                            anchors.right:      parent.right
                            anchors.bottom:     bottomBar.top
                            anchors.margins:    10
                            color: Qt.rgba(0, 0, 0, 0.28)
                            radius: 6
                            clip: true

                            // Compute bounding box across all member nodes of this
                            // desktop. Pinned nodes always count. Recomputed when
                            // refreshTick or the node list mutates.
                            property real boundsX: 0
                            property real boundsY: 0
                            property real boundsW: 1
                            property real boundsH: 1
                            property int  memberCount: 0

                            function _recompute() {
                                if (!root.nodes || !root.nodes.model) {
                                    memberCount = 0
                                    return
                                }
                                var mnX = 1e12, mnY = 1e12, mxX = -1e12, mxY = -1e12
                                var count = 0
                                for (var i = 0; i < root.nodes.model.count; i++) {
                                    var entry = root.nodes.model.get(i)
                                    if (!entry || !entry.object || entry.isVisualization) continue
                                    var uuid = entry.uuid
                                    var inDesktop = DesktopManager.isNodeInDesktop(uuid, tile.desktopId)
                                    var isPinned  = DesktopManager.pinnedNodes.indexOf(uuid) >= 0
                                    if (!inDesktop && !isPinned) continue
                                    var item = root.nodes.itemAt(i)
                                    var nx = item ? item.x      : entry.object.x
                                    var ny = item ? item.y      : entry.object.y
                                    var nw = item ? item.width  : entry.object.width
                                    var nh = item ? item.height : entry.object.height
                                    if (nx < mnX) mnX = nx
                                    if (ny < mnY) mnY = ny
                                    if (nx + nw > mxX) mxX = nx + nw
                                    if (ny + nh > mxY) mxY = ny + nh
                                    count++
                                }
                                memberCount = count
                                if (count === 0) { boundsX = 0; boundsY = 0; boundsW = 1; boundsH = 1; return }
                                var pad = 50
                                boundsX = mnX - pad
                                boundsY = mnY - pad
                                boundsW = Math.max(1, (mxX - mnX) + pad * 2)
                                boundsH = Math.max(1, (mxY - mnY) + pad * 2)
                            }

                            // Trigger recompute on any relevant change
                            property int _trigger: root.refreshTick
                            on_TriggerChanged: _recompute()
                            Component.onCompleted:  _recompute()

                            // Scale to fit, preserving aspect ratio
                            readonly property real scaleX: width  / boundsW
                            readonly property real scaleY: height / boundsH
                            readonly property real fit:    Math.min(scaleX, scaleY)
                            // Offset to center the bounding box in the preview
                            readonly property real offX:   (width  - boundsW * fit) / 2
                            readonly property real offY:   (height - boundsH * fit) / 2

                            // Empty state
                            Column {
                                visible: previewBox.memberCount === 0
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    text: qsTr("Empty")
                                    font.pixelSize: 11
                                    color: Qt.rgba(1, 1, 1, 0.4)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                                Text {
                                    text: qsTr("Drop nodes here")
                                    font.pixelSize: 9
                                    color: Qt.rgba(1, 1, 1, 0.25)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }

                            // Mini node rectangles
                            Repeater {
                                model: root.nodes && root.nodes.model ? root.nodes.model.count : 0

                                delegate: Item {
                                    readonly property var entry: root.nodes && root.nodes.model ? root.nodes.model.get(index) : null
                                    readonly property string uuid: entry ? entry.uuid : ""
                                    readonly property bool isVisualization: entry ? entry.isVisualization : false
                                    readonly property bool belongs: uuid !== "" &&
                                        (DesktopManager.isNodeInDesktop(uuid, tile.desktopId)
                                         || DesktopManager.pinnedNodes.indexOf(uuid) >= 0)
                                    readonly property bool isPinned: uuid !== "" && DesktopManager.pinnedNodes.indexOf(uuid) >= 0
                                    readonly property var nodeItem: root.nodes ? root.nodes.itemAt(index) : null

                                    visible: belongs && !isVisualization && nodeItem

                                    x: previewBox.offX + (nodeItem ? (nodeItem.x - previewBox.boundsX) * previewBox.fit : 0)
                                    y: previewBox.offY + (nodeItem ? (nodeItem.y - previewBox.boundsY) * previewBox.fit : 0)
                                    width:  nodeItem ? Math.max(3, nodeItem.width  * previewBox.fit) : 0
                                    height: nodeItem ? Math.max(3, nodeItem.height * previewBox.fit) : 0

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Math.min(width, height) * 0.15
                                        color: isPinned ? Qt.rgba(1, 1, 1, 0.32)
                                                        : Qt.rgba(1, 1, 1, 0.18)
                                        border.width: 1
                                        border.color: isPinned ? "#FFEB3B" : tile.desktopColor
                                    }

                                    // Tiny pin marker
                                    Text {
                                        visible: isPinned && parent.width >= 12
                                        text: qsTr("📌")
                                        font.pixelSize: 6
                                        anchors.top:   parent.top
                                        anchors.right: parent.right
                                    }
                                }
                            }
                        }

                        // ── Bottom name bar ─────────────────────────────────
                        // z: 5 keeps the close button reachable above the tile's
                        // catch-all click MouseArea (tileMa) underneath.
                        Rectangle {
                            id: bottomBar
                            z: 5
                            anchors.bottom: parent.bottom
                            anchors.left:   parent.left
                            anchors.right:  parent.right
                            height: 34
                            color: Qt.rgba(0, 0, 0, 0.4)
                            radius: 10
                            // mask top corners
                            Rectangle {
                                anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                                height: 14; color: parent.color
                            }

                            Row {
                                anchors.left:           parent.left
                                anchors.leftMargin:     12
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8

                                Rectangle {
                                    width: 8; height: 8; radius: 4
                                    color: modelData.color
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: modelData.name
                                    color: "white"
                                    font.pixelSize: 12
                                    font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                    width: 160
                                }
                                Text {
                                    text: previewBox.memberCount + (previewBox.memberCount === 1 ? " node" : " nodes")
                                    color: ThemeManager.textSecondaryColor
                                    font.pixelSize: 10
                                    opacity: 0.7
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            // Delete button on hover
                            Rectangle {
                                visible: (closeMa.containsMouse || tileMa.containsMouse) && DesktopManager.desktopCount > 1
                                anchors.right:          parent.right
                                anchors.rightMargin:    8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 22; height: 22; radius: 11
                                color: closeMa.containsMouse ? ThemeManager.dangerColor : Qt.rgba(1, 1, 1, 0.18)
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: qsTr("×")
                                    color: "white"
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                                MouseArea {
                                    id: closeMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape:  Qt.PointingHandCursor
                                    onClicked: DesktopManager.removeDesktop(tile.desktopId)
                                }
                            }
                        }

                        MouseArea {
                            id: tileMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            // Don't intercept clicks on the close button
                            anchors.rightMargin: 0
                            onClicked: {
                                DesktopManager.switchToDesktop(tile.desktopId)
                                root.close()
                            }
                        }
                    }
                }
            }
        }

        // Add new desktop button — bottom row
        Row {
            id: addRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom:           parent.bottom
            anchors.bottomMargin:     32
            spacing: 12

            Rectangle {
                width: 220; height: 44; radius: 22
                color: addNewMa.containsMouse
                          ? Qt.lighter(ThemeManager.primaryColor, 1.12)
                          : ThemeManager.primaryColor
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    anchors.centerIn: parent
                    text: qsTr("+   New Desktop")
                    color: "white"
                    font.pixelSize: 13
                    font.bold: true
                }
                MouseArea {
                    id: addNewMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: DesktopManager.addDesktop("")
                }
            }
        }
    }
}
