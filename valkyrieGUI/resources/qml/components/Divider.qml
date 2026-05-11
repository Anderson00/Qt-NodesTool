import QtQuick 2.15
import App.Theme 1.0

// Divider — horizontal or vertical line with optional centered label.
//
// Usage:
//   Divider { }
//   Divider { label: "OR"; orientation: Qt.Horizontal }
//   Divider { orientation: Qt.Vertical; height: 40 }
Item {
    id: root

    property int    orientation: Qt.Horizontal
    property string label:       ""
    property color  color:       Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.45)
    property int    thickness:   1
    property int    fontSize:    11
    property color  labelColor:  ThemeManager.textSecondaryColor
    property int    labelSpacing: 10

    readonly property bool _horiz: orientation === Qt.Horizontal

    implicitWidth:  _horiz ? 200 : thickness
    implicitHeight: _horiz ? (label !== "" ? labelTxt.implicitHeight + 4 : thickness) : 40

    // Horizontal with label
    Item {
        visible: root._horiz
        anchors.fill: parent

        Row {
            anchors.centerIn: parent
            width: parent.width
            spacing: 0

            // Left line
            Rectangle {
                height: root.thickness
                width: root.label !== "" ? (parent.width - labelTxt.width - root.labelSpacing * 2) / 2 : parent.width
                anchors.verticalCenter: parent.verticalCenter
                color: root.color
            }

            // Label
            Text {
                id: labelTxt
                visible: root.label !== ""
                text: root.label
                font.pixelSize: root.fontSize
                color: root.labelColor
                leftPadding: root.labelSpacing; rightPadding: root.labelSpacing
                anchors.verticalCenter: parent.verticalCenter
            }

            // Right line
            Rectangle {
                visible: root.label !== ""
                height: root.thickness
                width: (parent.width - labelTxt.width - root.labelSpacing * 2) / 2
                anchors.verticalCenter: parent.verticalCenter
                color: root.color
            }
        }
    }

    // Vertical line
    Rectangle {
        visible: !root._horiz
        anchors.centerIn: parent
        width: root.thickness; height: parent.height
        color: root.color
    }
}
