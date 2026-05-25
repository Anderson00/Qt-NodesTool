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

        // ── Header ────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: qsTr("Items")
                font.pixelSize: 11; font.bold: true
                color: ThemeManager.textColor; opacity: 0.7
            }
            Item { Layout.fillWidth: true }
            Text {
                text: behaviourObject ? behaviourObject.items.length + " items" : "0 items"
                font.pixelSize: 10
                color: ThemeManager.primaryColor; opacity: 0.8
            }
        }

        // ── Scrollable list ───────────────────────────────────────────────
        // O botão "Add item" está FORA do ScrollView para nunca sumir
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 6
            color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.03)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.1)
            clip: true

            ScrollView {
                id: scroll
                anchors.fill: parent
                anchors.margins: 4
                contentWidth: availableWidth
                // contentHeight explícito para o ScrollView saber exatamente
                // quanto conteúdo existe e não cortar nada
                contentHeight: itemsCol.implicitHeight
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                clip: true

                Column {
                    id: itemsCol
                    width: scroll.availableWidth
                    spacing: 3

                    Repeater {
                        model: behaviourObject ? behaviourObject.items : []
                        delegate: RowLayout {
                            width: itemsCol.width
                            spacing: 4

                            CustomTextField {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                text: modelData
                                onEditingFinished: if (behaviourObject) behaviourObject.setItem(index, text)
                            }
                            Rectangle {
                                width: 26; height: 26; radius: 4
                                color: delMa.containsMouse ? "#FF1744" : Qt.rgba(1, 0.1, 0.2, 0.18)
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Text { anchors.centerIn: parent; text: qsTr("−"); font.pixelSize: 15; font.bold: true; color: "#FF5252" }
                                MouseArea {
                                    id: delMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: if (behaviourObject) behaviourObject.removeItem(index)
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Add item — sempre visível, fora do scroll ─────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            radius: 5
            color: addMa.containsMouse
                   ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.18)
                   : Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.07)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.25)
            Behavior on color { ColorAnimation { duration: 100 } }
            RowLayout {
                anchors.centerIn: parent; spacing: 5
                Text { text: qsTr("+"); font.pixelSize: 15; font.bold: true; color: ThemeManager.primaryColor }
                Text { text: qsTr("Add item"); font.pixelSize: 12; color: ThemeManager.primaryColor }
            }
            MouseArea {
                id: addMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: if (behaviourObject) behaviourObject.addItem("")
            }
        }

        // ── Auto toggle ───────────────────────────────────────────────────
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
