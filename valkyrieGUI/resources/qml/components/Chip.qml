import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import App.Icons 1.0

// Chip — closeable/selectable pill label with optional icon.
//
// Usage:
//   Chip { label: "Rust"; onClosed: remove() }
//   Chip { label: "Active"; selected: true; selectable: true }
Item {
    id: root

    property string label:       ""
    property string iconSource:  ""   // optional left icon
    property bool   closeable:   true
    property bool   selectable:  false
    property bool   selected:    false
    property color  accentColor: ThemeManager.primaryColor
    property color  chipColor:   Qt.rgba(ThemeManager.textColor.r,
                                         ThemeManager.textColor.g,
                                         ThemeManager.textColor.b, 0.1)
    property color  textColor:   ThemeManager.textColor
    property int    fontSize:    12
    property int    radius:      16

    signal closed()
    signal clicked()

    implicitHeight: 28
    implicitWidth:  row.width + 16

    readonly property color _bg: root.selected
        ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25)
        : root.chipColor

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: root.radius
        color: root._bg
        border.width: root.selected ? 1 : 0
        border.color: root.selected ? root.accentColor : "transparent"
        Behavior on color  { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 4

            // Icon
            SvgIcon {
                visible: root.iconSource !== ""
                width: 14; height: 14
                source: root.iconSource
                color: root.selected ? root.accentColor : root.textColor
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.label
                font.pixelSize: root.fontSize
                color: root.selected ? root.accentColor : root.textColor
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            // Close button
            Rectangle {
                visible: root.closeable
                width: 14; height: 14; radius: 7
                color: closeArea.containsMouse ? Qt.rgba(1,1,1,0.15) : "transparent"
                anchors.verticalCenter: parent.verticalCenter

                SvgIcon {
                    anchors.centerIn: parent
                    width: 10; height: 10
                    source: Icons.close
                    color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.7)
                }

                MouseArea {
                    id: closeArea; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) { mouse.accepted = true; root.closed() }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.selectable || !root.closeable
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.selectable) { root.selected = !root.selected }
                root.clicked()
            }
        }
    }
}

