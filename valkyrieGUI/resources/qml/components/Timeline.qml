import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import App.Theme 1.0

// Timeline — vertical event timeline.
//
// Usage:
//   Timeline {
//       events: [
//           { title: "Started", subtitle: "10:00", icon: "●", color: "#4caf50" },
//           { title: "Running", subtitle: "10:05" },
//           { title: "Done",    subtitle: "10:30", icon: "✓", color: "#3498db" }
//       ]
//   }
Item {
    id: root

    // Each item: { title, subtitle?, icon?, color?, detail? }
    property var    events:       []
    property color  lineColor:    Qt.rgba(ThemeManager.primaryColor.r,
                                          ThemeManager.primaryColor.g,
                                          ThemeManager.primaryColor.b, 0.3)
    property color  dotColor:     ThemeManager.primaryColor
    property int    dotSize:      16
    property int    lineWidth:    2
    property int    itemSpacing:  8
    property int    fontSize:     13
    property int    subtitleSize: 11

    implicitWidth:  300
    implicitHeight: eventsColumn.implicitHeight

    Column {
        id: eventsColumn
        anchors { left: parent.left; right: parent.right; top: parent.top }
        spacing: 0   // spacing is supplied by eventContent.bottomPadding instead

        Repeater {
            model: root.events

            delegate: Row {
                spacing: 12
                width: eventsColumn.width

                // ── Left: dot + connector line ────────────────────────────────
                Item {
                    width: root.dotSize
                    height: eventContent.height

                    // Connector line (shown between items, not after last)
                    Rectangle {
                        visible: index < root.events.length - 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: dot.bottom
                        anchors.bottom: parent.bottom
                        width: root.lineWidth
                        color: root.lineColor
                    }

                    Rectangle {
                        id: dot
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top; anchors.topMargin: 2
                        width: root.dotSize; height: root.dotSize; radius: root.dotSize / 2
                        color: modelData.color !== undefined ? modelData.color : root.dotColor

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon !== undefined ? modelData.icon : ""
                            font.pixelSize: root.dotSize * 0.55
                            color: "#ffffff"
                            visible: modelData.icon !== undefined
                        }
                    }
                }

                // ── Right: content ────────────────────────────────────────────
                Column {
                    id: eventContent
                    width: parent.width - root.dotSize - 12
                    spacing: 2
                    bottomPadding: root.itemSpacing

                    Text {
                        text: modelData.title !== undefined ? modelData.title : ""
                        font.pixelSize: root.fontSize; font.bold: true
                        color: ThemeManager.textColor
                        width: parent.width; wrapMode: Text.WordWrap
                    }

                    Text {
                        visible: modelData.subtitle !== undefined
                        text: modelData.subtitle !== undefined ? modelData.subtitle : ""
                        font.pixelSize: root.subtitleSize
                        color: ThemeManager.textSecondaryColor
                        width: parent.width; wrapMode: Text.WordWrap
                    }

                    Text {
                        visible: modelData.detail !== undefined
                        text: modelData.detail !== undefined ? modelData.detail : ""
                        font.pixelSize: root.subtitleSize - 1
                        color: Qt.rgba(ThemeManager.textColor.r,
                                       ThemeManager.textColor.g,
                                       ThemeManager.textColor.b, 0.5)
                        width: parent.width; wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
