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

    property string displayResult: ""
    property string displayError:  ""
    property var    displayKeys:   []

    Connections {
        target: behaviourObject
        function onInternalResult(path, value) {
            displayResult = value
            displayError  = ""
        }
        function onInternalError(msg) {
            displayError  = msg
            displayResult = ""
        }
        function onInternalKeys(keys) {
            displayKeys = keys
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 6

        // ── Title ─────────────────────────────────────────────────────────
        Text {
            text: qsTr("JSON Parser")
            color: ThemeManager.textColor
            font.pixelSize: 11
            font.bold: true
        }

        // ── Path input ────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: qsTr("Path:")
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 10
                Layout.alignment: Qt.AlignVCenter
            }

            CustomTextField {
                id: pathField
                Layout.fillWidth: true
                placeholderText: qsTr("e.g. data.items.0.name")
                text: behaviourObject ? behaviourObject.currentPath : ""
                onEditingFinished: {
                    if (behaviourObject)
                        behaviourObject.setPath(text)
                }
            }
        }

        // ── Top-level keys display ─────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 28
            color: Qt.rgba(ThemeManager.surfaceColor.r, ThemeManager.surfaceColor.g,
                           ThemeManager.surfaceColor.b, 0.7)
            radius: 3

            Flickable {
                anchors.fill: parent
                anchors.margins: 4
                contentWidth: keysRow.width
                clip: true

                Row {
                    id: keysRow
                    spacing: 4

                    Text {
                        text: qsTr("keys:")
                        color: ThemeManager.textSecondaryColor
                        font.pixelSize: 9
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Repeater {
                        model: displayKeys
                        delegate: Rectangle {
                            height: 20
                            width: keyLabel.width + 10
                            radius: 3
                            color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
                                           ThemeManager.primaryColor.b, 0.18)
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                id: keyLabel
                                anchors.centerIn: parent
                                text: modelData
                                color: ThemeManager.primaryColor
                                font.pixelSize: 9
                                font.family: "Consolas, monospace"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    pathField.text = modelData
                                    if (behaviourObject)
                                        behaviourObject.setPath(modelData)
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── JSON preview ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 90
            radius: 3
            color: Qt.rgba(ThemeManager.backgroundColor.r, ThemeManager.backgroundColor.g,
                           ThemeManager.backgroundColor.b, 0.6)
            border.color: ThemeManager.borderColor
            border.width: 1
            clip: true

            Flickable {
                anchors.fill: parent
                anchors.margins: 5
                contentWidth: width
                contentHeight: previewText.contentHeight
                clip: true

                Text {
                    id: previewText
                    width: parent.width
                    text: behaviourObject && behaviourObject.lastError !== ""
                          ? behaviourObject.lastError
                          : (displayResult !== "" ? displayResult : "Awaiting JSON input…")
                    color: (behaviourObject && behaviourObject.lastError !== "")
                           ? ThemeManager.errorColor
                           : (displayResult !== "" ? ThemeManager.textColor : ThemeManager.textSecondaryColor)
                    font.family: "Consolas, monospace"
                    font.pixelSize: 10
                    wrapMode: Text.WrapAnywhere
                }
            }
        }

        // ── Result row ────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 32
            radius: 3
            color: Qt.rgba(ThemeManager.surfaceColor.r, ThemeManager.surfaceColor.g,
                           ThemeManager.surfaceColor.b, 0.5)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Text {
                    text: qsTr("Result:")
                    color: ThemeManager.textSecondaryColor
                    font.pixelSize: 10
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    Layout.fillWidth: true
                    text: behaviourObject ? behaviourObject.lastResult : ""
                    color: ThemeManager.textColor
                    font.family: "Consolas, monospace"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
