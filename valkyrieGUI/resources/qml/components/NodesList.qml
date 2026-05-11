import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.15
import App.Theme 1.0
import App.Properties 1.0

Rectangle {
    id: root

    property var nodesModel
    property var containerCanvas
    property var mycanvas
    property real zoomScale: 1.0
    property var statusBar
    property var topBar
    property var topLeftAnchor: topBar
    property var nodes
    property var focusedNode: null
    property var onNodeSelected: null
    property string position: GlobalProperties.nodesListPosition || "bottom-left"
    property bool _animating: false

    width: 220
    height: Math.min(nodesModel.count * 32 + 38, 230)
    radius: 8
    color: Qt.rgba(ThemeManager.backgroundColor.r,
                   ThemeManager.backgroundColor.g,
                   ThemeManager.backgroundColor.b, 0.85)
    border.color: ThemeManager.borderColor
    border.width: 1
    z: 150
    visible: nodesModel.count > 0

    anchors.margins: 12

    Component.onCompleted: {
        updatePosition()
    }

    Binding {
        target: root
        property: "position"
        value: GlobalProperties.nodesListPosition || "bottom-left"
    }

    onPositionChanged: updatePosition()

    function updatePosition() {
        clearAnchors()
        const margin = 12

        switch(position) {
            case "top-left":
                root.anchors.top = topLeftAnchor.bottom
                root.anchors.topMargin = margin
                root.anchors.left = root.parent.left
                root.anchors.leftMargin = margin
                break
            case "top-center":
                root.anchors.top = topBar.bottom
                root.anchors.topMargin = margin
                root.anchors.horizontalCenter = root.parent.horizontalCenter
                break
            case "top-right":
                root.anchors.top = topBar.bottom
                root.anchors.topMargin = margin
                root.anchors.right = root.parent.right
                root.anchors.rightMargin = margin
                break
            case "mid-left":
                root.anchors.verticalCenter = root.parent.verticalCenter
                root.anchors.left = root.parent.left
                root.anchors.leftMargin = margin
                break
            case "mid-right":
                root.anchors.verticalCenter = root.parent.verticalCenter
                root.anchors.right = root.parent.right
                root.anchors.rightMargin = margin
                break
            case "bottom-left":
                root.anchors.bottom = statusBar.top
                root.anchors.bottomMargin = margin
                root.anchors.left = root.parent.left
                root.anchors.leftMargin = margin
                break
            case "bottom-center":
                root.anchors.bottom = statusBar.top
                root.anchors.bottomMargin = margin
                root.anchors.horizontalCenter = root.parent.horizontalCenter
                break
            case "bottom-right":
                root.anchors.bottom = statusBar.top
                root.anchors.bottomMargin = margin
                root.anchors.right = root.parent.right
                root.anchors.rightMargin = margin
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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        Text {
            text: "Nodes (" + nodesModel.count + ")"
            font.pixelSize: 11
            font.bold: true
            color: ThemeManager.primaryColor
            Layout.fillWidth: true
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: nodesModel

            ScrollBar.vertical: ScrollBar {
                active: true
                policy: ScrollBar.AsNeeded
                contentItem: Rectangle {
                    implicitWidth: 2
                    radius: 1
                    color: ThemeManager.primaryColor
                    opacity: 0.3
                }
            }

            delegate: Rectangle {
                id: delegateRect
                width: ListView.view.width - 2
                height: 28
                radius: 4

                readonly property bool isFocused: {
                    const nodeItem = root.nodes.itemAt(index)
                    return nodeItem === root.focusedNode
                }

                color: isFocused
                       ? Qt.rgba(ThemeManager.primaryColor.r,
                                 ThemeManager.primaryColor.g,
                                 ThemeManager.primaryColor.b, 0.25)
                       : (delegateHover.containsMouse
                          ? Qt.rgba(ThemeManager.primaryColor.r,
                                    ThemeManager.primaryColor.g,
                                    ThemeManager.primaryColor.b, 0.15)
                          : "transparent")
                border.width: isFocused ? 1 : 0
                border.color: isFocused ? ThemeManager.primaryColor : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 6
                    text: model.object.title || "Node " + index
                    font.pixelSize: 11
                    font.bold: delegateRect.isFocused
                    color: delegateRect.isFocused ? ThemeManager.primaryColor : ThemeManager.textColor
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    Behavior on color { ColorAnimation { duration: 100 } }
                }

                MouseArea {
                    id: delegateHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const nodeItem = root.nodes.itemAt(index)
                        if (nodeItem && !root._animating) {
                            if (root.onNodeSelected) {
                                root.onNodeSelected(nodeItem)
                            }

                            const nodeX = nodeItem.x
                            const nodeY = nodeItem.y
                            const nodeW = nodeItem.width
                            const nodeH = nodeItem.height
                            const nodeCenterX = nodeX + nodeW / 2
                            const nodeCenterY = nodeY + nodeH / 2
                            const viewCenterScreenX = root.containerCanvas.width / 2
                            const viewCenterScreenY = root.containerCanvas.height / 2
                            const targetX = viewCenterScreenX - nodeCenterX * root.zoomScale
                            const targetY = viewCenterScreenY - nodeCenterY * root.zoomScale

                            root._animating = true
                            animX.to = targetX
                            animY.to = targetY
                            animX.start()
                            animY.start()
                        }
                    }
                }

                NumberAnimation {
                    id: animX
                    target: root.mycanvas
                    property: "x"
                    duration: 600
                    easing.type: Easing.InOutQuad
                    onFinished: root._animating = false
                }

                NumberAnimation {
                    id: animY
                    target: root.mycanvas
                    property: "y"
                    duration: 600
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}

