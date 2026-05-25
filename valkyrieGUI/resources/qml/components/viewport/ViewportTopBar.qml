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
    signal saveAsRequested()
    signal openRequested()
    signal undoRequested()
    signal redoRequested()
    signal homeRequested()
    signal renameRequested(string newName)

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

            // Valkyrie logo — clickable, returns to home (SplashScreen)
            Item {
                id: logoBtn
                width:  logoText.implicitWidth
                height: root.barHeight

                Text {
                    id: logoText
                    text: qsTr("Valkyrie")
                    font.pixelSize: 14
                    font.bold: true
                    font.letterSpacing: 0.8
                    color: ThemeManager.primaryColor
                    opacity: logoHover.containsMouse ? 0.75 : 1.0
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                // Subtle underline on hover
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 12
                    anchors.left:   logoText.left
                    anchors.right:  logoText.right
                    height: 1
                    color:   ThemeManager.primaryColor
                    opacity: logoHover.containsMouse ? 0.8 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                MouseArea {
                    id: logoHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked:    root.homeRequested()
                }

                AppToolTip { text: qsTr("Back to Home"); visible: logoHover.containsMouse; delay: 500 }
            }

            Item { width: 12; height: 1 }

            Rectangle {
                width: 1; height: 16
                color:   ThemeManager.textColor
                opacity: 0.3
                anchors.verticalCenter: parent.verticalCenter
            }

            Item { width: 12; height: 1 }

            // Project name — view / edit mode toggle
            Item {
                id: projectNameWrap
                property bool editing: false
                width:  Math.max(80, (projectNameWrap.editing ? projectNameEdit.implicitWidth + 16 : projectNameView.implicitWidth + editIcon.width + 14))
                height: root.barHeight

                // View mode
                Row {
                    visible: !projectNameWrap.editing
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Text {
                        id: projectNameView
                        text: root.currentProject + (root.isDirty ? " •" : "")
                        font.pixelSize: 12
                        color:   root.isDirty ? ThemeManager.primaryColor : ThemeManager.textColor
                        opacity: root.isDirty ? 0.75 : (projectNameHover.containsMouse ? 0.9 : 0.55)
                        verticalAlignment: Text.AlignVCenter
                        Behavior on color   { ColorAnimation { duration: 150 } }
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    // Pencil icon — visible on hover, hint that name is editable
                    ColorIcon {
                        id: editIcon
                        source: Icons.pencilOutline
                        color:  ThemeManager.textColor
                        width: 12; height: 12
                        opacity: projectNameHover.containsMouse ? 0.7 : 0.0
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }
                }

                // Edit mode
                Rectangle {
                    visible: projectNameWrap.editing
                    anchors.fill: parent
                    anchors.topMargin: 8
                    anchors.bottomMargin: 8
                    radius: 4
                    color:  Qt.darker(ThemeManager.backgroundColor, 1.6)
                    border.color: ThemeManager.primaryColor
                    border.width: 1

                    TextInput {
                        id: projectNameEdit
                        anchors.fill:        parent
                        anchors.leftMargin:  8
                        anchors.rightMargin: 8
                        verticalAlignment:   TextInput.AlignVCenter
                        color:               ThemeManager.textColor
                        font.pixelSize:      12
                        selectByMouse:       true
                        clip:                true

                        function commit() {
                            const newName = (projectNameEdit.text || "").trim()
                            const oldName = root.currentProject
                            if (newName !== "" && newName !== oldName)
                                root.renameRequested(newName)
                            projectNameWrap.editing = false
                        }
                        function cancel() { projectNameWrap.editing = false }

                        Keys.onReturnPressed: commit()
                        Keys.onEnterPressed:  commit()
                        Keys.onEscapePressed: cancel()
                        onActiveFocusChanged: if (!activeFocus && projectNameWrap.editing) commit()
                    }
                }

                MouseArea {
                    id: projectNameHover
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled:      !projectNameWrap.editing
                    cursorShape:  Qt.IBeamCursor
                    onDoubleClicked: {
                        projectNameEdit.text = root.currentProject
                        projectNameWrap.editing = true
                        projectNameEdit.selectAll()
                        projectNameEdit.forceActiveFocus()
                    }
                }

                AppToolTip {
                    text: qsTr("Double-click to rename")
                    visible: projectNameHover.containsMouse && !projectNameWrap.editing
                    delay: 600
                }
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
                        text: qsTr("Nodes")
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
                        text: qsTr("Explorer")
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
                        text: qsTr("Variables")
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
                AppToolTip { text: qsTr("Histórico (Ctrl+H)"); visible: parent.hovered }
            }

            AppBarButton {
                icon.source: Icons.undo
                icon.color:  root.canUndo ? ThemeManager.textColor : Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.3)
                enabled:     root.canUndo
                width: 40; height: 40
                onClicked: root.undoRequested()
                AppToolTip { text: qsTr("Undo (Ctrl+Z)"); visible: parent.hovered }
            }

            AppBarButton {
                icon.source: Icons.redo
                icon.color:  root.canRedo ? ThemeManager.textColor : Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.3)
                enabled:     root.canRedo
                width: 40; height: 40
                onClicked: root.redoRequested()
                AppToolTip { text: qsTr("Redo (Ctrl+Y)"); visible: parent.hovered }
            }

            AppBarButton {
                icon.source: Icons.filePlusOutline
                icon.color:  ThemeManager.textColor
                width: 40; height: 40
                onClicked: root.newProjectRequested()
                AppToolTip { text: qsTr("New Project"); visible: parent.hovered }
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
                AppToolTip { text: qsTr("Save  (Ctrl+S)"); visible: parent.hovered }
            }

            AppBarButton {
                icon.source: Icons.contentSaveOutline
                icon.color:  ThemeManager.textColor
                width: 40; height: 40
                onClicked: root.saveAsRequested()
                AppToolTip { text: qsTr("Save As…  (Ctrl+Shift+S)"); visible: parent.hovered }
            }

            AppBarButton {
                icon.source: Icons.folderOpenOutline
                icon.color:  ThemeManager.textColor
                width: 40; height: 40
                onClicked: root.openRequested()
                AppToolTip { text: qsTr("Open Project"); visible: parent.hovered }
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
                AppToolTip { text: qsTr("Camera frame (Ctrl+Shift+C)"); visible: parent.hovered }
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
                AppToolTip { text: qsTr("Visualization window (Ctrl+Shift+V)"); visible: parent.hovered }
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
                AppToolTip { text: qsTr("Screenshot"); visible: parent.hovered }
            }

            AppBarButton {
                width: 40; height: 40
                icon.source: Icons.cog
                icon.color:  ThemeManager.textColor
                onClicked: root.settingsRequested()
                AppToolTip { text: qsTr("Settings"); visible: parent.hovered }
            }
        }
    }
}

