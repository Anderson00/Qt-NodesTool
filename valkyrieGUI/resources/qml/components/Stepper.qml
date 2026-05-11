import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0

// Stepper — step wizard progress indicator.
//
// Usage:
//   Stepper {
//       steps: ["Account", "Profile", "Review"]
//       currentStep: 1
//       orientation: Qt.Horizontal
//       onStepClicked: function(i) { wizard.currentIndex = i }
//   }
Item {
    id: root

    property var    steps:       []
    property int    currentStep: 0          // 0-based
    property int    orientation: Qt.Horizontal
    property color  accentColor: ThemeManager.primaryColor
    property color  textColor:   ThemeManager.textColor
    property color  lineColor:   ThemeManager.borderColor
    property int    dotSize:     28
    property int    fontSize:    12
    property bool   clickable:   true

    signal stepClicked(int index)

    readonly property bool _horiz: orientation === Qt.Horizontal

    implicitWidth:  _horiz ? parent.width  : dotSize + 120
    implicitHeight: _horiz ? dotSize + 28  : steps.length * (dotSize + 20)

    Repeater {
        model: root.steps
        delegate: Item {
            id: stepItem
            property bool done:   index < root.currentStep
            property bool active: index === root.currentStep

            x: root._horiz ? index * (root.width / root.steps.length) : 0
            y: root._horiz ? 0 : index * (root.dotSize + 20)
            width:  root._horiz ? root.width / root.steps.length : root.width
            height: root._horiz ? root.height : root.dotSize + 20

            // Connecting line — drawn forward from THIS step's dot centre to NEXT step's dot centre.
            // Because Repeater creates items in order, later steps render on top → the next dot
            // always covers the connector's end, so no z-fighting artefact.
            Rectangle {
                visible: index < root.steps.length - 1
                color: stepItem.done ? root.accentColor : Qt.rgba(root.lineColor.r, root.lineColor.g, root.lineColor.b, 0.4)
                Behavior on color { ColorAnimation { duration: 200 } }

                // Horizontal: from centre of current dot rightward to centre of next dot
                x:      root._horiz ? parent.width / 2 : root.dotSize / 2 - 1
                y:      root._horiz ? root.dotSize / 2 - 1 : root.dotSize / 2
                width:  root._horiz ? parent.width : 2
                height: root._horiz ? 2 : root.dotSize + 20
            }

            // Step dot
            Rectangle {
                id: dot
                z: 1   // always above connector line within this step item
                anchors.horizontalCenter: root._horiz ? parent.horizontalCenter : undefined
                anchors.left:             root._horiz ? undefined : parent.left
                anchors.top:              parent.top
                width: root.dotSize; height: root.dotSize; radius: root.dotSize / 2
                color: stepItem.done   ? root.accentColor
                     : stepItem.active ? "transparent"
                     :                   Qt.rgba(root.lineColor.r, root.lineColor.g, root.lineColor.b, 0.25)
                border.color: stepItem.done || stepItem.active ? root.accentColor : Qt.rgba(root.lineColor.r, root.lineColor.g, root.lineColor.b, 0.5)
                border.width: stepItem.active ? 2 : 0
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                Text {
                    anchors.centerIn: parent
                    text: stepItem.done ? "✓" : (index + 1).toString()
                    font.pixelSize: 12; font.bold: true
                    color: stepItem.done ? "#FFF" : (stepItem.active ? root.accentColor : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.5))
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            // Label
            Text {
                anchors {
                    top:              root._horiz ? dot.bottom : undefined
                    horizontalCenter: root._horiz ? dot.horizontalCenter : undefined
                    left:             root._horiz ? undefined : dot.right
                    verticalCenter:   root._horiz ? undefined : dot.verticalCenter
                    topMargin:        root._horiz ? 6 : 0
                    leftMargin:       root._horiz ? 0 : 10
                }
                text: modelData
                font.pixelSize: root.fontSize
                font.bold: stepItem.active
                color: stepItem.done || stepItem.active
                       ? root.textColor
                       : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.45)
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.clickable && index <= root.currentStep
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: root.stepClicked(index)
            }
        }
    }
}
