import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import ThemeManager 1.0
import "qrc:/components"

ColumnLayout {
    spacing: 6
    width: parent ? parent.width : 200

    // ── Current value display ─────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        height: 44
        color: ThemeManager.surfaceColor
        radius: 6
        border.color: ThemeManager.borderColor
        border.width: 1

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "value"
                font.pixelSize: 10
                color: ThemeManager.textSecondaryColor
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: behaviourObject ? behaviourObject.value.toFixed(4) : "0.0000"
                font.pixelSize: 15
                font.bold: true
                color: ThemeManager.primaryColor
            }
        }
    }

    // ── Type output labels ────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
            model: ["double", "int", "bool", "string", "data"]
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
            text: qsTr("Auto-send")
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
        text: qsTr("Cast")
        variant: "filled"
        iconSource: Icons.flash
        backgroundColor: ThemeManager.primaryColor
        onClicked: if (behaviourObject) behaviourObject.send()
    }
}
