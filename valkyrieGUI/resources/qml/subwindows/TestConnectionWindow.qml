import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.0
import QtQuick.Controls.Material 2.12

import Qaterial 1.0 as Qaterial

Rectangle {
    anchors.fill: parent
    color: "#140f07"

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

            Qaterial.TextField {
                id: cmdLine
                Layout.fillWidth: true
                trailingContent: Qaterial.TextFieldButtonContainer
                {
                    Qaterial.TextFieldClearButton {
                        visible: cmdLine.text.length > 0
                    }
                } // TextFieldButtonContainer
            }

            Qaterial.RaisedButton {
                id: btnAction
                text: "Send"                
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

                color: "#e0e7f6"
                background: Rectangle { color: "#21252f" }

                enabled: false

            }
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                id: stateText
                Layout.preferredHeight: 25
                Layout.alignment: Qt.AlignVCenter
                color: "#e0e7f6"
                Layout.fillWidth: true
                text: "Initiated"
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
                text: "Ok"
                onClicked: {
                    midClient.retryConn(ipConn.text, 6969);
                }
            }

        }
    }
}
