import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0

// BottomSheet — draggable sheet that slides up from the bottom.
// Supports snap points and swipe-to-dismiss.
//
// Usage:
//   BottomSheet {
//       id: sheet
//       title: "Options"
//       snapHeights: [0.35, 0.65]   // fractions of parent height
//       content: Column { ... }
//   }
//   sheet.open()
Popup {
    id: root

    property string    title:       ""
    property var       snapHeights: [0.5]   // fractions of parent height (0–1)
    property Component content:     null
    property color     handleColor: ThemeManager.borderColor
    property color     bgColor:     ThemeManager.surfaceColor
    property bool      showHandle:  true

    // internal snap management
    property real _snapFrac:    snapHeights.length > 0 ? snapHeights[0] : 0.5
    property real _dragOffset:  0   // pixels dragged during gesture (positive = down)
    property bool _dragging:    false

    readonly property real _ovH: Overlay.overlay ? Overlay.overlay.height : 600
    readonly property real _snapH: _snapFrac * _ovH
    readonly property real _currentH: Math.max(80, Math.min(_ovH * 0.95, _snapH - _dragOffset))

    // Position at bottom
    x: Overlay.overlay ? (Overlay.overlay.width - root.width) / 2 : 0
    y: Overlay.overlay ? _ovH - _currentH : 0
    width:  Overlay.overlay ? Overlay.overlay.width : 400
    height: _currentH
    padding: 0

    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.4)
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    enter: Transition { NumberAnimation { property: "y"; duration: 280; easing.type: Easing.OutCubic } }
    exit:  Transition { NumberAnimation { property: "y"; to: root._ovH; duration: 220; easing.type: Easing.InCubic } }

    background: Rectangle {
        color: root.bgColor
        radius: 14
        // Only round top corners
        Rectangle {
            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
            height: 14; color: parent.color
        }
    }

    contentItem: Column {
        anchors.fill: parent
        spacing: 0

        // ── Drag handle ─────────────────────────────────────────────────────
        Item {
            width: parent.width; height: 28

            Rectangle {
                visible: root.showHandle
                anchors.centerIn: parent
                width: 40; height: 4; radius: 2
                color: root.handleColor
            }

            MouseArea {
                id: handleMa
                anchors.fill: parent
                property real _startY: 0
                property real _startH: 0

                onPressed: {
                    _startY = mouseY
                    _startH = root._snapH
                    root._dragging = true
                }
                onPositionChanged: {
                    if (root._dragging) {
                        root._dragOffset = mouseY - _startY
                    }
                }
                onReleased: {
                    root._dragging = false
                    var newH = root._snapH - root._dragOffset
                    root._dragOffset = 0

                    // Snap to nearest snap height or dismiss
                    if (newH < root._ovH * 0.15) {
                        root.close(); return
                    }
                    var best = root.snapHeights[0], bestD = 999
                    for (var i = 0; i < root.snapHeights.length; i++) {
                        var d = Math.abs(root.snapHeights[i] * root._ovH - newH)
                        if (d < bestD) { bestD = d; best = root.snapHeights[i] }
                    }
                    root._snapFrac = best
                }
            }
        }

        // ── Title ──────────────────────────────────────────────────────────
        Text {
            visible: root.title !== ""
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: root.title
            font.pixelSize: 15; font.bold: true
            color: ThemeManager.textColor
            bottomPadding: 8
        }

        Rectangle {
            visible: root.title !== ""
            width: parent.width; height: 1
            color: ThemeManager.borderColor; opacity: 0.4
        }

        // ── Content ────────────────────────────────────────────────────────
        Loader {
            width: parent.width
            height: parent.height - (root.showHandle ? 28 : 0) - (root.title !== "" ? 38 : 0)
            sourceComponent: root.content
        }
    }
}
