import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0

// SegmentedControl — mutually exclusive pill-tab buttons (iOS / Material 3 style).
//
// Usage:
//   SegmentedControl {
//       model: ["Day", "Week", "Month"]
//       currentIndex: 0
//       onCurrentIndexChanged: console.log(currentIndex)
//   }
Item {
    id: root

    property var    model:        []
    property int    currentIndex: 0
    property color  accentColor:  ThemeManager.primaryColor
    property color  trackColor:   Qt.rgba(ThemeManager.textColor.r,
                                          ThemeManager.textColor.g,
                                          ThemeManager.textColor.b, 0.08)
    property color  labelColor:   ThemeManager.textColor
    property int    radius:       6
    property int    itemHeight:   32
    property int    fontSize:     12
    property bool   animated:     true

    signal itemClicked(int index, string label)

    implicitHeight: root.itemHeight
    implicitWidth:  200

    // Background track
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color:  root.trackColor
        border.width: 1
        border.color: Qt.rgba(ThemeManager.borderColor.r,
                              ThemeManager.borderColor.g,
                              ThemeManager.borderColor.b, 0.3)
    }

    // Animated selection indicator
    Rectangle {
        id: indicator
        width:  root.model.length > 0 ? parent.width / root.model.length - 4 : 0
        height: parent.height - 4
        radius: root.radius - 1
        y: 2
        x: root.model.length > 0
           ? root.currentIndex * (parent.width / root.model.length) + 2
           : 2
        color: root.accentColor

        Behavior on x { enabled: root.animated; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        // Subtle shadow
        layer.enabled: true
        layer.effect: null
    }

    Row {
        anchors.fill: parent
        spacing: 0

        Repeater {
            model: root.model

            delegate: Item {
                width:  root.width  / root.model.length
                height: root.itemHeight

                Text {
                    anchors.centerIn: parent
                    text: modelData
                    font.pixelSize: root.fontSize
                    font.bold: root.currentIndex === index
                    color: root.currentIndex === index
                           ? "#ffffff"
                           : Qt.rgba(root.labelColor.r, root.labelColor.g, root.labelColor.b, 0.65)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.currentIndex = index

                        root.itemClicked(index, root.model[index])
                    }
                }
            }
        }
    }
}

