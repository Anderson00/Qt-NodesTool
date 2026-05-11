import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0

// SplitPane — resizable two-panel splitter (horizontal or vertical).
//
// Usage:
//   SplitPane {
//       width: 800; height: 500
//       orientation: Qt.Horizontal
//       initialSplit: 0.3
//       firstPanel:  Rectangle { color: "red" }
//       secondPanel: Rectangle { color: "blue" }
//   }
Item {
    id: root

    property int       orientation:   Qt.Horizontal
    property real      initialSplit:  0.5      // 0–1 fraction for first panel
    property real      minFirst:      60       // px
    property real      minSecond:     60       // px
    property Component firstPanel:   null
    property Component secondPanel:  null
    property color     handleColor:  ThemeManager.borderColor
    property int       handleSize:   5

    readonly property bool _horiz: orientation === Qt.Horizontal
    property real _split: root.initialSplit

    Item {
        anchors.fill: parent

        // First panel
        Loader {
            id: panelA
            sourceComponent: root.firstPanel
            x: 0; y: 0
            width:  root._horiz ? root._split * root.width  : root.width
            height: root._horiz ? root.height : root._split * root.height
        }

        // Handle
        Rectangle {
            id: handle
            x:      root._horiz ? panelA.width : 0
            y:      root._horiz ? 0 : panelA.height
            width:  root._horiz ? root.handleSize : root.width
            height: root._horiz ? root.height : root.handleSize
            color: hma.containsMouse || hma.pressed
                   ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.35)
                   : Qt.rgba(root.handleColor.r, root.handleColor.g, root.handleColor.b, 0.4)
            Behavior on color { ColorAnimation { duration: 80 } }
            z: 2

            // Grip dots
            Column {
                anchors.centerIn: parent; spacing: 3
                Repeater {
                    model: 3
                    Rectangle {
                        width: root._horiz ? 2 : 10; height: root._horiz ? 10 : 2; radius: 1
                        color: Qt.rgba(root.handleColor.r, root.handleColor.g, root.handleColor.b, 0.7)
                    }
                }
            }

            MouseArea {
                id: hma; anchors.fill: parent; hoverEnabled: true
                cursorShape: root._horiz ? Qt.SplitHCursor : Qt.SplitVCursor
                property real _startPos: 0
                property real _startSplit: 0

                onPressed: {
                    _startPos   = root._horiz ? mouseX : mouseY
                    _startSplit = root._split
                }
                onPositionChanged: {
                    if (!pressed) return
                    var delta = (root._horiz ? mouseX - _startPos : mouseY - _startPos)
                    var total = root._horiz ? root.width : root.height
                    var newSplit = _startSplit + delta / total
                    var minF = root.minFirst  / total
                    var minS = root.minSecond / total
                    root._split = Math.max(minF, Math.min(1 - minS, newSplit))
                }
            }
        }

        // Second panel
        Loader {
            sourceComponent: root.secondPanel
            x:      root._horiz ? panelA.width + root.handleSize : 0
            y:      root._horiz ? 0 : panelA.height + root.handleSize
            width:  root._horiz ? root.width  - panelA.width - root.handleSize : root.width
            height: root._horiz ? root.height : root.height - panelA.height - root.handleSize
        }
    }
}

