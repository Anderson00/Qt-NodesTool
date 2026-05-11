import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0

// Skeleton — shimmer placeholder for loading states.
// Supports "rect", "circle", "text" shapes and a shimmer animation.
//
// Usage:
//   Skeleton { width: 200; height: 16; shape: "rect" }
//   Skeleton { width: 48;  height: 48; shape: "circle" }
//   Column { Repeater { model: 3; Skeleton { width: 200; height: 12; shape: "text" } } }
Item {
    id: root

    property string shape:   "rect"     // "rect" | "circle" | "text"
    property color  baseColor:    Qt.rgba(ThemeManager.textColor.r,
                                          ThemeManager.textColor.g,
                                          ThemeManager.textColor.b, 0.08)
    property color  shimmerColor: Qt.rgba(ThemeManager.textColor.r,
                                          ThemeManager.textColor.g,
                                          ThemeManager.textColor.b, 0.18)
    property bool   animate: true
    property int    radius:  4          // only for "rect"

    implicitWidth:  120
    implicitHeight: 16

    readonly property int _r: {
        if (root.shape === "circle") return Math.min(root.width, root.height) / 2
        if (root.shape === "text")   return root.height / 2
        return root.radius
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: root._r
        color: root.baseColor
        clip: true

        // Shimmer overlay
        Rectangle {
            id: shimmer
            width: parent.width * 0.5
            height: parent.height
            radius: root._r
            color: "transparent"
            visible: root.animate

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: root.shimmerColor }
                GradientStop { position: 1.0; color: "transparent" }
            }

            NumberAnimation on x {
                running: root.animate && root.visible
                from: -bg.width * 0.5
                to:   bg.width
                duration: 1200
                loops: Animation.Infinite
                easing.type: Easing.InOutSine
            }
        }
    }
}
