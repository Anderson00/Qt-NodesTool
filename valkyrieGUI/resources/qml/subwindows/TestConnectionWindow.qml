import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.0
import QtQuick.Controls.Material 2.12

import App.Theme 1.0
import App.Icons 1.0


Rectangle {
    anchors.fill: parent
    color: ThemeManager.backgroundColor

    Connections {
        target: midClient

        function onStateChanged(state){
            switch(state){
            case 0:
                stateText.text = "Unconnected"
                break;
            case 1:
                stateText.text = "HostLookupState";
                break;
            case 2:
                stateText.text = "ConnectingState";
                break;
            case 3:
                stateText.text = "ConnectedState";
                break;
            case 4:
                stateText.text = "BoundState";
                break;
            case 5:
                stateText.text = "ListeningState";
                break;
            case 6:
                stateText.text = "ClosingState";
                break;
            }
        }

        function onResultCommand(message){
            if(message){
                resultArea.text += "Resposta: "+message["result"]+"\n";
            }
        }
    }


    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40

            TextField {
                id: cmdLine
                Layout.fillWidth: true
                placeholderText: qsTr("Command...")
                rightPadding: clearBtn.visible ? clearBtn.width + 4 : 0

                AppBarButton {
                    id: clearBtn
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 2 }
                    visible: cmdLine.text.length > 0
                    width: 28; height: 28; padding: 0
                    icon.source: Icons.close
                    icon.color:  "#888"
                    icon.width: 14; icon.height: 14
                    onClicked: cmdLine.clear()
                }
            }

            Button {
                id: btnAction
                text: qsTr("Send")
                onClicked: {
                    let cmdSplits = cmdLine.text.split(" ");
                    midClient.sendCommand(cmdSplits[0], cmdSplits.slice(1,cmdSplits.length))
                }
            }
        }

        ScrollView {
            id: scroll
            clip: true
            Layout.fillHeight: true
            Layout.fillWidth: true
            ScrollBar.vertical.policy: ScrollBar.AlwaysOn
            background: Rectangle { color: "#21252f" }


            TextArea {
                id: resultArea
                width: scroll.parent.width
                //height: scroll.height

                color: ThemeManager.textColor
                background: Rectangle { color: ThemeManager.surfaceColor }

                enabled: false

            }
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                id: stateText
                Layout.preferredHeight: 25
                Layout.alignment: Qt.AlignVCenter
                color: ThemeManager.textColor
                Layout.fillWidth: true
                text: qsTr("Initiated")
            }

            TextField {
                id: ipConn
                Layout.preferredHeight: stateText.height
                Layout.preferredWidth: 120                
                text: "127.0.0.1"
            }

            Button {
                id: btnConnIp
                Layout.preferredHeight: stateText.height
                text: qsTr("Ok")
                onClicked: {
                    midClient.retryConn(ipConn.text, 6969);
                }
            }

        }
    }
}

