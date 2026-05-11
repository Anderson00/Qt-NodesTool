import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls.Material 2.15
import Qt5Compat.GraphicalEffects
import QtQuick.Controls.Material.impl 2.12
import App.Theme 1.0

Rectangle {
    id: root
    property alias iconSource: iconImage.source
    property alias iconSize: iconImage.width

    signal pressed()

    radius: root.width
    Layout.preferredWidth: 80
    Layout.preferredHeight: 80

    RippleEffectBackground {
        active: mouseArea.enabled
        radius: root.radius
        ripplePressed: mouseArea.pressed
        anchors.fill: parent
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        clip: true

        onPressed: root.pressed()

        RowLayout {
            anchors.fill: parent

            Image {
                id: iconImage
                source: ""
                width: 24
                height: 24
                fillMode: Image.PreserveAspectFit
                Layout.alignment: Qt.AlignCenter
            }
        }
    }
}

