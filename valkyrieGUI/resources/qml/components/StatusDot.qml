import QtQuick 2.15
import App.Theme 1.0

// StatusDot — compact online/status indicator with optional pulse animation.
//
// Usage:
//   StatusDot { status: "online" }
//   StatusDot { status: "busy"; size: 10; showPulse: false }
Item {
    id: root

    property string status:    "online"   // "online"|"offline"|"away"|"busy"|"unknown"
    property int    size:      8
    property bool   showPulse: true
    property bool   showLabel: false
    property string labelText: ""        // custom label; empty = uses status name

    implicitWidth:  root.showLabel ? dot.width + labelItem.width + 6 : root.size
    implicitHeight: root.size

    readonly property color _color: {
        switch(root.status) {
            case "online":  return "#4caf50"
            case "away":    return "#ff9800"
            case "busy":    return "#f44336"
            case "unknown": return "#9e9e9e"
            default:        return "#757575"   // offline
        }
    }

    readonly property bool _isPulsing: root.showPulse && root.status === "online"

    // Pulse ring
    Rectangle {
        id: pulseRing
        anchors.centerIn: dot
        width: root.size; height: root.size; radius: root.size / 2
        color: "transparent"
        border.color: root._color
        border.width: 1.5
        opacity: 0
        visible: root._isPulsing

        SequentialAnimation on opacity {
            running: root._isPulsing
            loops: Animation.Infinite
            NumberAnimation { to: 0.55; duration: 400 }
            PauseAnimation  { duration: 200 }
            NumberAnimation { to: 0.0;  duration: 800 }
        }

        NumberAnimation on scale {
            running: root._isPulsing
            from: 1; to: 2.2
            duration: 1000
            loops: Animation.Infinite
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: dot
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: root.size; height: root.size; radius: root.size / 2
        color: root._color
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    Text {
        id: labelItem
        visible: root.showLabel
        anchors.left: dot.right; anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        text: root.labelText !== "" ? root.labelText : root.status
        font.pixelSize: 12
        color: ThemeManager.textColor
    }
}

