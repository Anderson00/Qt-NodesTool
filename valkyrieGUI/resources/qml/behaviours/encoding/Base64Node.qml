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

    Connections {
        target: behaviourObject

        function onInternalEncoded(result) {
            encodeResultField.text = result
        }

        function onInternalDecoded(result) {
            decodeResultField.text = result
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 6

        // ── URL-safe mode switch ───────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "URL-safe encoding"
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 11
            }

            Item { Layout.fillWidth: true }

            CustomSwitch {
                checked: behaviourObject ? behaviourObject.urlSafe : false
                onToggled: behaviourObject.setUrlSafe(checked)
            }
        }

        // ── Encode section ────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            CustomTextField {
                id: encodeInputField
                Layout.fillWidth: true
                placeholderText: "Text to encode..."
                onAccepted: behaviourObject.encode(text)
            }

            NewButton {
                text: "Encode"
                variant: "filled"
                onClicked: behaviourObject.encode(encodeInputField.text)
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 28
            color: Qt.rgba(ThemeManager.backgroundColor.r, ThemeManager.backgroundColor.g, ThemeManager.backgroundColor.b, 0.6)
            border.color: ThemeManager.borderColor
            border.width: 1
            radius: 6

            TextInput {
                id: encodeResultField
                anchors.fill: parent
                anchors.margins: 6
                verticalAlignment: TextInput.AlignVCenter
                color: ThemeManager.textColor
                font { pixelSize: 10; family: "Consolas" }
                readOnly: true
                selectByMouse: true
                text: behaviourObject ? behaviourObject.lastEncoded : ""
                clip: true
                placeholderText: "Encoded result..."
            }
        }

        // ── Divider ───────────────────────────────────────────────────────────
        Divider { Layout.fillWidth: true }

        // ── Decode section ────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            CustomTextField {
                id: decodeInputField
                Layout.fillWidth: true
                placeholderText: "Base64 to decode..."
                onAccepted: behaviourObject.decode(text)
            }

            NewButton {
                text: "Decode"
                variant: "outlined"
                onClicked: behaviourObject.decode(decodeInputField.text)
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 28
            color: Qt.rgba(ThemeManager.backgroundColor.r, ThemeManager.backgroundColor.g, ThemeManager.backgroundColor.b, 0.6)
            border.color: ThemeManager.borderColor
            border.width: 1
            radius: 6

            TextInput {
                id: decodeResultField
                anchors.fill: parent
                anchors.margins: 6
                verticalAlignment: TextInput.AlignVCenter
                color: ThemeManager.textColor
                font { pixelSize: 10; family: "Consolas" }
                readOnly: true
                selectByMouse: true
                text: behaviourObject ? behaviourObject.lastDecoded : ""
                clip: true
                placeholderText: "Decoded result..."
            }
        }
    }
}
