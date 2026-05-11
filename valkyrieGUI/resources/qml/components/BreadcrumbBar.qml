import QtQuick 2.15
import App.Theme 1.0

// BreadcrumbBar — clickable navigation breadcrumb trail.
//
// Usage:
//   BreadcrumbBar {
//       items: [
//           { label: "Home" },
//           { label: "Projects" },
//           { label: "Valkyrie" }
//       ]
//       onItemClicked: function(i, item) { router.navigate(item) }
//   }
Item {
    id: root

    property var    items:      []
    property string separator:  "/"
    property color  textColor:  ThemeManager.textColor
    property color  activeColor: ThemeManager.primaryColor
    property color  hoverColor: ThemeManager.primaryColor
    property int    fontSize:   13
    property int    spacing:    6

    signal itemClicked(int index, var item)

    implicitHeight: crumbRow.implicitHeight
    implicitWidth:  crumbRow.implicitWidth

    Row {
        id: crumbRow
        spacing: root.spacing

        Repeater {
            model: root.items
            delegate: Row {
                spacing: root.spacing

                // Separator
                Text {
                    visible: index > 0
                    text: root.separator; font.pixelSize: root.fontSize
                    color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.35)
                    anchors.verticalCenter: parent.verticalCenter
                }

                // Label
                Text {
                    property bool isLast: index === root.items.length - 1
                    text: modelData.label || ""
                    font.pixelSize: root.fontSize
                    font.bold: isLast
                    color: isLast ? root.activeColor
                                  : (lma.containsMouse ? root.hoverColor
                                                       : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.6))
                    Behavior on color { ColorAnimation { duration: 100 } }
                    anchors.verticalCenter: parent.verticalCenter

                    // Underline on hover for non-last items
                    Rectangle {
                        visible: lma.containsMouse && !parent.isLast
                        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
                        height: 1; color: root.hoverColor
                    }

                    MouseArea {
                        id: lma; anchors.fill: parent; hoverEnabled: true
                        enabled: index < root.items.length - 1
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.itemClicked(index, modelData)
                    }
                }
            }
        }
    }
}

