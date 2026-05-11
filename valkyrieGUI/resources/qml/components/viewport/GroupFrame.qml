import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import App.Icons 1.0

import ".."

Rectangle {
    id: root

    // -- Public API --
    property string frameLabel: "Group"
    property color  frameColor: "#4CAF50"

    // Emitted on press — ViewPortWindow uses this to capture node start positions
    signal frameDragStarted()
    // Emitted on release — ViewPortWindow records the undo and syncs the model
    signal frameDragCompleted(real oldX, real oldY, real newX, real newY)

    signal dissolved()
    signal contentsSelected()
    signal labelEdited(string newLabel)

    // -- Appearance --
    color:        Qt.rgba(frameColor.r, frameColor.g, frameColor.b, 0.07)
    border.color: Qt.rgba(frameColor.r, frameColor.g, frameColor.b, 0.55)
    border.width: 1.5
    radius: 8

    // Internal drag state (read by ViewPortWindow via _pressFrameX/Y)
    property real _pressParentX: 0
    property real _pressParentY: 0
    property real _pressFrameX:  0
    property real _pressFrameY:  0

    // ── Header bar ────────────────────────────────────────────────────────────
    Rectangle {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 28
        radius: root.radius
        color: Qt.rgba(root.frameColor.r, root.frameColor.g, root.frameColor.b, 0.22)

        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: root.radius
            color:  parent.color
        }

        TextInput {
            id: labelInput
            anchors {
                left: parent.left; leftMargin: 10
                right: btnRow.left; rightMargin: 6
                verticalCenter: parent.verticalCenter
            }
            text:           root.frameLabel
            readOnly:       true
            color:          root.frameColor
            font.pixelSize: 11
            font.bold:      true
            clip:           true
            selectByMouse:  true
            selectionColor: Qt.rgba(root.frameColor.r, root.frameColor.g, root.frameColor.b, 0.4)
            onEditingFinished: { readOnly = true; root.labelEdited(text) }
        }

        Row {
            id: btnRow
            z: 2
            anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 4 }
            spacing: 0

            AppBarButton {
                width: 22; height: 22; padding: 0
                icon.source: Icons.checkboxMultipleOutline
                icon.color:  root.frameColor
                icon.width: 12; icon.height: 12
                onClicked: root.contentsSelected()
                AppToolTip { text: "Select nodes"; visible: parent.hovered }
            }
            AppBarButton {
                width: 22; height: 22; padding: 0
                icon.source: Icons.close
                icon.color:  root.frameColor
                icon.width: 11; icon.height: 11
                onClicked: root.dissolved()
                AppToolTip { text: "Dissolve group"; visible: parent.hovered }
            }
        }

        // Drag handle — sits above the TextInput (z:1) so drags register even over the label.
        // Disabled while the label is being edited so TextInput can handle its own events.
        // Buttons sit at z:2 and remain clickable regardless.
        MouseArea {
            anchors.fill: parent
            z: 1
            enabled: labelInput.readOnly
            preventStealing: true
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.SizeAllCursor

            onPressed: function(mouse) {
                var pt           = mapToItem(root.parent, mouse.x, mouse.y)
                root._pressParentX = pt.x
                root._pressParentY = pt.y
                root._pressFrameX  = root.x
                root._pressFrameY  = root.y
                root.frameDragStarted()
            }

            onPositionChanged: function(mouse) {
                var pt = mapToItem(root.parent, mouse.x, mouse.y)
                root.x = root._pressFrameX + (pt.x - root._pressParentX)
                root.y = root._pressFrameY + (pt.y - root._pressParentY)
            }

            onReleased: {
                root.frameDragCompleted(root._pressFrameX, root._pressFrameY, root.x, root.y)
            }

            onDoubleClicked: {
                labelInput.readOnly = false
                labelInput.selectAll()
                labelInput.forceActiveFocus()
            }
        }
    }
}

