import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import ThemeManager 1.0
import "qrc:/components"

ColumnLayout {
    spacing: 6
    width: parent ? parent.width : 200

    // ── A input ───────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Text {
            text: "A"
            font.pixelSize: 12
            font.bold: true
            color: "#E74C3C"
            Layout.alignment: Qt.AlignVCenter
            width: 14
        }
        NumericInputField {
            Layout.fillWidth: true
            value: behaviourObject ? behaviourObject.a : 0
            decimals: 4
            onValueModified: function(v) { if (behaviourObject) behaviourObject.setA(v) }
        }
    }

    // ── B input ───────────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Text {
            text: "B"
            font.pixelSize: 12
            font.bold: true
            color: "#3498DB"
            Layout.alignment: Qt.AlignVCenter
            width: 14
        }
        NumericInputField {
            Layout.fillWidth: true
            value: behaviourObject ? behaviourObject.b : 0
            decimals: 4
            onValueModified: function(v) { if (behaviourObject) behaviourObject.setB(v) }
        }
    }

    // ── Output chips ──────────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 4
        Repeater {
            model: ["(D,D)", "(I,D)", "(I,I)", "data"]
            delegate: Rectangle {
                Layout.fillWidth: true
                height: 20
                radius: 4
                color: ThemeManager.surfaceColor
                border.color: ThemeManager.borderColor
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: modelData
                    font.pixelSize: 9
                    color: ThemeManager.textSecondaryColor
                }
            }
        }
    }

    // ── Auto-send toggle ──────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Text {
            text: "Auto-send"
            font.pixelSize: 11
            color: ThemeManager.textColor
            opacity: 0.6
            Layout.alignment: Qt.AlignVCenter
        }
        CustomSwitch {
            checked: behaviourObject ? behaviourObject.autoSend : false
            onCheckedChanged: if (behaviourObject) behaviourObject.setAutoSend(checked)
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // ── Send button ───────────────────────────────────────────────────────
    NewButton {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        text: "Merge"
        variant: "filled"
        iconSource: Icons.flash
        backgroundColor: ThemeManager.primaryColor
        onClicked: if (behaviourObject) behaviourObject.send()
    }
}
