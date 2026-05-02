import QtQuick 2.4
import QtQuick.Controls.Material 2.12
import QtQuick.Controls.Material.impl 2.12
import Qt5Compat.GraphicalEffects
import App.Theme 1.0

Item {
    id: root

    property color color: ThemeManager.primaryColor
    property color borderColor: ThemeManager.borderColor
    property int borderWidth: 0
    property int radius: 4

    property bool ripplePressed: false
    property bool active: true
    property double rippleAlpha: 0.5
    property color baseColor: Qt.darker(ThemeManager.primaryColor, 0.5)
    property color rippleColor: Qt.rgba(baseColor.r, baseColor.g, baseColor.b, rippleAlpha)

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: root.radius
        visible: false
    }

    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        color: root.color
        border.color: root.borderColor
        border.width: root.borderWidth
        radius: root.radius
        clip: true

        Ripple {
            pressed: root.ripplePressed
            active: root.active
            color: root.active ? root.rippleColor : Material.rippleColor
            anchor: parent
            anchors.fill: parent
            clipRadius: root.radius
            layer.enabled: true

        }
    }
}
