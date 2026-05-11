import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.0
import App.Theme 1.0
import App.Icons 1.0

import ".."

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
    signal screenshotRequested()
    signal newProjectRequested()
    signal cameraToggled()
    signal visualizationToggled()
    signal saveRequested()
    signal openRequested()
    signal undoRequested()
    signal redoRequested()

    property bool canUndo:           false
    property bool canRedo:           false
    property bool isDirty:           false
    property bool historyPanelOpen:  false
    property bool showCamera:        false
    property bool showVisualization: false

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
                text: root.currentProject + (root.isDirty ? " •" : "")
                font.pixelSize: 12
                color:   root.isDirty ? ThemeManager.primaryColor : ThemeManager.textColor
                opacity: root.isDirty ? 0.75 : 0.55
                height:  root.barHeight
                verticalAlignment: Text.AlignVCenter
                Behavior on color   { ColorAnimation { duration: 150 } }
                Behavior on opacity { NumberAnimation { duration: 150 } }
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

                    ColorIcon {
                        source: Icons.graphOutline
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

                    ColorIcon {
                        source: Icons.folderOutline
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

                    ColorIcon {
                        source: Icons.codeJson
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

            AppBarButton {
                icon.source: Icons.history
                icon.color:  root.historyPanelOpen ? ThemeManager.primaryColor : ThemeManager.textColor
                width: 40; height: 40
                onClicked: root.historyPanelOpen = !root.historyPanelOpen
                Behavior on icon.color { ColorAnimation { duration: 150 } }
                AppToolTip { text: "Histórico (Ctrl+H)"; visible: parent.hovered }
            }

            AppBarButton {
                icon.source: Icons.undo
                icon.color:  root.canUndo ? ThemeManager.textColor : Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.3)
                enabled:     root.canUndo
                width: 40; height: 40
                onClicked: root.undoRequested()
                AppToolTip { text: "Undo (Ctrl+Z)"; visible: parent.hovered }
            }

            AppBarButton {
                icon.source: Icons.redo
                icon.color:  root.canRedo ? ThemeManager.textColor : Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.3)
                enabled:     root.canRedo
                width: 40; height: 40
                onClicked: root.redoRequested()
                AppToolTip { text: "Redo (Ctrl+Y)"; visible: parent.hovered }
            }

            AppBarButton {
                icon.source: Icons.filePlusOutline
                icon.color:  ThemeManager.textColor
                width: 40; height: 40
                onClicked: root.newProjectRequested()
                AppToolTip { text: "New Project"; visible: parent.hovered }
            }

            AppBarButton {
                icon.source: Icons.contentSave
                icon.color:  root.isDirty
                                 ? ThemeManager.textColor
                                 : Qt.rgba(ThemeManager.textColor.r,
                                           ThemeManager.textColor.g,
                                           ThemeManager.textColor.b, 0.3)
                enabled:     root.isDirty
                width: 40; height: 40
                onClicked: root.saveRequested()
                Behavior on icon.color { ColorAnimation { duration: 150 } }
                AppToolTip { text: "Save  (Ctrl+S)"; visible: parent.hovered }
            }

            AppBarButton {
                icon.source: Icons.folderOpenOutline
                icon.color:  ThemeManager.textColor
                width: 40; height: 40
                onClicked: root.openRequested()
                AppToolTip { text: "Open Project"; visible: parent.hovered }
            }

            // ── Camera / Visualization separator ──────────────────────────────
            Rectangle {
                width: 1; height: 18; color: ThemeManager.textColor; opacity: 0.2
                anchors.verticalCenter: parent.verticalCenter
            }

            AppBarButton {
                width: 40; height: 40
                icon.source: Icons.cropFree
                icon.color:  root.showCamera ? "#FF9800"
                                             : Qt.rgba(ThemeManager.textColor.r,
                                                       ThemeManager.textColor.g,
                                                       ThemeManager.textColor.b, 0.6)
                onClicked: root.cameraToggled()
                Behavior on icon.color { ColorAnimation { duration: 150 } }
                AppToolTip { text: "Camera frame (Ctrl+Shift+C)"; visible: parent.hovered }
            }

            AppBarButton {
                width: 40; height: 40
                icon.source: Icons.television
                icon.color:  root.showVisualization ? "#FF9800"
                                                    : Qt.rgba(ThemeManager.textColor.r,
                                                              ThemeManager.textColor.g,
                                                              ThemeManager.textColor.b, 0.6)
                onClicked: root.visualizationToggled()
                Behavior on icon.color { ColorAnimation { duration: 150 } }
                AppToolTip { text: "Visualization window (Ctrl+Shift+V)"; visible: parent.hovered }
            }

            Rectangle {
                width: 1; height: 18; color: ThemeManager.textColor; opacity: 0.2
                anchors.verticalCenter: parent.verticalCenter
            }

            AppBarButton {
                width: 40; height: 40
                icon.source: Icons.cameraOutline
                icon.color:  ThemeManager.textColor
                onClicked: root.screenshotRequested()
                AppToolTip { text: "Screenshot"; visible: parent.hovered }
            }

            AppBarButton {
                width: 40; height: 40
                icon.source: Icons.cog
                icon.color:  ThemeManager.textColor
                onClicked: root.settingsRequested()
                AppToolTip { text: "Settings"; visible: parent.hovered }
            }
        }
    }
}

