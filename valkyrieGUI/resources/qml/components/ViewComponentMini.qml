import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.14
import QtQuick.Window 2.2
import QtQuick 2.14
import QtQml 2.14

import Qaterial 1.0 as Qaterial

Rectangle{
    id: card
    color: "#222"
    border.width: 1
    border.color: Material.accentColor
    radius: 4

    ColumnLayout {
        anchors.fill: parent

        anchors.margins: 4

        Label {
            font.pixelSize: 16
            text: "FileLoad"
        }

        Rectangle {
            //Layout.fillWidth: true
            Layout.preferredWidth: parent.width + 8
            Layout.leftMargin: -4
            height: card.border.width
            color: card.border.color
        }

        RowLayout {
            width: parent.width
            height: 20
            Qaterial.Icon {
                Layout.preferredHeight: 20
                icon: Qaterial.Icons.upload
            }

            Label {
                text: "3"
            }

            Qaterial.Icon {
                Layout.preferredHeight: 20
                icon: Qaterial.Icons.download
            }

            Label {
                text: "1"
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
