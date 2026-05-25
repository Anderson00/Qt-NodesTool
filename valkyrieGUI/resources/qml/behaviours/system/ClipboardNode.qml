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

    property string previewText: ""
    property string lastUpdated: ""

    Connections {
        target: behaviourObject
        function onInternalClipboardChanged(text) {
            previewText = text
            lastUpdated = Qt.formatTime(new Date(), "hh:mm:ss")
        }
        function onInternalRead(text) {
            previewText = text
            lastUpdated = Qt.formatTime(new Date(), "hh:mm:ss")
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // -- Header row with monitor switch --
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: qsTr("Clipboard")
                font.pixelSize: 10
                font.bold: true
                color: ThemeManager.textColor
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Text {
                text: qsTr("Monitor")
                font.pixelSize: 9
                color: ThemeManager.textSecondaryColor
                Layout.alignment: Qt.AlignVCenter
            }

            CustomSwitch {
                checked: behaviourObject ? behaviourObject.monitorChanges : false
                onCheckedChanged: {
                    if (behaviourObject)
                        behaviourObject.setMonitorChanges(checked)
                }
            }
        }

        // -- Clipboard preview --
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 4
            color: Qt.rgba(ThemeManager.backgroundColor.r, ThemeManager.backgroundColor.g, ThemeManager.backgroundColor.b, 0.5)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.4)
            clip: true

            Flickable {
                anchors.fill: parent
                anchors.margins: 6
                contentWidth: width
                contentHeight: clipText.contentHeight
                clip: true

                TextArea {
                    id: clipText
                    width: parent.width
                    text: previewText === "" ? (behaviourObject && behaviourObject.lastText !== "" ? behaviourObject.lastText : "") : previewText
                    readOnly: true
                    wrapMode: TextArea.Wrap
                    font.family: "Consolas, monospace"
                    font.pixelSize: 10
                    color: ThemeManager.textColor
                    background: null
                    placeholderText: qsTr("Clipboard content will appear here...")
                    placeholderTextColor: ThemeManager.textSecondaryColor
                    selectByMouse: true
                }
            }
        }

        // -- Last updated timestamp --
        Text {
            visible: lastUpdated !== ""
            text: qsTr("Updated: ") + lastUpdated
            font.pixelSize: 8
            color: ThemeManager.textSecondaryColor
            Layout.alignment: Qt.AlignRight
        }

        // -- Action buttons --
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            NewButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                variant: "outlined"
                text: qsTr("Read")
                onClicked: {
                    if (behaviourObject) behaviourObject.readText()
                }
            }

            NewButton {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                variant: "filled"
                text: qsTr("Write")
                backgroundColor: ThemeManager.primaryColor
                onClicked: {
                    if (behaviourObject && clipText.text !== "")
                        behaviourObject.writeText(clipText.text)
                }
            }
        }
    }
}
