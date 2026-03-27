import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Controls.Material.impl 2.12
import App.Theme 1.0

import Qaterial 1.0 as Qaterial

Button {
    id: control

    // -- Public API --
    property string variant: "filled"  // "filled", "outlined", "text", "rounded"
    property string textColor: {
        switch (variant) {
            case "outlined": return control.backgroundColor
            case "text":     return control.backgroundColor
            default:         return "#fff"
        }
    }
    property int radius: variant === "rounded" ? height / 2 : 8
    property string backgroundColor: ThemeManager.primaryColor
    property string iconSource: ""
    property int iconSize: 18
    property int borderWidth: variant === "outlined" ? 2 : 0

    // -- Internal colors --
    readonly property color __bgColor: {
        switch (variant) {
            case "outlined": return "transparent"
            case "text":     return "transparent"
            default:         return control.backgroundColor
        }
    }
    readonly property color __hoverColor: {
        if (variant === "outlined" || variant === "text")
            return Qt.rgba(Qt.color(control.backgroundColor).r,
                           Qt.color(control.backgroundColor).g,
                           Qt.color(control.backgroundColor).b, 0.08)
        return Qt.darker(control.backgroundColor, 1.1)
    }
    readonly property color __pressColor: {
        if (variant === "outlined" || variant === "text")
            return Qt.rgba(Qt.color(control.backgroundColor).r,
                           Qt.color(control.backgroundColor).g,
                           Qt.color(control.backgroundColor).b, 0.16)
        return Qt.darker(control.backgroundColor, 1.25)
    }

    flat: variant === "text"
    padding: 12
    leftPadding: 16
    rightPadding: 16
    topPadding: 8
    bottomPadding: 8

    contentItem: Item {
        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: (control.iconSource !== "" && control.text !== "") ? 8 : 0

            Qaterial.Icon {
                id: btIcon
                visible: control.iconSource !== ""
                width: control.iconSize
                height: control.iconSize
                anchors.verticalCenter: parent.verticalCenter
                icon: control.iconSource
                color: control.textColor
                antialiasing: true
            }

            Text {
                visible: control.text !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: control.text
                font: control.font
                color: control.textColor
                elide: Text.ElideRight
            }
        }
    }

    background: Rectangle {
        id: bgRect
        implicitWidth: 64
        implicitHeight: 40
        radius: control.radius
        color: control.down ? control.__pressColor
             : control.hovered ? control.__hoverColor
             : control.__bgColor
        border.width: control.borderWidth
        border.color: control.borderWidth > 0 ? control.backgroundColor : "transparent"
        clip: true

        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        // Ripple effect
        Rectangle {
            id: ripple
            property real cx: bgRect.width / 2
            property real cy: bgRect.height / 2
            x: cx - width / 2
            y: cy - height / 2
            width: 0
            height: width
            radius: width / 2
            color: Qt.rgba(1, 1, 1, 0.25)
            opacity: 0
            visible: false

            // Expand animation
            ParallelAnimation {
                id: rippleEnter
                NumberAnimation {
                    target: ripple; property: "width"
                    from: 0; to: Math.max(bgRect.width, bgRect.height) * 2.5
                    duration: 400; easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: ripple; property: "opacity"
                    from: 0.35; to: 0.35
                    duration: 400
                }
            }

            // Fade out animation
            NumberAnimation {
                id: rippleExit
                target: ripple; property: "opacity"
                to: 0; duration: 300; easing.type: Easing.InQuad
                onFinished: { ripple.visible = false; ripple.width = 0 }
            }
        }

        MouseArea {
            id: rippleArea
            anchors.fill: parent
            hoverEnabled: true

            onPressed: function(mouse) {
                ripple.cx = mouse.x
                ripple.cy = mouse.y
                ripple.visible = true
                rippleExit.stop()
                rippleEnter.start()
                mouse.accepted = false
            }
            onReleased: function(mouse) {
                rippleEnter.stop()
                rippleExit.start()
                mouse.accepted = false
            }
            onCanceled: {
                rippleEnter.stop()
                rippleExit.start()
            }

            // Pass through all events to the button
            propagateComposedEvents: true
            onClicked: function(mouse) { mouse.accepted = false }
            onDoubleClicked: function(mouse) { mouse.accepted = false }
        }
    }
}
