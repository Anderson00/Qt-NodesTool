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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 7

        // ── Label (key) ───────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Text { text: "Label / Key"; font.pixelSize: 10; color: ThemeManager.textColor; opacity: 0.55 }
            CustomTextField {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                placeholderText: "e.g. Series A"
                text: behaviourObject ? behaviourObject.keyText : ""
                onTextChanged: if (behaviourObject && behaviourObject.keyText !== text) behaviourObject.setKeyText(text)
            }
        }

        // ── Value (number) ────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3
            Text { text: "Value"; font.pixelSize: 10; color: ThemeManager.textColor; opacity: 0.55 }
            NumericInputField {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                value: behaviourObject ? behaviourObject.valueNum : 0
                decimals: 3
                onValueModified: function(newValue) { if (behaviourObject) behaviourObject.setValueNum(newValue) }
            }
        }

        // ── Index ─────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text { text: "Index"; font.pixelSize: 10; color: ThemeManager.textColor; opacity: 0.55; Layout.alignment: Qt.AlignVCenter }
            NumberSpinBox {
                Layout.preferredWidth: 80
                Layout.preferredHeight: 28
                value: behaviourObject ? behaviourObject.indexNum : 0
                from: 0; to: 9999
                onValueChanged: if (behaviourObject) behaviourObject.setIndexNum(value)
            }
            Item { Layout.fillWidth: true }
        }

        // ── Auto + Send ───────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Text { text: "Auto"; font.pixelSize: 11; color: ThemeManager.textColor; opacity: 0.6; Layout.alignment: Qt.AlignVCenter }
            CustomSwitch {
                checked: behaviourObject ? behaviourObject.autoSend : false
                onCheckedChanged: if (behaviourObject) behaviourObject.setAutoSend(checked)
                Layout.alignment: Qt.AlignVCenter
            }
            Item { Layout.fillWidth: true }
            NewButton {
                text: "Send"; variant: "filled"; iconSource: Icons.flash
                backgroundColor: ThemeManager.primaryColor
                Layout.preferredHeight: 28; Layout.preferredWidth: 70
                onClicked: if (behaviourObject) behaviourObject.send()
            }
        }
    }
}
