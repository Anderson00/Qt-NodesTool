import QtQuick 2.15
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property alias source: innerIcon.source
    property color color: "white"
    
    implicitWidth: 24
    implicitHeight: 24
    
    Image {
        id: innerIcon
        anchors.fill: parent
        sourceSize: Qt.size(parent.width, parent.height)
        fillMode: Image.PreserveAspectFit
        visible: false
    }
    
    ColorOverlay {
        anchors.fill: innerIcon
        source: innerIcon
        color: root.color
        visible: innerIcon.status === Image.Ready
    }
}

