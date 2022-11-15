import QtQuick 2.9
import QtQuick.Templates 2.2 as T
import QtQuick.Controls 2.2
import QtQuick.Controls.impl 2.2
import QtQuick.Layouts 1.0
import QtQuick.Controls.Material 2.2
import QtQuick.Controls.Material.impl 2.2

import Qaterial 1.0 as Qaterial

Button {
    id: control

    property string textColor: "#fff"
    property int radius: 2
    property string backgroundColor: Material.primaryColor
    property string iconSource: ''
    property int iconSize: 18

    implicitWidth: Math.max(background ? background.implicitWidth : 0,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(background ? background.implicitHeight : 0,
                             contentItem.implicitHeight + topPadding + bottomPadding)
    baselineOffset: contentItem.y + contentItem.baselineOffset

    // external vertical padding is 6 (to increase touch area)
//    padding: 12
//    leftPadding: padding - 4
//    rightPadding: padding - 4

    Material.elevation: flat ? control.down || control.hovered ? 2 : 0
                             : control.down ? 8 : 2
    Material.background: flat ? "transparent" : control.backgroundColor

    contentItem: RowLayout {
        anchors.fill: parent.Center

        Qaterial.Icon {
            id: btIcon
            Layout.preferredHeight: control.iconSize
            Layout.fillWidth: true
            icon: control.iconSource
            antialiasing: true
        }

        Label {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            visible: btIcon.icon ? false : true
            text: control.text
            font: control.font
            color: textColor
            elide: Text.ElideRight
            verticalAlignment: Label.AlignVCenter
            horizontalAlignment: Label.AlignHCenter
        }
    }

    // TODO: Add a proper ripple/ink effect for mouse/touch input and focus state
    background: Rectangle {
        implicitWidth: 64
        implicitHeight: 40

        // external vertical padding is 6 (to increase touch area)
        y: 6
        width: parent.width
        height: parent.height - 12
        radius: control.radius
        color: control.backgroundColor


        Ripple {
            clipRadius: 2
            width: parent.width
            height: parent.height
            pressed: control.pressed
            anchor: control
            active: control.down || control.visualFocus || control.hovered
            color: control.Material.rippleColor
        }
    }
}
