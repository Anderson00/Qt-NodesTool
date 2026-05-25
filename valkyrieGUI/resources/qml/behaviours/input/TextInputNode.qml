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
        spacing: 6

        // ── Text field ────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 6
            color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.06)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.2)
            clip: true

            TextEdit {
                id: textEdit
                anchors.fill: parent
                anchors.margins: 6
                wrapMode: TextEdit.Wrap
                font.pixelSize: 12
                font.family: "Segoe UI"
                color: ThemeManager.textColor
                selectionColor: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.4)
                text: behaviourObject ? behaviourObject.text : ""
                selectByMouse: true
                onTextChanged: {
                    if (behaviourObject && behaviourObject.text !== text)
                        behaviourObject.setText(text)
                }
            }
        }

        // ── Auto-send toggle ──────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Text { text: qsTr("Auto-send"); font.pixelSize: 11; color: ThemeManager.textColor; opacity: 0.6; Layout.alignment: Qt.AlignVCenter }
            CustomSwitch {
                checked: behaviourObject ? behaviourObject.autoSend : false
                onCheckedChanged: if (behaviourObject) behaviourObject.setAutoSend(checked)
                Layout.alignment: Qt.AlignVCenter
            }
        }

        // ── Send — full width ─────────────────────────────────────────────
        NewButton {
            Layout.fillWidth: true; Layout.preferredHeight: 36
            text: qsTr("Send"); variant: "filled"; iconSource: Icons.flash
            backgroundColor: ThemeManager.primaryColor
            onClicked: if (behaviourObject) behaviourObject.send()
        }
    }
}
