import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.0
import App.Theme 1.0
import Qaterial as Qaterial

// Top application bar for the ViewPort window.
// Displays app name, project name, panel navigation buttons and action buttons.
Rectangle {
    id: root

    property int    barHeight:      48
    property string currentProject: "Untitled Project"

    // The currently active left-panel ID ("nodes", "explorer", "variables", or "").
    // Bind this to the parent's selectedPanel property for two-way sync.
    property string selectedPanel: ""

    // Emitted when the user clicks a nav button.
    // The parent should toggle the drawer and update selectedPanel.
    signal panelToggled(string panel)
    signal settingsRequested()
    signal saveRequested()
    signal openRequested()

    height: barHeight
    color: Qt.darker(ThemeManager.backgroundColor, 1.35)

    // Bottom separator line
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right
        height: 1
        color:   ThemeManager.primaryColor
        opacity: 0.3
    }

    RowLayout {
        anchors.fill:        parent
        anchors.leftMargin:  16
        anchors.rightMargin: 8
        spacing: 0

        // ── App name + project name ──────────────────────────────────────────
        Row {
            spacing: 0
            Layout.alignment: Qt.AlignVCenter

            Text {
                text: "Valkyrie"
                font.pixelSize: 14
                font.bold: true
                font.letterSpacing: 0.8
                color: ThemeManager.primaryColor
                height: root.barHeight
                verticalAlignment: Text.AlignVCenter
            }

            Item { width: 12; height: 1 }

            Rectangle {
                width: 1; height: 16
                color:   ThemeManager.textColor
                opacity: 0.3
                anchors.verticalCenter: parent.verticalCenter
            }

            Item { width: 12; height: 1 }

            Text {
                text: root.currentProject
                font.pixelSize: 12
                color:   ThemeManager.textColor
                opacity: 0.55
                height:  root.barHeight
                verticalAlignment: Text.AlignVCenter
            }
        }

        // ── Nav panel buttons ────────────────────────────────────────────────
        Row {
            spacing: 0
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 8

            // Nodes
            Item {
                width:  nodesRow.implicitWidth + 24
                height: root.barHeight

                Rectangle {
                    anchors.fill: parent
                    color:   ThemeManager.primaryColor
                    opacity: root.selectedPanel === "nodes" ? 0.12 : nodesHover.containsMouse ? 0.06 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                Row {
                    id: nodesRow
                    anchors.centerIn: parent
                    spacing: 7

                    Qaterial.ColorIcon {
                        source: Qaterial.Icons.graphOutline
                        color:  root.selectedPanel === "nodes" ? ThemeManager.primaryColor : ThemeManager.textColor
                        width: 16; height: 16
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    Text {
                        text: "Nodes"
                        font.pixelSize: 11
                        color: root.selectedPanel === "nodes" ? ThemeManager.primaryColor : ThemeManager.textColor
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left:   parent.left;  anchors.right:  parent.right
                    anchors.leftMargin: 6;        anchors.rightMargin: 6
                    height: 2; radius: 1
                    color:   ThemeManager.primaryColor
                    visible: root.selectedPanel === "nodes"
                }

                MouseArea {
                    id: nodesHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: root.panelToggled("nodes")
                }
            }

            // Explorer
            Item {
                width:  explorerRow.implicitWidth + 24
                height: root.barHeight

                Rectangle {
                    anchors.fill: parent
                    color:   ThemeManager.primaryColor
                    opacity: root.selectedPanel === "explorer" ? 0.12 : explorerHover.containsMouse ? 0.06 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                Row {
                    id: explorerRow
                    anchors.centerIn: parent
                    spacing: 7

                    Qaterial.ColorIcon {
                        source: Qaterial.Icons.folderOutline
                        color:  root.selectedPanel === "explorer" ? ThemeManager.primaryColor : ThemeManager.textColor
                        width: 16; height: 16
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    Text {
                        text: "Explorer"
                        font.pixelSize: 11
                        color: root.selectedPanel === "explorer" ? ThemeManager.primaryColor : ThemeManager.textColor
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left:   parent.left;  anchors.right:  parent.right
                    anchors.leftMargin: 6;        anchors.rightMargin: 6
                    height: 2; radius: 1
                    color:   ThemeManager.primaryColor
                    visible: root.selectedPanel === "explorer"
                }

                MouseArea {
                    id: explorerHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: root.panelToggled("explorer")
                }
            }

            // Variables
            Item {
                width:  variablesRow.implicitWidth + 24
                height: root.barHeight

                Rectangle {
                    anchors.fill: parent
                    color:   ThemeManager.primaryColor
                    opacity: root.selectedPanel === "variables" ? 0.12 : variablesHover.containsMouse ? 0.06 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                Row {
                    id: variablesRow
                    anchors.centerIn: parent
                    spacing: 7

                    Qaterial.ColorIcon {
                        source: Qaterial.Icons.codeJson
                        color:  root.selectedPanel === "variables" ? ThemeManager.primaryColor : ThemeManager.textColor
                        width: 16; height: 16
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                    Text {
                        text: "Variables"
                        font.pixelSize: 11
                        color: root.selectedPanel === "variables" ? ThemeManager.primaryColor : ThemeManager.textColor
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left:   parent.left;  anchors.right:  parent.right
                    anchors.leftMargin: 6;        anchors.rightMargin: 6
                    height: 2; radius: 1
                    color:   ThemeManager.primaryColor
                    visible: root.selectedPanel === "variables"
                }

                MouseArea {
                    id: variablesHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: root.panelToggled("variables")
                }
            }
        }

        Item { Layout.fillWidth: true }

        // ── Right action buttons ─────────────────────────────────────────────
        Row {
            spacing: 0
            Layout.alignment: Qt.AlignVCenter

            Qaterial.AppBarButton {
                icon.source: Qaterial.Icons.contentSave
                icon.color:  ThemeManager.textColor
                ToolTip.text: "Save"
                ToolTip.visible: hovered
                ToolTip.delay: 500
                width: 40; height: 40
                onClicked: root.saveRequested()
            }

            Qaterial.AppBarButton {
                icon.source: Qaterial.Icons.folderOpenOutline
                icon.color:  ThemeManager.textColor
                ToolTip.text: "Open Project"
                ToolTip.visible: hovered
                ToolTip.delay: 500
                width: 40; height: 40
                onClicked: root.openRequested()
            }

            Qaterial.AppBarButton {
                width: 40; height: 40
                icon.source: Qaterial.Icons.cogOutline
                icon.color:  ThemeManager.textColor
                ToolTip.text: "Settings"
                ToolTip.visible: hovered
                ToolTip.delay: 500
                onClicked: root.settingsRequested()
            }
        }
    }
}
