import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import App.Theme 1.0
import App.Icons 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    // ── Preset chips ──────────────────────────────────────────────────────────
    readonly property var presets: [
        {label: qsTr("@hourly"),   expr: "@hourly"},
        {label: qsTr("@daily"),    expr: "@daily"},
        {label: qsTr("@weekly"),   expr: "@weekly"},
        {label: qsTr("@monthly"),  expr: "@monthly"},
        {label: qsTr("Seg-Sex 9h"),expr: "0 9 * * 1-5"},
        {label: qsTr("30 min"),    expr: "*/30 * * * *"}
    ]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // ── Expression field ──────────────────────────────────────────────────
        Text {
            text: qsTr("Expressão Cron")
            color: ThemeManager.textSecondaryColor; font.pixelSize: 10
        }

        Rectangle {
            Layout.fillWidth: true; height: 36; radius: 6
            color: Qt.rgba(1,1,1,0.05)
            border.width: 1
            border.color: {
                if (!behaviourObject) return Qt.rgba(1,1,1,0.12)
                if (!behaviourObject.isValid) return "#EF4444"
                return cronField.activeFocus ? ThemeManager.primaryColor : Qt.rgba(1,1,1,0.18)
            }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            TextInput {
                id: cronField
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left; anchors.right: parent.right
                anchors.margins: 10
                text: behaviourObject ? behaviourObject.cronExpression : "0 * * * *"
                color: ThemeManager.textColor
                font.pixelSize: 13; font.family: "Consolas"
                selectByMouse: true
                onEditingFinished: if (behaviourObject) behaviourObject.cronExpression = text
            }
        }

        // ── Description ───────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: descText.implicitHeight + 12
            radius: 6
            color: behaviourObject && behaviourObject.isValid ? Qt.rgba(1,1,1,0.04) : Qt.rgba(239,68,68,0.08)
            border.width: 1
            border.color: behaviourObject && behaviourObject.isValid ? Qt.rgba(1,1,1,0.08) : Qt.rgba(239,68,68,0.25)

            Text {
                id: descText
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 8 }
                text: behaviourObject ? behaviourObject.description : ""
                color: behaviourObject && behaviourObject.isValid ? ThemeManager.textSecondaryColor : "#EF4444"
                font.pixelSize: 11
                wrapMode: Text.WordWrap
            }
        }

        // ── Divider ───────────────────────────────────────────────────────────
        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.08) }

        // ── Status & Next ─────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 6
            Rectangle {
                width: 8; height: 8; radius: 4
                color: behaviourObject && behaviourObject.enabled ? "#22C55E" : Qt.rgba(1,1,1,0.2)
                Behavior on color { ColorAnimation { duration: 300 } }
            }
            Text {
                text: behaviourObject && behaviourObject.enabled ? "Ativo" : "Inativo"
                color: ThemeManager.textSecondaryColor; font.pixelSize: 11
            }
            Item { Layout.fillWidth: true }
            RowLayout {
                spacing: 3
                SvgIcon { width: 10; height: 10; source: Icons.flash; color: ThemeManager.textSecondaryColor }
                Text {
                    text: behaviourObject ? String(behaviourObject.fireCount) : "0"
                    color: ThemeManager.textSecondaryColor; font.pixelSize: 11
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true; spacing: 4
            Text { text: qsTr("Próximo:"); color: ThemeManager.textSecondaryColor; font.pixelSize: 10 }
            Text {
                text: behaviourObject ? behaviourObject.nextOccurrence : "—"
                color: ThemeManager.textColor; font.pixelSize: 11; font.bold: true
            }
        }

        RowLayout {
            Layout.fillWidth: true; spacing: 4
            visible: behaviourObject && behaviourObject.lastOccurrence.length > 0
            Text { text: qsTr("Último:");  color: ThemeManager.textSecondaryColor; font.pixelSize: 10 }
            Text {
                text: behaviourObject ? behaviourObject.lastOccurrence : "—"
                color: ThemeManager.textSecondaryColor; font.pixelSize: 11
            }
        }

        // ── Preset chips ──────────────────────────────────────────────────────
        Flow {
            Layout.fillWidth: true; spacing: 4
            Repeater {
                model: root.presets
                Rectangle {
                    height: 22
                    width: chipText.implicitWidth + 16
                    radius: 11
                    color: chipA.containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.06)
                    border.width: 1; border.color: Qt.rgba(1,1,1,0.15)
                    Text {
                        id: chipText
                        anchors.centerIn: parent
                        text: modelData.label
                        color: ThemeManager.textSecondaryColor; font.pixelSize: 10
                    }
                    MouseArea {
                        id: chipA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (behaviourObject) {
                                behaviourObject.cronExpression = modelData.expr
                                cronField.text = modelData.expr
                            }
                        }
                    }
                }
            }
        }

        // ── Controls ──────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 6

            Rectangle {
                Layout.fillWidth: true; height: 30; radius: 6
                color: enableA.containsMouse
                    ? (behaviourObject && behaviourObject.enabled ? "#DC2626" : Qt.lighter(ThemeManager.primaryColor,1.2))
                    : (behaviourObject && behaviourObject.enabled ? "#EF4444" : ThemeManager.primaryColor)
                Behavior on color { ColorAnimation { duration: 150 } }
                RowLayout {
                    anchors.centerIn: parent; spacing: 5
                    SvgIcon {
                        width: 13; height: 13
                        source: behaviourObject && behaviourObject.enabled ? Icons.pause : Icons.play
                        color: "#fff"
                    }
                    Text {
                        text: behaviourObject && behaviourObject.enabled ? "Desativar" : "Ativar"
                        color: "#fff"; font.pixelSize: 12; font.bold: true
                    }
                }
                MouseArea {
                    id: enableA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: if (behaviourObject) behaviourObject.enabled = !behaviourObject.enabled
                }
            }

            Rectangle {
                width: 30; height: 30; radius: 6
                color: testA.containsMouse ? Qt.rgba(1,1,1,0.12) : Qt.rgba(1,1,1,0.06)
                border.width: 1; border.color: Qt.rgba(1,1,1,0.15)
                SvgIcon { anchors.centerIn: parent; width: 16; height: 16; source: Icons.flash; color: ThemeManager.textColor }
                MouseArea { id: testA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: behaviourObject.testFire() }
                AppToolTip { text: qsTr("Disparar agora (teste)") }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
