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

    property string lastResponseBody: ""
    property int    lastCode:         0
    property string selectedMethod:   "GET"

    function statusColor(code) {
        if (code >= 200 && code < 300) return "#2ecc71"
        if (code >= 300 && code < 400) return "#f39c12"
        if (code >= 400)               return "#e74c3c"
        return ThemeManager.textSecondaryColor
    }

    Connections {
        target: behaviourObject
        function onInternalResponse(body)  { lastResponseBody = body }
        function onInternalError(err)      { lastResponseBody = "Error: " + err }
        function onInternalStatus(code)    { lastCode = code }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Toolbar ────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 34
            color: ThemeManager.surfaceColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Text {
                    text: "HTTP Requester"
                    color: ThemeManager.textColor
                    font.pixelSize: 11
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                LoadingSpinner {
                    visible: behaviourObject && behaviourObject.isLoading
                    width: 16; height: 16
                }

                Rectangle {
                    visible: lastCode > 0
                    width: 46; height: 20; radius: 4
                    color: Qt.rgba(statusColor(lastCode) === "#2ecc71" ? 0.18 : statusColor(lastCode) === "#f39c12" ? 0.95 : 0.93,
                                   statusColor(lastCode) === "#2ecc71" ? 0.80 : statusColor(lastCode) === "#f39c12" ? 0.63 : 0.17,
                                   statusColor(lastCode) === "#2ecc71" ? 0.44 : 0.17, 0.18)
                    border.color: statusColor(lastCode)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: lastCode > 0 ? lastCode : ""
                        font.pixelSize: 10; font.bold: true
                        color: statusColor(lastCode)
                    }
                }
            }
        }

        // ── Method + URL + Send ────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 42
            color: Qt.rgba(ThemeManager.surfaceColor.r, ThemeManager.surfaceColor.g, ThemeManager.surfaceColor.b, 0.6)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                anchors.topMargin: 5
                anchors.bottomMargin: 5
                spacing: 4

                CustomComboBox {
                    id: methodCombo
                    Layout.preferredWidth: 88
                    model: ["GET", "POST", "PUT", "DELETE"]
                    currentIndex: 0
                    onCurrentTextChanged: root.selectedMethod = currentText
                }

                CustomTextField {
                    id: urlField
                    Layout.fillWidth: true
                    placeholderText: "https://..."
                    text: ""
                }

                NewButton {
                    Layout.preferredWidth: 52
                    Layout.fillHeight: true
                    variant: "filled"
                    label: "Send"
                    backgroundColor: ThemeManager.primaryColor
                    onClicked: {
                        if (!behaviourObject) return
                        var u = urlField.text.trim()
                        if (u === "") return
                        var m = methodCombo.currentText
                        if (m === "GET")    behaviourObject.get(u)
                        else if (m === "POST") behaviourObject.post(u, bodyArea.text)
                        else if (m === "PUT")  behaviourObject.put(u, bodyArea.text)
                        else if (m === "DELETE") behaviourObject.del(u)
                    }
                }
            }
        }

        // ── Headers row ────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: headersVisible ? 76 : 32
            color: "transparent"
            clip: true

            Behavior on height { NumberAnimation { duration: 150 } }

            property bool headersVisible: false

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    height: 28
                    spacing: 4

                    Text {
                        text: "Headers"
                        font.pixelSize: 9
                        color: ThemeManager.textSecondaryColor
                        font.bold: true
                        Layout.alignment: Qt.AlignVCenter
                    }

                    NewButton {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        variant: "outlined"
                        iconSource: parent.parent.parent.headersVisible ? Icons.x : Icons.plus
                        onClicked: parent.parent.parent.headersVisible = !parent.parent.parent.headersVisible
                    }

                    Item { Layout.fillWidth: true }
                }

                RowLayout {
                    Layout.fillWidth: true
                    height: 30
                    spacing: 4
                    visible: parent.parent.headersVisible

                    CustomTextField {
                        id: headerKey
                        Layout.preferredWidth: 100
                        placeholderText: "Key"
                    }

                    CustomTextField {
                        id: headerValue
                        Layout.fillWidth: true
                        placeholderText: "Value"
                    }

                    NewButton {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 30
                        variant: "filled"
                        iconSource: Icons.plus
                        backgroundColor: ThemeManager.primaryColor
                        onClicked: {
                            if (behaviourObject && headerKey.text.trim() !== "")
                                behaviourObject.setHeader(headerKey.text.trim(), headerValue.text)
                        }
                    }
                }
            }
        }

        // ── Body (shown for POST/PUT) ──────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: (selectedMethod === "POST" || selectedMethod === "PUT") ? 64 : 0
            color: "transparent"
            clip: true
            visible: height > 0

            Behavior on height { NumberAnimation { duration: 150 } }

            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                anchors.topMargin: 2
                anchors.bottomMargin: 2
                radius: 4
                color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.05)
                border.width: bodyArea.activeFocus ? 1 : 0
                border.color: ThemeManager.primaryColor

                Flickable {
                    id: bodyFlick
                    anchors.fill: parent
                    anchors.margins: 6
                    contentWidth: width
                    contentHeight: bodyArea.contentHeight
                    clip: true

                    TextArea {
                        id: bodyArea
                        width: bodyFlick.width
                        wrapMode: TextArea.Wrap
                        font.family: "Consolas, monospace"
                        font.pixelSize: 11
                        color: ThemeManager.textColor
                        background: null
                        placeholderText: '{"key": "value"}'
                        placeholderTextColor: ThemeManager.textSecondaryColor
                    }
                }
            }
        }

        // ── Response ───────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Qt.rgba(ThemeManager.backgroundColor.r, ThemeManager.backgroundColor.g, ThemeManager.backgroundColor.b, 0.5)
            clip: true

            Flickable {
                id: responseFlick
                anchors.fill: parent
                anchors.margins: 6
                contentWidth: width
                contentHeight: responseText.contentHeight
                clip: true

                Text {
                    id: responseText
                    width: responseFlick.width
                    text: lastResponseBody === "" ? "Response will appear here..." : lastResponseBody
                    color: lastResponseBody === "" ? ThemeManager.textSecondaryColor : ThemeManager.textColor
                    font.family: "Consolas, monospace"
                    font.pixelSize: 10
                    wrapMode: Text.WrapAnywhere
                }
            }
        }

        // ── Cancel button ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 28
            color: ThemeManager.surfaceColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 4

                Text {
                    text: "Timeout: " + (behaviourObject ? behaviourObject.timeout : 30000) + "ms"
                    font.pixelSize: 9
                    color: ThemeManager.textSecondaryColor
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                NewButton {
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 20
                    variant: "outlined"
                    label: "Cancel"
                    onClicked: { if (behaviourObject) behaviourObject.cancel() }
                    visible: behaviourObject && behaviourObject.isLoading
                }
            }
        }
    }
}
