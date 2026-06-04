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

    property int inTokens: 0
    property int outTokens: 0

    Connections {
        target: behaviourObject

        function onInternalResponse(text) {
            responseArea.text = text
        }

        function onInternalError(msg) {
            responseArea.text = qsTr("Error: ") + msg
        }

        function onInternalTokens(inT, outT) {
            root.inTokens = inT
            root.outTokens = outT
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // ── Model selector ────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: qsTr("Model:")
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 11
            }

            Chip {
                label: qsTr("Haiku")
                closeable: false
                selectable: true
                selected: behaviourObject ? behaviourObject.model === "claude-haiku-4-5-20251001" : true
                onClicked: behaviourObject.setModel("claude-haiku-4-5-20251001")
            }

            Chip {
                label: qsTr("Sonnet")
                closeable: false
                selectable: true
                selected: behaviourObject ? behaviourObject.model === "claude-sonnet-4-5-20251001" : false
                onClicked: behaviourObject.setModel("claude-sonnet-4-5-20251001")
            }

            Chip {
                label: qsTr("Opus")
                closeable: false
                selectable: true
                selected: behaviourObject ? behaviourObject.model === "claude-opus-4-5-20251001" : false
                onClicked: behaviourObject.setModel("claude-opus-4-5-20251001")
            }
        }

        // ── API Key field ─────────────────────────────────────────────────────
        PasswordField {
            id: apiKeyField
            Layout.fillWidth: true
            placeholderText: qsTr("sk-ant-...")
            onEditingFinished: behaviourObject.setApiKey(text)
        }

        // ── System prompt ─────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 60
            color: Qt.rgba(ThemeManager.surfaceColor.r, ThemeManager.surfaceColor.g, ThemeManager.surfaceColor.b, 0.6)
            border.color: ThemeManager.borderColor
            border.width: 1
            radius: 6

            ScrollView {
                anchors.fill: parent
                anchors.margins: 4
                clip: true

                TextArea {
                    id: systemPromptArea
                    placeholderText: qsTr("System prompt (optional)...")
                    color: ThemeManager.textColor
                    font.pixelSize: 11
                    background: null
                    wrapMode: TextArea.Wrap
                    text: behaviourObject ? behaviourObject.systemPrompt : ""
                    onEditingFinished: behaviourObject.setSystemPrompt(text)
                }
            }
        }

        // ── Query area + Send ─────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 56
            color: Qt.rgba(ThemeManager.surfaceColor.r, ThemeManager.surfaceColor.g, ThemeManager.surfaceColor.b, 0.6)
            border.color: ThemeManager.borderColor
            border.width: 1
            radius: 6

            ScrollView {
                anchors.fill: parent
                anchors.rightMargin: 68
                anchors.margins: 4
                clip: true

                TextArea {
                    id: queryArea
                    placeholderText: qsTr("Enter your prompt...")
                    color: ThemeManager.textColor
                    font.pixelSize: 11
                    background: null
                    wrapMode: TextArea.Wrap
                }
            }

            NewButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 4
                text: qsTr("Send")
                variant: "filled"
                width: 60
                onClicked: {
                    if (queryArea.text.length > 0)
                        behaviourObject.query(queryArea.text)
                }
            }
        }

        // ── Response area ─────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Qt.rgba(ThemeManager.backgroundColor.r, ThemeManager.backgroundColor.g, ThemeManager.backgroundColor.b, 0.6)
            border.color: ThemeManager.borderColor
            border.width: 1
            radius: 6
            clip: true

            ScrollView {
                anchors.fill: parent
                anchors.margins: 4
                clip: true

                TextArea {
                    id: responseArea
                    placeholderText: qsTr("Response will appear here...")
                    color: ThemeManager.textColor
                    font.pixelSize: 11
                    background: null
                    readOnly: true
                    wrapMode: TextArea.Wrap
                    text: behaviourObject ? behaviourObject.lastResponse : ""
                }
            }

            // Loading spinner overlay
            LoadingSpinner {
                anchors.centerIn: parent
                visible: behaviourObject ? behaviourObject.isLoading : false
                running: visible
            }
        }

        // ── Token count + cancel row ──────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: qsTr("In: ") + root.inTokens + "  Out: " + root.outTokens
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 10
            }

            Item { Layout.fillWidth: true }

            NewButton {
                text: qsTr("Cancel")
                variant: "outlined"
                visible: behaviourObject ? behaviourObject.isLoading : false
                onClicked: behaviourObject.cancel()
            }
        }
    }
}
