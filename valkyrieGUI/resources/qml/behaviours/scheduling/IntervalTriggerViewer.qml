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

    // ── Helpers ───────────────────────────────────────────────────────────────
    function fmtCountdown(s) { return s.length > 0 ? s : "--:--:--" }

    // ── Layout ────────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // ── Fields: Days / Hours / Mins / Secs ────────────────────────────────
        GridLayout {
            Layout.fillWidth: true
            columns: 4
            columnSpacing: 6
            rowSpacing: 4

            Repeater {
                model: [
                    {label: "Dias",    field: "days",    val: behaviourObject ? behaviourObject.days    : 0, max: 365},
                    {label: "Horas",   field: "hours",   val: behaviourObject ? behaviourObject.hours   : 0, max: 23},
                    {label: "Minutos", field: "minutes", val: behaviourObject ? behaviourObject.minutes : 1, max: 59},
                    {label: "Segs",    field: "seconds", val: behaviourObject ? behaviourObject.seconds : 0, max: 59}
                ]

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: modelData.label
                        color: ThemeManager.textSecondaryColor
                        font.pixelSize: 10
                        Layout.alignment: Qt.AlignHCenter
                    }

                    VerticalSpinBox {
                        from: 0; to: modelData.max
                        value: behaviourObject ? behaviourObject[modelData.field] : 0
                        onValueModified: function(newValue) {
                            if (behaviourObject) {
                                behaviourObject[modelData.field] = newValue
                            }
                        }
                    }
                }
            }
        }

        // ── Divider ───────────────────────────────────────────────────────────
        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1,1,1,0.08) }

        // ── Status row ────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            // Status badge
            Rectangle {
                width: 8; height: 8; radius: 4
                color: behaviourObject && behaviourObject.running ? "#22C55E" : Qt.rgba(1,1,1,0.2)
                Behavior on color { ColorAnimation { duration: 300 } }
            }
            Text {
                text: behaviourObject && behaviourObject.running ? "Rodando" : "Parado"
                color: ThemeManager.textSecondaryColor; font.pixelSize: 11
            }
            Item { Layout.fillWidth: true }
            RowLayout {
                spacing: 3
                SvgIcon { width: 10; height: 10; source: Icons.flash; color: ThemeManager.textSecondaryColor }
                Text {
                    text: behaviourObject ? String(behaviourObject.tickCount) : "0"
                    color: ThemeManager.textSecondaryColor; font.pixelSize: 11
                }
            }
        }

        // ── Countdown display ─────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 40; radius: 8
            color: Qt.rgba(0,0,0,0.3)
            border.width: 1
            border.color: behaviourObject && behaviourObject.running ? ThemeManager.primaryColor : Qt.rgba(1,1,1,0.08)
            Behavior on border.color { ColorAnimation { duration: 300 } }

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                SvgIcon {
                    width: 16; height: 16
                    source: Icons.timerOutline
                    color: behaviourObject && behaviourObject.running ? ThemeManager.primaryColor : ThemeManager.textSecondaryColor
                }
                Text {
                    id: countdownLabel
                    text: fmtCountdown(behaviourObject ? behaviourObject.nextTriggerIn : "--:--:--")
                    color: behaviourObject && behaviourObject.running ? ThemeManager.primaryColor : ThemeManager.textSecondaryColor
                    font.pixelSize: 16; font.bold: true; font.family: "Consolas"
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }
        }

        // ── Controls ──────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            // Start / Pause
            Rectangle {
                Layout.fillWidth: true; height: 30; radius: 6
                color: startArea.containsMouse
                    ? Qt.lighter(ThemeManager.primaryColor, 1.2)
                    : ThemeManager.primaryColor
                Behavior on color { ColorAnimation { duration: 150 } }
                RowLayout {
                    anchors.centerIn: parent; spacing: 5
                    SvgIcon {
                        width: 13; height: 13
                        source: behaviourObject && behaviourObject.running ? Icons.pause : Icons.play
                        color: "#fff"
                    }
                    Text {
                        text: behaviourObject && behaviourObject.running ? "Pausar" : "Iniciar"
                        color: "#fff"; font.pixelSize: 12; font.bold: true
                    }
                }
                MouseArea {
                    id: startArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (behaviourObject.running) behaviourObject.stopTrigger()
                        else behaviourObject.startTrigger()
                    }
                }
            }

            // Reset count
            Rectangle {
                width: 30; height: 30; radius: 6
                color: resetArea.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05)
                border.width: 1; border.color: Qt.rgba(1,1,1,0.15)
                SvgIcon { anchors.centerIn: parent; width: 16; height: 16; source: Icons.refresh; color: ThemeManager.textColor }
                MouseArea { id: resetArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: behaviourObject.resetCount() }
            }

            // Fire now
            Rectangle {
                width: 30; height: 30; radius: 6
                color: fireArea.containsMouse ? Qt.rgba(1,1,1,0.1) : Qt.rgba(1,1,1,0.05)
                border.width: 1; border.color: Qt.rgba(1,1,1,0.15)
                SvgIcon { anchors.centerIn: parent; width: 16; height: 16; source: Icons.flash; color: ThemeManager.textColor }
                MouseArea { id: fireArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: behaviourObject.trigger() }
            }
        }

        // Fire immediately option
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            CheckBox {
                id: fireImmCheck
                checked: behaviourObject ? behaviourObject.fireImmediately : false
                onCheckedChanged: if (behaviourObject) behaviourObject.fireImmediately = checked
            }
            Text {
                text: "Disparar imediatamente ao iniciar"
                color: ThemeManager.textSecondaryColor; font.pixelSize: 11
                MouseArea { anchors.fill: parent; onClicked: fireImmCheck.toggle() }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
