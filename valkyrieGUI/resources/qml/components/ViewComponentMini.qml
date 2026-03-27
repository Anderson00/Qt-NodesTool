import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.14
import QtQuick.Window 2.2
import QtQuick 2.14
import QtQml 2.14
import App.Theme 1.0

import Qaterial 1.0 as Qaterial

Rectangle{
    id: card

    property string name: ''
    property string desc: ''
    property int n_inputs: 0
    property int n_outputs: 0

    signal doubleClicked();

    color: "#222"
    border.width: 1
    border.color: ThemeManager.primaryColor
    radius: 4

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        onHoveredChanged: {
            if(containsMouse)
                card.color = "#333"
            else
                card.color = "#222"
        }

        onDoubleClicked: {
            card.doubleClicked()
        }
    }

    ColumnLayout {
        anchors.fill: parent

        anchors.margins: 4

        Label {
            Layout.fillWidth: true
            font.pixelSize: 16
            text: card.name
            elide: "ElideRight"
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
            SvgIcon {
                Layout.preferredHeight: 20
                Layout.preferredWidth: 20
                source: Qaterial.Icons.upload
                color: card.border.color
            }

            Label {
                text: n_outputs
            }

            SvgIcon {
                Layout.preferredHeight: 20
                Layout.preferredWidth: 20
                source: Qaterial.Icons.download
                color: card.border.color
            }

            Label {
                text: n_inputs
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.rightMargin: 4
            height: 1
            color: "#111"
        }

        Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            font.pixelSize: 12
            text: card.desc
            wrapMode: "WordWrap"
            elide: "ElideRight"
        }

        RowLayout {
            Button {
                z: 10
                visible: false
                Layout.preferredHeight: 30
                text: "ok"

                onClicked: {
                    console.log("ewfewf")
                }
            }
        }
    }
}
