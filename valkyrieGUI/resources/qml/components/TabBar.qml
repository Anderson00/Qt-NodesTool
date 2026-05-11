import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0

// TabBar — icon + label tab navigation bar.
//
// Usage:
//   TabBar {
//       tabs: [
//           { label: "Overview",  icon: "home"   },
//           { label: "Nodes",     icon: "graph"  },
//           { label: "Settings",  icon: "cog"    }
//       ]
//       currentIndex: 0
//       onTabChanged: function(i) { stack.currentIndex = i }
//   }
Item {
    id: root

    property var    tabs:         []
    property int    currentIndex: 0
    property color  accentColor:  ThemeManager.primaryColor
    property color  bgColor:      ThemeManager.backgroundColor
    property color  textColor:    ThemeManager.textColor
    property int    tabHeight:    42
    property int    fontSize:     12
    property bool   showIcons:    true
    property bool   animated:     true

    signal tabChanged(int index)

    implicitHeight: root.tabHeight

    Rectangle {
        anchors.fill: parent
        color: root.bgColor

        // Animated selection indicator (underline)
        Rectangle {
            id: _indicator
            height: 2; color: root.accentColor; radius: 1
            anchors.bottom: parent.bottom
            x: root.tabs.length > 0 ? (root.currentIndex * (parent.width / root.tabs.length)) : 0
            width: root.tabs.length > 0 ? (parent.width / root.tabs.length) : 0
            Behavior on x { enabled: root.animated; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        }

        Rectangle {
            anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
            height: 1; color: ThemeManager.borderColor; opacity: 0.4
        }

        Row {
            anchors.fill: parent

            Repeater {
                model: root.tabs
                delegate: Item {
                    width: parent.width / root.tabs.length
                    height: root.tabHeight

                    Column {
                        anchors.centerIn: parent; spacing: 2

                        Text {
                            visible: root.showIcons && modelData.icon !== undefined && modelData.icon !== ""
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.icon || ""; font.pixelSize: 16
                            color: index === root.currentIndex ? root.accentColor : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.5)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.label || ""
                            font.pixelSize: root.fontSize
                            font.bold: index === root.currentIndex
                            color: index === root.currentIndex ? root.accentColor : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.55)
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.currentIndex = index
                            root.tabChanged(index)
                        }
                    }
                }
            }
        }
    }
}

