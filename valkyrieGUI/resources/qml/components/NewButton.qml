import QtQuick 2.9
import QtQuick.Templates 2.2 as T
import QtQuick.Controls 2.2
import QtQuick.Controls.impl 2.2
import QtQuick.Layouts 1.0
import QtQuick.Controls.Material 2.2
import QtQuick.Controls.Material.impl 2.2
import App.Theme 1.0

import Qaterial 1.0 as Qaterial

Button {
    id: control

    property string textColor: "#fff"
    property int radius: 8
    property string backgroundColor: ThemeManager.primaryColor
    property string iconSource: ''
    property int iconSize: 18

    implicitWidth: Math.max(background ? background.implicitWidth : 0,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(background ? background.implicitHeight : 0,
                             contentItem.implicitHeight + topPadding + bottomPadding)
    baselineOffset: contentItem.y + contentItem.baselineOffset

    Material.elevation: flat ? control.down || control.hovered ? 2 : 0
                             : control.down ? 8 : 2
    Material.background: flat ? "transparent" : control.backgroundColor

    state: "rounded"

    states:[
        State {
            name: "default"

            PropertyChanges {
                target: myRect;
                color: "red"
            }
        },
        State {
            name: "rounded"

            PropertyChanges {
                target: control;
                radius: control.width

                width: 60
                height: 60
            }
        }

    ]

    // external vertical padding is 6 (to increase touch area)
//    padding: 12
//    leftPadding: padding - 4
//    rightPadding: padding - 4

    contentItem: RowLayout {
        anchors.centerIn: parent

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
        implicitWidth: control.width
        implicitHeight: control.height

        // external vertical padding is 6 (to increase touch area)
        y: 6
        width: parent.width
        height: parent.height - 12
        radius: control.radius
        color: control.backgroundColor
        clip: true

        Ripple {
            clipRadius: control.radius
            width: parent.width
            height: parent.height
            pressed: control.pressed
            anchor: control
            active: control.down || control.visualFocus || control.hovered
            color: control.Material.rippleColor
        }
    }
}
