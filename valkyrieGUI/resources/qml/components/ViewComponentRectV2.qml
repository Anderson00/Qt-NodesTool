import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.12
import Qt5Compat.GraphicalEffects
import App.Theme 1.0
import App.Properties 1.0

import Qaterial 1.0 as Qaterial

Rectangle {
    id: root

    // -- Public API --
    property var behaviourObject

    property var connectionsInput: []
    property var connectionsOutput: []
    property alias title: titleView.text
    property color borderColor: ThemeManager.primaryColor
    property alias rootBodyColor: rootBody.color
    property alias bodyComponent: rootBodyLoader.sourceComponent
    property alias bodySourceQML: rootBodyLoader.source
    property bool animEnabled: false

    property double minWidth: 150
    property double minHeight: 100

    property int resizeHandleSize: 8

    // True while any resize handle is being dragged
    readonly property bool isResizing:
        tlH.active || trH.active || blH.active || brH.active ||
        tH.active  || bH.active  || lH.active  || rH.active

    // -- Signals --
    signal connectionSocketClicked(conn: var)

    // Single menu signal: action is one of
    // "close", "front-step", "back-step", "front-max", "back-max"
    signal menuActionTriggered(string action)

    // Kept for backward compatibility
    signal closeButtonClicked()
    signal frontOneStepClicked()
    signal backOneStepClicked()
    signal frontTotalClicked()
    signal backTotalClicked()

    color: Qt.rgba(ThemeManager.backgroundColor.r,
                   ThemeManager.backgroundColor.g,
                   ThemeManager.backgroundColor.b, 0.6)
    radius: 4
    border.width: 1
    border.color: root.borderColor

    // ============== Helpers ==============
    function stringToColour(str) {
        let hash = 0
        for (let i = 0; i < str.length; i++)
            hash = str.charCodeAt(i) + ((hash << 5) - hash)
        const hue = Math.abs(hash) % 360
        return Qt.hsla(hue / 360.0, 0.65, 0.55, 1.0)
    }

    function extractParams(text) {
        const i = text.indexOf('(')
        if (i === -1) return text
        return text.slice(i, text.length - 1)
    }

    function connectionOnXYPosition(x: double, y: double) {
        const connJoint = connectionsInput.concat(connectionsOutput)
        for (let i = 0; i < connJoint.length; i++) {
            const conn = connJoint[i].connArea
            const connPos = conn.mapToItem(this.parent, 0, 0)
            if ((x >= connPos.x && x <= conn.width + connPos.x) &&
                (y >= connPos.y && y <= conn.height + connPos.y))
                return connJoint[i]
        }
        return undefined
    }

    function loadInputConns() {
        const connObj = []
        const inputs = behaviourObject.getInputsMethodSignature()
        inputs.forEach((input) => connObj.push({ name: input }))
        root.connectionsInput = connObj
    }

    function loadOutputConns() {
        const connObj = []
        const outputs = behaviourObject.getOutputsMethodSignature()
        outputs.forEach((output) => connObj.push({ name: output }))
        root.connectionsOutput = connObj
    }

    function _emitMenuAction(action) {
        menuActionTriggered(action)
        switch (action) {
            case "close":      closeButtonClicked();    break
            case "front-step": frontOneStepClicked();   break
            case "back-step":  backOneStepClicked();    break
            case "front-max":  frontTotalClicked();     break
            case "back-max":   backTotalClicked();      break
        }
    }

    // ============== Bindings to behaviourObject ==============
    // One-shot init from behaviourObject; user interactions (drag/resize) push
    // values back via the onXChanged/onYChanged/onWidthChanged/onHeightChanged
    // handlers below. Avoids circular bindings between width <-> contentWidth.
    Component.onCompleted: {
        root.title = Qt.binding(() => behaviourObject.title)
        root.bodySourceQML = Qt.binding(() => behaviourObject.qmlBodyUrl)
        root.width  = behaviourObject.width  > 0 ? behaviourObject.width  : root.minWidth
        root.height = behaviourObject.height > 0 ? behaviourObject.height
                                                  : (behaviourObject.contentHeight + topHeaderRect.height +
                                                     divider.height + connectionsBody.height)
        root.x = behaviourObject.x
        root.y = behaviourObject.y
        loadInputConns()
        loadOutputConns()
        Qt.callLater(() => animEnabled = true)
    }

    onXChanged:      if (behaviourObject) behaviourObject.x = x
    onYChanged:      if (behaviourObject) behaviourObject.y = y
    onWidthChanged:  if (behaviourObject) { behaviourObject.width = width; behaviourObject.contentWidth = width }
    onHeightChanged: if (behaviourObject) behaviourObject.height = root.height

    Connections {
        target: rootBodyLoader
        function onLoaded() {
            rootBodyLoader.item.behaviourObject = root.behaviourObject
        }
    }

    Behavior on height {
        enabled: animEnabled && !isResizing
        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
    }
    Behavior on width {
        enabled: animEnabled && !isResizing
        NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
    }

    // ============== Drag area ==============
    MouseArea {
        id: area
        z: 1
        anchors.fill: root
        hoverEnabled: true
        cursorShape: (area.containsMouse && !isResizing) ? Qt.OpenHandCursor : Qt.ArrowCursor
        drag.smoothed: true
        drag.target: root

        drag.minimumX: 0
        drag.minimumY: 0
        drag.maximumX: parent && parent.parent ? parent.parent.width  - width  : Number.MAX_VALUE
        drag.maximumY: parent && parent.parent ? parent.parent.height - height : Number.MAX_VALUE
        acceptedButtons: Qt.AllButtons

        onClicked: function(mouse) {
            root.focus = true
            if (mouse.button === Qt.RightButton)
                contextMenu.popup()
        }
    }

    // ============== Resize handles (extracted to ResizeHandle.qml) ==============
    ResizeHandle { id: tlH; direction: "top-left";     handleSize: resizeHandleSize; minWidth: root.minWidth; minHeight: root.minHeight; highlightColor: root.borderColor }
    ResizeHandle { id: trH; direction: "top-right";    handleSize: resizeHandleSize; minWidth: root.minWidth; minHeight: root.minHeight; highlightColor: root.borderColor }
    ResizeHandle { id: blH; direction: "bottom-left";  handleSize: resizeHandleSize; minWidth: root.minWidth; minHeight: root.minHeight; highlightColor: root.borderColor }
    ResizeHandle { id: brH; direction: "bottom-right"; handleSize: resizeHandleSize; minWidth: root.minWidth; minHeight: root.minHeight; highlightColor: root.borderColor }
    ResizeHandle { id: tH;  direction: "top";          handleSize: resizeHandleSize; minWidth: root.minWidth; minHeight: root.minHeight; highlightColor: root.borderColor }
    ResizeHandle { id: bH;  direction: "bottom";       handleSize: resizeHandleSize; minWidth: root.minWidth; minHeight: root.minHeight; highlightColor: root.borderColor }
    ResizeHandle { id: lH;  direction: "left";         handleSize: resizeHandleSize; minWidth: root.minWidth; minHeight: root.minHeight; highlightColor: root.borderColor }
    ResizeHandle { id: rH;  direction: "right";        handleSize: resizeHandleSize; minWidth: root.minWidth; minHeight: root.minHeight; highlightColor: root.borderColor }

    // ============== Header ==============
    Rectangle {
        id: topHeaderRect
        anchors.left: root.left
        anchors.top: root.top
        anchors.right: root.right
        anchors.leftMargin: root.border.width
        anchors.topMargin: root.border.width
        anchors.rightMargin: root.border.width
        height: 25
        radius: root.radius - 1
        antialiasing: true
        clip: true
        z: 1
        color: root.focus ? root.borderColor : root.color

        Rectangle {
            anchors.bottom: topHeaderRect.bottom
            width: parent.width
            height: root.radius
            color: topHeaderRect.color
            antialiasing: true
        }

        RowLayout {
            id: topHeader
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 4

            Text {
                id: titleView
                Layout.fillWidth: true
                text: ""
                font.pixelSize: 10
                color: root.focus ? ThemeManager.backgroundColor
                                  : ThemeManager.textColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            NewButton {
                Layout.preferredHeight: 25
                Layout.preferredWidth: 22
                textColor: titleView.color
                iconSource: Qaterial.Icons.dotsVertical
                iconSize: 12
                variant: "text"
                onClicked: contextMenu.popup()
            }

            NewButton {
                Layout.preferredHeight: 25
                Layout.preferredWidth: 22
                textColor: titleView.color
                iconSource: Qaterial.Icons.windowMaximize
                iconSize: 12
                variant: "text"
                onClicked: console.log("Maximize clicked")
            }

            NewButton {
                Layout.preferredHeight: 25
                Layout.preferredWidth: 22
                textColor: titleView.color
                iconSource: Qaterial.Icons.close
                iconSize: 12
                variant: "text"
                onClicked: root._emitMenuAction("close")
            }
        }
    }

    // ============== Context menu ==============
    Menu {
        id: contextMenu
        Material.foreground: ThemeManager.textColor

        background: Rectangle {
            color: ThemeManager.backgroundColor
            border.color: ThemeManager.primaryColor
            border.width: 1
            radius: 4
            implicitWidth: 200
            implicitHeight: 40
        }

        onOpened:     root.focus = true
        onAboutToHide: root.focus = true

        MenuItem {
            text: qsTr("Close")
            icon.source: 'qrc:/Qaterial/Icons/close.svg'
            onTriggered: root._emitMenuAction("close")
        }
        MenuItem {
            text: qsTr("Front + 1")
            icon.source: 'qrc:/Qaterial/Icons/arrow-up.svg'
            onTriggered: root._emitMenuAction("front-step")
        }
        MenuItem {
            text: qsTr("Down - 1")
            icon.source: 'qrc:/Qaterial/Icons/arrow-down.svg'
            onTriggered: root._emitMenuAction("back-step")
        }
        MenuItem {
            text: qsTr("Front max")
            icon.source: 'qrc:/Qaterial/Icons/flip-to-front.svg'
            onTriggered: root._emitMenuAction("front-max")
        }
        MenuItem {
            text: qsTr("Back max")
            icon.source: 'qrc:/Qaterial/Icons/flip-to-back.svg'
            onTriggered: root._emitMenuAction("back-max")
        }
    }

    // ============== Divider ==============
    Rectangle {
        id: divider
        color: root.border.color
        height: 1
        anchors.top: topHeaderRect.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 1
        anchors.rightMargin: 1
    }

    // ============== Body ==============
    ColumnLayout {
        id: body
        anchors.top: divider.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 1
        anchors.rightMargin: 1
        anchors.bottomMargin: 1
        clip: true
        spacing: 0
        z: 2

        RowLayout {
            id: connectionsBody
            Layout.fillWidth: true
            spacing: 0
            z: 3
            visible: connectionsInput.length > 0 || connectionsOutput.length > 0

            SplitView {
                id: splitConns
                orientation: Qt.Horizontal
                Layout.fillWidth: true
                Layout.preferredHeight:
                    Math.max(columnLayoutInputConns.height,
                             columnLayoutOutputConns.height) + 8

                Rectangle {
                    id: connectionsInputBody
                    Layout.preferredHeight:
                        Math.max(columnLayoutInputConns.height,
                                 columnLayoutOutputConns.height) + 4
                    Layout.fillWidth: true
                    SplitView.minimumWidth: 10
                    SplitView.preferredWidth: parent.width / 2
                    color: Qt.rgba(1, 1, 1, 0.06)

                    ColumnLayout {
                        id: columnLayoutInputConns
                        width: parent.width
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.leftMargin: 4
                        anchors.topMargin: 2

                        Repeater {
                            model: connectionsInput
                            Rectangle {
                                id: inputArea
                                width: connInName.width + connInConnCircle.width
                                height: rowInput.height
                                color: 'transparent'

                                Component.onCompleted: {
                                    connectionsInput[index].connArea = inputArea
                                    connectionsInput[index].circleConn = connInConnCircle
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    preventStealing: true
                                    onClicked: root.connectionSocketClicked(connectionsInput[index])
                                }

                                Row {
                                    id: rowInput
                                    spacing: 2

                                    Rectangle {
                                        id: connInConnCircle
                                        width: 4
                                        height: width
                                        radius: width
                                        color: stringToColour(extractParams(connInName.text))
                                        anchors.verticalCenter: connInName.verticalCenter
                                    }
                                    Text {
                                        id: connInName
                                        font.pixelSize: 8
                                        color: ThemeManager.textColor
                                        text: modelData.name
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    clip: true
                    id: connectionsOutputBody
                    Layout.preferredHeight:
                        Math.max(columnLayoutInputConns.height,
                                 columnLayoutOutputConns.height) + 4
                    Layout.fillWidth: true
                    SplitView.minimumWidth: 10
                    SplitView.preferredWidth: parent.width / 2
                    color: Qt.rgba(0, 0, 0, 0.20)

                    ColumnLayout {
                        id: columnLayoutOutputConns
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.rightMargin: 4
                        anchors.topMargin: 2

                        Repeater {
                            model: connectionsOutput
                            Rectangle {
                                id: outputArea
                                width: connOutName.width + 8
                                Layout.alignment: Qt.AlignRight
                                height: connOutName.height
                                color: 'transparent'

                                Component.onCompleted: {
                                    connectionsOutput[index].connArea = outputArea
                                    connectionsOutput[index].circleConn = connOutConnCircle
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.connectionSocketClicked(connectionsOutput[index])
                                }

                                Row {
                                    id: rowOutput
                                    anchors.right: parent.right
                                    spacing: 2

                                    Text {
                                        id: connOutName
                                        font.pixelSize: 8
                                        color: ThemeManager.textColor
                                        text: modelData.name
                                    }
                                    Rectangle {
                                        id: connOutConnCircle
                                        width: 4
                                        height: width
                                        radius: width
                                        color: stringToColour(extractParams(connOutName.text))
                                        anchors.verticalCenter: connOutName.verticalCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: rootBody
            Layout.fillHeight: true
            Layout.fillWidth: true
            z: 2
            radius: root.radius
            clip: true
            color: Qt.rgba(0, 0, 0, 0.35)

            Loader {
                id: rootBodyLoader
                anchors.fill: parent
            }
        }
    }
}
