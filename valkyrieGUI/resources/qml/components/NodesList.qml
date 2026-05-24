import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.15
import App.Theme 1.0
import App.Properties 1.0
import App.Desktop 1.0
import App.Icons 1.0

// Floating "minimap"-style nodes panel.
// Groups nodes by virtual desktop (collapsible sections). Clicking a node
// switches to its desktop AND animates the canvas to center on it.
// A "Pinned" group at the top holds nodes that show on every desktop.
Rectangle {
    id: root

    // ── Public API ──────────────────────────────────────────────────────────
    property var nodesModel
    property var containerCanvas
    property var mycanvas
    property real zoomScale: 1.0
    property var statusBar
    property var topBar
    // Anchor used for top-positioned layouts; ViewPortWindow passes the
    // DesktopBar so this panel sits below it, not under it.
    property var topLeftAnchor: topBar
    property var nodes
    property var focusedNode: null
    property var onNodeSelected: null
    property string position: GlobalProperties.nodesListPosition || "bottom-left"
    property bool _animating: false

    // Re-evaluated whenever the user toggles a section
    property var _collapsed: ({})

    width: 248
    // Height = chrome (header + divider + padding ≈ 56) + visible group content,
    // clamped to [180, 420]. The inner Flickable scrolls when content exceeds.
    // groupsCol.implicitHeight already reflects collapsed/expanded sections.
    height: Math.max(180,
                     Math.min(420,
                              groupsCol.implicitHeight + 56))
    radius: 10
    color: Qt.rgba(ThemeManager.backgroundColor.r,
                   ThemeManager.backgroundColor.g,
                   ThemeManager.backgroundColor.b, 0.92)
    border.color: Qt.rgba(ThemeManager.borderColor.r,
                          ThemeManager.borderColor.g,
                          ThemeManager.borderColor.b, 0.6)
    border.width: 1
    z: 150
    visible: nodesModel && nodesModel.count > 0

    anchors.margins: 12

    Component.onCompleted: updatePosition()

    Binding {
        target: root
        property: "position"
        value: GlobalProperties.nodesListPosition || "bottom-left"
    }

    onPositionChanged: updatePosition()

    function _toggleSection(id) {
        var c = root._collapsed
        c[id] = !c[id]
        root._collapsed = c
    }
    function _isCollapsed(id) { return root._collapsed[id] === true }

    function _focusNode(index) {
        if (!root.nodes) return
        var nodeItem = root.nodes.itemAt(index)
        if (!nodeItem || root._animating) return

        var entry = nodesModel.get(index)
        // Switch to a desktop that contains this node so it becomes visible
        if (entry && entry.uuid) {
            if (DesktopManager.pinnedNodes.indexOf(entry.uuid) < 0) {
                if (!DesktopManager.isNodeInDesktop(entry.uuid, DesktopManager.currentDesktopId)) {
                    var owners = DesktopManager.getNodeDesktops(entry.uuid)
                    if (owners.length > 0)
                        DesktopManager.switchToDesktop(owners[0])
                }
            }
        }

        if (root.onNodeSelected) root.onNodeSelected(nodeItem)

        var nodeCenterX = nodeItem.x + nodeItem.width  / 2
        var nodeCenterY = nodeItem.y + nodeItem.height / 2
        var targetX = root.containerCanvas.width  / 2 - nodeCenterX * root.zoomScale
        var targetY = root.containerCanvas.height / 2 - nodeCenterY * root.zoomScale

        root._animating = true
        animX.to = targetX
        animY.to = targetY
        animX.start()
        animY.start()
    }

    NumberAnimation { id: animX; target: root.mycanvas; property: "x"; duration: 500
                      easing.type: Easing.InOutQuad; onFinished: root._animating = false }
    NumberAnimation { id: animY; target: root.mycanvas; property: "y"; duration: 500
                      easing.type: Easing.InOutQuad }

    function updatePosition() {
        clearAnchors()
        const margin = 12
        switch(position) {
            case "top-left":
                root.anchors.top    = topLeftAnchor.bottom
                root.anchors.topMargin    = margin
                root.anchors.left   = root.parent.left
                root.anchors.leftMargin   = margin
                break
            case "top-center":
                root.anchors.top    = topLeftAnchor.bottom
                root.anchors.topMargin    = margin
                root.anchors.horizontalCenter = root.parent.horizontalCenter
                break
            case "top-right":
                root.anchors.top    = topLeftAnchor.bottom
                root.anchors.topMargin    = margin
                root.anchors.right  = root.parent.right
                root.anchors.rightMargin  = margin
                break
            case "mid-left":
                root.anchors.verticalCenter = root.parent.verticalCenter
                root.anchors.left   = root.parent.left
                root.anchors.leftMargin   = margin
                break
            case "mid-right":
                root.anchors.verticalCenter = root.parent.verticalCenter
                root.anchors.right  = root.parent.right
                root.anchors.rightMargin  = margin
                break
            case "bottom-left":
                root.anchors.bottom = statusBar.top
                root.anchors.bottomMargin = margin
                root.anchors.left   = root.parent.left
                root.anchors.leftMargin   = margin
                break
            case "bottom-center":
                root.anchors.bottom = statusBar.top
                root.anchors.bottomMargin = margin
                root.anchors.horizontalCenter = root.parent.horizontalCenter
                break
            case "bottom-right":
                root.anchors.bottom = statusBar.top
                root.anchors.bottomMargin = margin
                root.anchors.right  = root.parent.right
                root.anchors.rightMargin  = margin
                break
        }
    }

    function clearAnchors() {
        root.anchors.top = undefined
        root.anchors.bottom = undefined
        root.anchors.left = undefined
        root.anchors.right = undefined
        root.anchors.horizontalCenter = undefined
        root.anchors.verticalCenter = undefined
        root.anchors.topMargin = 0
        root.anchors.bottomMargin = 0
        root.anchors.leftMargin = 0
        root.anchors.rightMargin = 0
    }

    // Bumped whenever any source data changes so the inner Repeaters re-evaluate
    property int _refresh: 0
    Connections {
        target: DesktopManager
        function onDesktopListChanged()           { root._refresh++ }
        function onCurrentDesktopChanged()        { root._refresh++ }
        function onNodeDesktopMembershipChanged() { root._refresh++ }
        function onPinnedNodesChanged()           { root._refresh++ }
    }
    Connections {
        target: nodesModel
        function onCountChanged() { root._refresh++ }
    }

    // ── Content ──────────────────────────────────────────────────────────────
    ColumnLayout {
        id: rootColumn
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        // Header row
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Text {
                Layout.fillWidth: true
                text: "Nodes  (" + (nodesModel ? nodesModel.count : 0) + ")"
                font.pixelSize: 11
                font.bold: true
                color: ThemeManager.primaryColor
                elide: Text.ElideRight
            }
            Text {
                text: DesktopManager.desktopCount + " desktops"
                font.pixelSize: 9
                color: ThemeManager.textSecondaryColor
                opacity: 0.7
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1
                    color: ThemeManager.primaryColor; opacity: 0.18 }

        // Scrollable group/section list
        Flickable {
            id: scrollArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: groupsCol.implicitHeight
            clip: true

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: 3
                    radius: 2
                    color: ThemeManager.primaryColor
                    opacity: 0.35
                }
            }

            Column {
                id: groupsCol
                width: scrollArea.width
                spacing: 4

                // ── Pinned group (always at the top, if any pinned exists) ──
                Item {
                    width: parent.width
                    visible: DesktopManager.pinnedNodes.length > 0 && (root._refresh >= 0)
                    height: visible ? pinnedHeader.height + (root._isCollapsed("__pinned__") ? 0 : pinnedItems.height + 2) : 0

                    Rectangle {
                        id: pinnedHeader
                        width: parent.width
                        height: 22
                        radius: 4
                        color: pinnedHeaderHover.containsMouse
                                   ? Qt.rgba(ThemeManager.primaryColor.r,
                                             ThemeManager.primaryColor.g,
                                             ThemeManager.primaryColor.b, 0.10)
                                   : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            spacing: 4
                            Text {
                                text: root._isCollapsed("__pinned__") ? "▸" : "▾"
                                font.pixelSize: 9
                                color: ThemeManager.textSecondaryColor
                                anchors.verticalCenter: parent.verticalCenter
                                width: 12; horizontalAlignment: Text.AlignHCenter
                            }
                            Text { text: "📌"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                            Text {
                                text: "Pinned"
                                font.pixelSize: 10
                                font.bold: true
                                color: ThemeManager.textColor
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: "(" + DesktopManager.pinnedNodes.length + ")"
                                font.pixelSize: 9
                                color: ThemeManager.textSecondaryColor
                                opacity: 0.6
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        MouseArea {
                            id: pinnedHeaderHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked: root._toggleSection("__pinned__")
                        }
                    }

                    Column {
                        id: pinnedItems
                        anchors.top: pinnedHeader.bottom
                        anchors.topMargin: 2
                        width: parent.width
                        visible: !root._isCollapsed("__pinned__")
                        spacing: 2

                        Repeater {
                            model: (root._refresh >= 0) ? (nodesModel ? nodesModel.count : 0) : 0
                            delegate: Loader {
                                width: pinnedItems.width
                                active: nodesModel && (function() {
                                    var e = nodesModel.get(index)
                                    return e && e.uuid && DesktopManager.pinnedNodes.indexOf(e.uuid) >= 0
                                })()
                                sourceComponent: nodeRow
                                property int _nodeIndex: index
                            }
                        }
                    }
                }

                // ── Per-desktop sections ────────────────────────────────────
                Repeater {
                    model: (root._refresh >= 0) ? DesktopManager.desktopList : []

                    delegate: Item {
                        id: section
                        readonly property var desktop: modelData
                        readonly property string sectionId: desktop.id
                        readonly property bool isCurrent: desktop.id === DesktopManager.currentDesktopId

                        width: groupsCol.width
                        height: header.height + (root._isCollapsed(sectionId) ? 0 : itemsCol.height + 2)

                        Rectangle {
                            id: header
                            width: parent.width
                            height: 22
                            radius: 4
                            color: section.isCurrent
                                   ? Qt.rgba(section.desktop.color.r !== undefined ? section.desktop.color.r : 0.3,
                                             0.4, 0.4, 0.10)
                                   : (sectionHover.containsMouse
                                        ? Qt.rgba(ThemeManager.primaryColor.r,
                                                  ThemeManager.primaryColor.g,
                                                  ThemeManager.primaryColor.b, 0.08)
                                        : "transparent")
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 4
                                anchors.rightMargin: 4
                                spacing: 4

                                Text {
                                    text: root._isCollapsed(section.sectionId) ? "▸" : "▾"
                                    font.pixelSize: 9
                                    color: ThemeManager.textSecondaryColor
                                    width: 12; horizontalAlignment: Text.AlignHCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Rectangle {
                                    width: 8; height: 8; radius: 4
                                    color: section.desktop.color
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: section.desktop.name
                                    font.pixelSize: 10
                                    font.bold: section.isCurrent
                                    color: section.isCurrent ? section.desktop.color : ThemeManager.textColor
                                    anchors.verticalCenter: parent.verticalCenter
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: "(" + section.desktop.nodeCount + ")"
                                    font.pixelSize: 9
                                    color: ThemeManager.textSecondaryColor
                                    opacity: 0.6
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Item { width: 4; height: 1 }
                                Text {
                                    visible: section.isCurrent
                                    text: "·  active"
                                    font.pixelSize: 9
                                    color: section.desktop.color
                                    opacity: 0.7
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: sectionHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape:  Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: function(mouse) {
                                    if (mouse.button === Qt.RightButton) {
                                        // Right click = switch to this desktop
                                        DesktopManager.switchToDesktop(section.desktop.id)
                                    } else {
                                        root._toggleSection(section.sectionId)
                                    }
                                }
                                onDoubleClicked: DesktopManager.switchToDesktop(section.desktop.id)
                            }
                        }

                        Column {
                            id: itemsCol
                            anchors.top: header.bottom
                            anchors.topMargin: 2
                            width: parent.width
                            visible: !root._isCollapsed(section.sectionId)
                            spacing: 2

                            Repeater {
                                model: (root._refresh >= 0) ? (nodesModel ? nodesModel.count : 0) : 0
                                delegate: Loader {
                                    width: itemsCol.width
                                    active: nodesModel && (function() {
                                        var e = nodesModel.get(index)
                                        if (!e || !e.uuid) return false
                                        // Pinned nodes are listed in the "Pinned" group only,
                                        // not duplicated in every desktop section.
                                        if (DesktopManager.pinnedNodes.indexOf(e.uuid) >= 0) return false
                                        return DesktopManager.isNodeInDesktop(e.uuid, section.desktop.id)
                                    })()
                                    sourceComponent: nodeRow
                                    property int _nodeIndex: index
                                }
                            }

                            // Empty hint
                            Text {
                                visible: section.desktop.nodeCount === 0
                                width:   parent.width
                                text:    "  (no nodes)"
                                font.pixelSize: 9
                                color:   ThemeManager.textSecondaryColor
                                opacity: 0.5
                                font.italic: true
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Reusable node row component ─────────────────────────────────────────
    Component {
        id: nodeRow

        Rectangle {
            id: row
            readonly property int idx: parent ? parent._nodeIndex : -1
            readonly property var nodeItem: (idx >= 0 && root.nodes) ? root.nodes.itemAt(idx) : null
            readonly property var nodeEntry: (idx >= 0 && nodesModel) ? nodesModel.get(idx) : null
            readonly property bool isFocused: nodeItem === root.focusedNode

            width: parent ? parent.width : 0
            height: 22
            radius: 3
            color: isFocused
                   ? Qt.rgba(ThemeManager.primaryColor.r,
                             ThemeManager.primaryColor.g,
                             ThemeManager.primaryColor.b, 0.22)
                   : (rowHover.containsMouse
                      ? Qt.rgba(ThemeManager.primaryColor.r,
                                ThemeManager.primaryColor.g,
                                ThemeManager.primaryColor.b, 0.10)
                      : "transparent")
            border.width: isFocused ? 1 : 0
            border.color: isFocused ? ThemeManager.primaryColor : "transparent"
            Behavior on color { ColorAnimation { duration: 100 } }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 6
                spacing: 4

                // Connector indicator
                Rectangle {
                    width: 2; height: 10; radius: 1
                    color: isFocused ? ThemeManager.primaryColor : ThemeManager.textSecondaryColor
                    opacity: isFocused ? 0.9 : 0.35
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: (nodeEntry && nodeEntry.object) ? (nodeEntry.object.title || "Node " + row.idx) : ("Node " + row.idx)
                    font.pixelSize: 10
                    font.bold: row.isFocused
                    color: row.isFocused ? ThemeManager.primaryColor : ThemeManager.textColor
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 12
                    Behavior on color { ColorAnimation { duration: 100 } }
                }
            }

            MouseArea {
                id: rowHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onClicked: root._focusNode(row.idx)
            }
        }
    }
}
