import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import ThemeManager 1.0
import "qrc:/components"

ColumnLayout {
    spacing: 6
    width: parent ? parent.width : 200

    // ── A/B value display ─────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Rectangle {
            Layout.fillWidth: true
            height: 44
            color: ThemeManager.surfaceColor
            radius: 6
            border.color: "#E74C3C"
            border.width: 1

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "A"
                    font.pixelSize: 10
                    color: "#E74C3C"
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: behaviourObject ? behaviourObject.propA.toFixed(3) : "0.000"
                    font.pixelSize: 13
                    font.bold: true
                    color: ThemeManager.textColor
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 44
            color: ThemeManager.surfaceColor
            radius: 6
            border.color: "#3498DB"
            border.width: 1

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "B"
                    font.pixelSize: 10
                    color: "#3498DB"
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: behaviourObject ? behaviourObject.propB.toFixed(3) : "0.000"
                    font.pixelSize: 13
                    font.bold: true
                    color: ThemeManager.textColor
                }
            }
        }
    }

    // ── Output type chips ─────────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 4
        Repeater {
            model: ["(D,D)", "(I,D)", "(I,I)", "(D,I)", "data"]
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
        text: "Adapt"
        variant: "filled"
        iconSource: Icons.flash
        backgroundColor: ThemeManager.primaryColor
        onClicked: if (behaviourObject) behaviourObject.send()
    }
}
