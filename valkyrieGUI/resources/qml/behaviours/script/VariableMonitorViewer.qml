import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15 as Ctrl
import App.Theme 1.0
import App.Variables 1.0
import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    // ── Connections: refresh when variables change ─────────────────────────────
    Connections {
        target: VariableManager
        function onVariablesChanged() { _listModel.refresh() }
    }

    // ── Variable list for the "add watch" popup ───────────────────────────────
    property bool _popupOpen: false

    ColumnLayout {
        anchors.fill: parent; anchors.margins: 6; spacing: 4

        // ── Header row ────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "\uD83D\uDCCA Monitor"; font.pixelSize: 10; font.bold: true
                color: ThemeManager.textColor; opacity: 0.7
                Layout.fillWidth: true
            }

            // "+" button to add a variable to watch list
            Rectangle {
                width: 20; height: 20; radius: 10
                color: _addMa.containsMouse
                       ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
                                 ThemeManager.primaryColor.b, 0.2)
                       : "transparent"
                Text { anchors.centerIn: parent; text: "+"; font.pixelSize: 14
                       color: ThemeManager.primaryColor }
                MouseArea {
                    id: _addMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root._popupOpen = !root._popupOpen
                }
            }

            // Clear all button
            Rectangle {
                width: 20; height: 20; radius: 10; visible: behaviourObject && behaviourObject.watchedIds.length > 0
                color: _clrMa.containsMouse ? Qt.rgba(0.94,0.27,0.27,0.2) : "transparent"
                Text { anchors.centerIn: parent; text: "\u00D7"; font.pixelSize: 14; color: "#EF4444" }
                MouseArea { id: _clrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { if (behaviourObject) behaviourObject.clearWatch() } }
            }
        }

        // ── Variable picker popup ─────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: root._popupOpen ? Math.min(160, VariableManager.count * 28 + 8) : 0
            visible: height > 0
            clip: true
            radius: 4; color: ThemeManager.backgroundColor
            border.color: ThemeManager.primaryColor; border.width: 1

            Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

            Ctrl.ScrollView {
                anchors.fill: parent; anchors.margins: 4; clip: true
                ListView {
                    model: VariableManager.variables
                    delegate: Rectangle {
                        width: parent ? parent.width : 0; height: 26; radius: 3
                        color: _pma.containsMouse
                               ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
                                         ThemeManager.primaryColor.b, 0.12)
                               : "transparent"
                        property bool _watched: behaviourObject
                                                 ? behaviourObject.watchedIds.indexOf(modelData.id) >= 0
                                                 : false
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 6; spacing: 6
                            Text { text: _watched ? "\u2713" : ""; font.pixelSize: 9; color: ThemeManager.primaryColor; width: 10 }
                            Text { Layout.fillWidth: true; text: modelData.name; font.pixelSize: 10
                                   color: ThemeManager.textColor; elide: Text.ElideRight }
                            Text { text: modelData.type; font.pixelSize: 8; color: ThemeManager.primaryColor; opacity: 0.6 }
                        }
                        MouseArea {
                            id: _pma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!behaviourObject) return
                                if (parent._watched) behaviourObject.removeWatchId(modelData.id)
                                else                 behaviourObject.addWatchId(modelData.id)
                            }
                        }
                    }
                }
            }
        }

        // ── Watched variable cards ────────────────────────────────────────────
        Ctrl.ScrollView {
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true

            Column {
                width: parent ? parent.width : 0; spacing: 4

                Repeater {
                    model: behaviourObject ? behaviourObject.watchedIds : []
                    delegate: Rectangle {
                        width: parent ? parent.width : 0; height: 44; radius: 5
                        color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                                       ThemeManager.textColor.b, 0.04)
                        border.color: ThemeManager.borderColor; border.width: 1

                        property var _var: VariableManager.variableById(modelData)

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 6; spacing: 6

                            Column {
                                Layout.fillWidth: true; spacing: 2
                                Text {
                                    text: parent.parent.parent._var ? parent.parent.parent._var.name : modelData
                                    font.pixelSize: 10; font.bold: true
                                    color: ThemeManager.textColor; elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    text: parent.parent.parent._var ? parent.parent.parent._var.value : "—"
                                    font.pixelSize: 12; font.family: "Consolas"
                                    color: ThemeManager.primaryColor; elide: Text.ElideRight
                                    width: parent.width
                                }
                            }

                            // Remove button
                            Rectangle {
                                width: 16; height: 16; radius: 8
                                color: _rmMa.containsMouse ? Qt.rgba(0.94,0.27,0.27,0.2) : "transparent"
                                Text { anchors.centerIn: parent; text: "\u00D7"; font.pixelSize: 11; color: "#EF4444" }
                                MouseArea {
                                    id: _rmMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { if (behaviourObject) behaviourObject.removeWatchId(modelData) }
                                }
                            }
                        }

                        // Auto-refresh when variable changes
                        Connections {
                            target: VariableManager
                            function onVariablesChanged() { _var = VariableManager.variableById(modelData) }
                        }
                    }
                }

                // Empty state
                Text {
                    visible: !behaviourObject || behaviourObject.watchedIds.length === 0
                    width: parent ? parent.width : 0
                    text: "Tap + to add variables\nto monitor"
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 10; color: ThemeManager.textSecondaryColor; opacity: 0.4
                    topPadding: 12
                }
            }
        }
    }
}
