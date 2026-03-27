import QtQuick 2.12
import Qt5Compat.GraphicalEffects

Item {
    id: root

    property alias source: img.source
    property color color: "#ffffff"
    property int renderSize: 96

    implicitWidth: 20
    implicitHeight: 20

    Image {
        id: img
        anchors.fill: parent
        sourceSize: Qt.size(root.renderSize, root.renderSize)
        smooth: true
        antialiasing: true
        visible: false
    }

    ColorOverlay {
        anchors.fill: img
        source: img
        color: root.color
        smooth: true
        antialiasing: true
    }
}
