import QtQuick 2.4
import QtQuick.Controls 2.0
import QtQuick.Controls.Material 2.12
import QtQuick.Controls.Material.impl 2.12
import QtQuick.Layouts 1.0
import QtGraphicalEffects 1.15
import Qaterial 1.0 as Qaterial

ColumnLayout {
    id: root
    width: parent.width + 8
    height: 40
    spacing: 0

    property alias title: buttonBody.text
    property alias loader: loaderBody.sourceComponent
    property  int loaderHeight
    property bool opened: false

    // TODO: extract this component
    Button {
        id: buttonBody
        Layout.preferredWidth: root.width
        Layout.preferredHeight: 40

        onClicked: {
            root.opened = !root.opened
        }

        background: Rectangle{
            color: "#222"
            anchors.fill: parent
        }

        contentItem: RowLayout{
            anchors.fill: parent
            Label {
                id: titleLabel
                text: buttonBody.text
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.alignment: Qt.AlignCenter
                color: Material.accentColor
                font.pixelSize: 12
            }

            Image {
                id: iconArrow
                Layout.preferredHeight: 20
                Layout.preferredWidth: 20

                source: `qrc:/Qaterial/Icons/arrow-down.svg`
                rotation: root.opened? 180 : 0

                ColorOverlay {
                    anchors.fill: iconArrow
                    source: iconArrow
                    color: Material.accentColor
                }
            }
        }

        Ripple {
            id: ripple
            anchors.horizontalCenter: parent.horizontalCenter
            clipRadius: 0
            width: parent.width
            height: 40
            pressed: buttonBody.pressed
            active: buttonBody.down || buttonBody.visualFocus || buttonBody.hovered
            color: "#20FFFFFF"
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle
                {
                    width: ripple.width
                    height: ripple.height
                    radius: 0
                }
            }
        }
    }


    Rectangle {
        id: loaderBackground
        color: "#444"
        Layout.preferredWidth: parent.width
        Layout.preferredHeight: root.opened ? loaderBody.height : 0
        clip: true

        Behavior on Layout.preferredHeight {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
        }

        Loader {
            id: loaderBody
            width: parent.width
            height: loaderHeight
        }

    }
}
