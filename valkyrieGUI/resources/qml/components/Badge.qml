import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0

// Badge — numeric/dot indicator that wraps another item.
// Place it as a sibling and anchor, or use the overlay property pattern.
//
// Usage (standalone):
//   Badge {
//       count: 5
//       anchors.top: someButton.top
//       anchors.right: someButton.right
//   }
//
// Or use BadgeOverlay pattern by parenting inside a Stack/Item.
Item {
    id: root

    property int    count:      0           // > 0 shows number; -1 shows dot only
    property int    max:        99          // numbers above this show "max+"
    property string dotText:    ""          // custom text instead of count
    property color  badgeColor: ThemeManager.dangerColor
    property color  textColor:  "#ffffff"
    property int    fontSize:   10
    property int    minSize:    18

    // Drive visibility via binding instead of property override (visible is FINAL on Item)
    visible: count !== 0 || dotText !== ""

    readonly property string _label: {
        if (root.dotText !== "") return root.dotText
        if (root.count < 0)     return ""
        if (root.count > root.max) return root.max + "+"
        return root.count.toString()
    }
    readonly property bool _dotMode: root.count < 0 && root.dotText === ""

    implicitWidth:  _dotMode ? 10 : Math.max(root.minSize, labelText.width + 8)
    implicitHeight: _dotMode ? 10 : root.minSize

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.badgeColor

        Text {
            id: labelText
            anchors.centerIn: parent
            text: root._label
            visible: !root._dotMode
            color: root.textColor
            font.pixelSize: root.fontSize
            font.bold: true
        }
    }
}

