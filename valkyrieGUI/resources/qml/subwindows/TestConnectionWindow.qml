import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.0
import QtQuick.Controls.Material 2.12

Rectangle {
    anchors.fill: parent
    color: "#333"

    Component.onCompleted: {
        console.log(window);
        console.log(midClient);
    }

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
            console.log(message);

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
            }

            Button {
                id: btnAction
                Layout.preferredWidth: 40
                text: "Send"
                onClicked: {
                    let cmdSplits = cmdLine.text.split(" ");
                    midClient.sendCommand(cmdSplits[0], cmdSplits.slice(1,cmdSplits.length))
                }
            }
        }

        ScrollView {
            id: scroll
            Layout.fillHeight: true
            Layout.fillWidth: true
            ScrollBar.vertical.policy: ScrollBar.AlwaysOn


            TextArea {
                id: resultArea

                color: "green"
                background: Rectangle { color: "#000" }
                enabled: false

            }
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                id: stateText
                Layout.preferredHeight: 25
                Layout.alignment: Qt.AlignVCenter
                color: "green"
                Layout.fillWidth: true
                text: "Initiated"
            }

            TextField {
                Layout.preferredHeight: stateText.height
                Layout.preferredWidth: 120
                id: ipConn
                text: "127.0.0.1"
            }

            Button {
                id: btnConnIp
                Layout.preferredHeight: stateText.height
                text: "Ok"
                onClicked: {
                    midClient.retryConn(stateText.text, 6969);
                }
            }

        }
    }
}
