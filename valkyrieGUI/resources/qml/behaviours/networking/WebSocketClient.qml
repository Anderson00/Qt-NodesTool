import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import App.Icons 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    property var messages: []

    Connections {
        target: behaviourObject
        function onInternalConnected() {
            statusDot.status = "success"
            appendLog("[connected]", "#4ade80")
        }
        function onInternalDisconnected() {
            statusDot.status = "error"
            appendLog("[disconnected]", "#f87171")
        }
        function onInternalError(msg) {
            appendLog("[error] " + msg, "#fb923c")
        }
        function onInternalMessage(msg) {
            appendLog(msg, ThemeManager.textColor)
        }
    }

    function appendLog(text, color) {
        var entry = {text: text, color: color}
        var arr = messages.slice()
        arr.push(entry)
        if (arr.length > 50) arr = arr.slice(arr.length - 50)
        messages = arr
        msgList.model = messages
        Qt.callLater(function() { msgList.positionViewAtEnd() })
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Header ────────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 34
            color: ThemeManager.surfaceColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8; anchors.rightMargin: 8
                spacing: 6

                StatusDot {
                    id: statusDot
                    status: behaviourObject && behaviourObject.isConnected ? "success" : "error"
                }

                Text {
                    text: "WebSocket"
                    color: ThemeManager.textColor; font.pixelSize: 11; font.bold: true
                }

                Text {
                    text: behaviourObject ? (behaviourObject.isConnected ? "Connected" : "Disconnected") : "–"
                    color: behaviourObject && behaviourObject.isConnected ? ThemeManager.successColor : ThemeManager.textSecondaryColor
                    font.pixelSize: 10
                    Layout.fillWidth: true
                }

                Text {
                    text: behaviourObject ? (behaviourObject.messageCount + " msg") : ""
                    color: ThemeManager.textSecondaryColor; font.pixelSize: 10
                }
            }
        }

        // ── URL row ───────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 38
            color: ThemeManager.backgroundColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6; anchors.rightMargin: 6
                anchors.topMargin: 4; anchors.bottomMargin: 4
                spacing: 4

                CustomTextField {
                    id: urlField
                    Layout.fillWidth: true
                    placeholderText: "ws://host:port/path"
                    text: behaviourObject ? behaviourObject.url : ""
                }

                NewButton {
                    Layout.preferredWidth: 64; Layout.fillHeight: true
                    variant: behaviourObject && behaviourObject.isConnected ? "outlined" : "filled"
                    text: behaviourObject && behaviourObject.isConnected ? "Disc." : "Connect"
                    backgroundColor: behaviourObject && behaviourObject.isConnected
                                     ? ThemeManager.errorColor : ThemeManager.primaryColor
                    onClicked: {
                        if (behaviourObject.isConnected)
                            behaviourObject.disconnect()
                        else
                            behaviourObject.connectTo(urlField.text)
                    }
                }
            }
        }

        // ── Options row ───────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 28
            color: ThemeManager.surfaceColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8; anchors.rightMargin: 8
                spacing: 8

                Text { text: "Auto-reconnect"; font.pixelSize: 10; color: ThemeManager.textSecondaryColor }
                CustomSwitch {
                    checked: behaviourObject ? behaviourObject.autoReconnect : false
                    onCheckedChanged: if (behaviourObject) behaviourObject.autoReconnect = checked
                }
                Item { Layout.fillWidth: true }
                NewButton {
                    Layout.preferredWidth: 50; height: 20
                    variant: "outlined"; text: "Clear"
                    onClicked: { root.messages = []; msgList.model = [] }
                }
            }
        }

        // ── Message log ───────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true
            color: Qt.rgba(0, 0, 0, 0.3)

            ListView {
                id: msgList
                anchors.fill: parent
                anchors.margins: 4
                clip: true
                spacing: 1

                delegate: Text {
                    width: msgList.width - 8
                    text: modelData.text
                    color: modelData.color
                    font.pixelSize: 10
                    font.family: "monospace"
                    wrapMode: Text.WrapAnywhere
                }
            }
        }

        // ── Send row ──────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 36
            color: ThemeManager.surfaceColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6; anchors.rightMargin: 6
                anchors.topMargin: 3; anchors.bottomMargin: 3
                spacing: 4

                CustomTextField {
                    id: sendField
                    Layout.fillWidth: true
                    placeholderText: "Send message..."
                    enabled: behaviourObject && behaviourObject.isConnected
                    Keys.onReturnPressed: sendBtn.clicked()
                }
                NewButton {
                    id: sendBtn
                    Layout.preferredWidth: 50; Layout.fillHeight: true
                    variant: "filled"; text: "Send"
                    backgroundColor: ThemeManager.primaryColor
                    enabled: behaviourObject && behaviourObject.isConnected && sendField.text.length > 0
                    onClicked: {
                        behaviourObject.send(sendField.text)
                        sendField.text = ""
                    }
                }
            }
        }
    }
}
