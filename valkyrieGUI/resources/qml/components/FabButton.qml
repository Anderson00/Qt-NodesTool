import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects
import App.Theme 1.0

AbstractButton {
    id: control

    property alias  iconSource: icon.source
    property color  iconColor:  ThemeManager.primaryColor
    property int    iconSize:   20
    property int    buttonSize: 40
    property bool   elevated:   true

    implicitWidth:  buttonSize
    implicitHeight: buttonSize
    padding: 0

    background: Rectangle {
        radius: control.buttonSize / 2
        color: control.pressed ? Qt.rgba(ThemeManager.secondaryColor.r,
                                         ThemeManager.secondaryColor.g,
                                         ThemeManager.secondaryColor.b, 1)
             : control.hovered ? Qt.rgba(ThemeManager.surfaceColor.r,
                                         ThemeManager.surfaceColor.g,
                                         ThemeManager.surfaceColor.b, 0.92)
             : ThemeManager.surfaceColor
        border.color: ThemeManager.borderColor
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }

        layer.enabled: control.elevated
        layer.effect: DropShadow {
            transparentBorder: true
            horizontalOffset: 0
            verticalOffset: 2
            radius: 6
            samples: 13
            color: Qt.rgba(0, 0, 0, 0.28)
        }
    }

    contentItem: SvgIcon {
        id: icon
        anchors.centerIn: parent
        width:  control.iconSize
        height: control.iconSize
        color:  control.iconColor
    }

    MouseArea {
        id: rippleMa
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed:  function(e) { e.accepted = false }
        onReleased: function(e) { e.accepted = false }
    }
}
