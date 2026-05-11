import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects
import App.Theme 1.0

Button {
    id: control
    
    property alias iconSource: innerIcon.source
    property color iconColor: ThemeManager.textColor
    
    implicitWidth: 40
    implicitHeight: 40
    
    background: Rectangle {
        implicitWidth: 40
        implicitHeight: 40
        radius: 4
        color: control.pressed ? Qt.rgba(ThemeManager.accentColor.r, ThemeManager.accentColor.g, ThemeManager.accentColor.b, 0.2)
             : control.hovered ? Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.1)
             : "transparent"
        
        border.width: control.checked ? 1 : 0
        border.color: ThemeManager.accentColor
    }
    
    contentItem: Item {
        Image {
            id: innerIcon
            anchors.centerIn: parent
            width: 24
            height: 24
            sourceSize: Qt.size(24, 24)
            fillMode: Image.PreserveAspectFit
            
            // Note: In Qt 6, we can use the color property if it's an Icon or use a ColorOverlay
            // For simplicity with standard Image, we'll use a shader or just icons that are already colored.
            // But usually we want dynamic coloring.
        }
        
        // Simple color overlay for Qt 6
        ColorOverlay {
            anchors.fill: innerIcon
            source: innerIcon
            color: control.iconColor
            visible: innerIcon.status === Image.Ready
        }
    }
}

