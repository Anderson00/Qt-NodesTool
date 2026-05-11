import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects
import App.Theme 1.0

// Supports the standard AbstractButton icon group (icon.source, icon.color,
// icon.width, icon.height) with proper SVG ColorOverlay recoloring.
ToolButton {
    id: control

    implicitWidth:  40
    implicitHeight: 40
    padding: 0
    opacity: enabled ? 1.0 : 0.38

    background: Rectangle {
        radius: 4
        color: control.pressed
               ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.18)
               : control.hovered
                 ? Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.10)
                 : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    contentItem: Item {
        // Hidden source image — used as input to ColorOverlay
        Image {
            id: _img
            anchors.centerIn: parent
            width:  control.icon.width  > 0 ? control.icon.width  : 22
            height: control.icon.height > 0 ? control.icon.height : 22
            sourceSize: Qt.size(width, height)
            source:     control.icon.source
            fillMode:   Image.PreserveAspectFit
            visible:    false
        }

        ColorOverlay {
            anchors.fill: _img
            source:       _img
            color:        control.icon.color
            visible:      _img.status === Image.Ready
        }
    }
}
