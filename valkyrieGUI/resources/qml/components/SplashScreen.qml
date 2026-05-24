import QtQuick 2.12
import QtQuick.Controls 2.12
import App.Theme 1.0
import App.Workspace 1.0
import App.Properties 1.0
import App.Icons 1.0

import "."

// Startup screen shown when no workspace is active.
// Mirrors the VSCode welcome experience: branding on the left,
// recent projects on the right.
Rectangle {
    id: root

    anchors.fill: parent
    z: 500
    color: ThemeManager.backgroundColor

    // Hide once any workspace becomes active or user explicitly dismisses.
    visible: !dismissed && WorkspaceManager.currentWorkspace === ""
    property bool dismissed: false

    signal newProjectRequested()
    signal openProjectRequested()
    signal workspaceOpenRequested(string name)
    signal workspaceRenameRequested(string name)
    signal workspaceExportRequested(string name)
    signal workspaceDeleteRequested(string name)

    // ── Left panel ────────────────────────────────────────────────────────────
    Rectangle {
        id: leftPanel
        width:  Math.max(260, parent.width * 0.32)
        height: parent.height
        color:  ThemeManager.foregroundColor

        Rectangle {
            anchors.right:  parent.right
            anchors.top:    parent.top
            anchors.bottom: parent.bottom
            width: 1
            color:   ThemeManager.borderColor
        }

        Column {
            anchors.left:       parent.left
            anchors.leftMargin: 36
            anchors.top:        parent.top
            anchors.topMargin:  parent.height * 0.18
            spacing: 0

            // ── Branding ──────────────────────────────────────────────────────
            Text {
                text: "Valkyrie"
                font.pixelSize: 38
                font.bold:      true
                font.letterSpacing: 1.5
                color: ThemeManager.primaryColor
            }

            Item { height: 4; width: 1 }

            Text {
                text: "Node-Based Debugger"
                font.pixelSize: 11
                color:   ThemeManager.foregroundColor
                opacity: 0.45
                font.letterSpacing: 0.5
            }

            Item { height: 52; width: 1 }

            // ── Section label ─────────────────────────────────────────────────
            Text {
                text: "START"
                font.pixelSize: 9
                font.bold: true
                color:   ThemeManager.primaryColor
                opacity: 0.6
                font.letterSpacing: 2
            }

            Item { height: 14; width: 1 }

            // New Project
            ActionRow {
                icon:  Icons.plusCircleOutline
                label: "New Project"
                onClicked: {
                    root.dismissed = true
                    root.newProjectRequested()
                }
            }

            Item { height: 6; width: 1 }

            // Open Project
            ActionRow {
                icon:  Icons.folderOpenOutline
                label: "Open Project..."
                onClicked: root.openProjectRequested()
            }

            // Continue where you left off (only shown when lastWorkspace exists)
            Item {
                visible: GlobalProperties.lastWorkspace !== ""
                height:  visible ? 24 : 0; width: 1
            }

            Rectangle {
                visible: GlobalProperties.lastWorkspace !== ""
                width:  leftPanel.width - 72
                height: 1
                color:  ThemeManager.borderColor
                opacity: 0.5
            }

            Item {
                visible: GlobalProperties.lastWorkspace !== ""
                height:  visible ? 16 : 0; width: 1
            }

            ActionRow {
                visible: GlobalProperties.lastWorkspace !== ""
                icon:    Icons.restore
                label:   "Continue  \"" + GlobalProperties.lastWorkspace + "\""
                onClicked: root.workspaceOpenRequested(GlobalProperties.lastWorkspace)
            }
        }

        // Version tag at bottom-left
        Column {
            anchors.left:         parent.left
            anchors.leftMargin:   36
            anchors.bottom:       parent.bottom
            anchors.bottomMargin: 24
            spacing: 4

            Text {
                text:    "Valkyrie v1.0.0"
                font.pixelSize: 9
                font.bold: true
                color:   ThemeManager.primaryColor
                opacity: 0.6
            }

            Text {
                text:    "Qt 6.5.3  •  C++17"
                font.pixelSize: 8
                color:   ThemeManager.textSecondaryColor
                opacity: 0.5
            }
        }
    }

    // ── Right panel — Recent projects ─────────────────────────────────────────
    Item {
        anchors.left:   leftPanel.right
        anchors.right:  parent.right
        anchors.top:    parent.top
        anchors.bottom: parent.bottom

        Column {
            anchors.left:       parent.left
            anchors.leftMargin: 48
            anchors.top:        parent.top
            anchors.topMargin:  parent.height * 0.18
            width: parent.width - 96
            spacing: 0

            Row {
                spacing: 12
                ColorIcon {
                    source: Icons.history
                    color:  ThemeManager.primaryColor
                    width: 16; height: 16
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: 0.7
                }
                Text {
                    text: "RECENT PROJECTS"
                    font.pixelSize: 10
                    font.bold: true
                    color:   ThemeManager.primaryColor
                    opacity: 0.7
                    font.letterSpacing: 1.2
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Item { height: 20; width: 1 }

            // Empty state
            Text {
                visible: WorkspaceManager.workspaceList.length === 0
                text: "No recent projects yet.\nCreate a project or open an existing one to get started."
                color:       ThemeManager.textSecondaryColor
                opacity:     0.6
                font.pixelSize: 12
                lineHeight:  1.7
                wrapMode:    Text.WordWrap
                width:       parent.width
            }

            // Workspace cards — last opened shown first, highlighted
            Repeater {
                model: {
                    const last = GlobalProperties.lastWorkspace
                    const all  = WorkspaceManager.workspaceList
                    if (last === "") return all
                    // Put last workspace first, then the rest
                    const others = all.filter(n => n !== last)
                    return last !== "" && all.indexOf(last) !== -1
                           ? [last].concat(others)
                           : all
                }

                delegate: Rectangle {
                    id: card
                    readonly property bool isLast: modelData === GlobalProperties.lastWorkspace
                    readonly property string workspaceName: modelData

                    width:  parent ? parent.width : 0
                    height: 60
                    radius: 6
                    color:  cardMouse.containsMouse
                                ? Qt.rgba(ThemeManager.surfaceColor.r,
                                          ThemeManager.surfaceColor.g,
                                          ThemeManager.surfaceColor.b, 0.4)
                                : isLast
                                    ? ThemeManager.surfaceColor
                                    : ThemeManager.backgroundColor
                    border.width: isLast ? 1 : 0
                    border.color: ThemeManager.borderColor

                    // Left accent bar for last-opened
                    Rectangle {
                        visible: card.isLast
                        width: 3; height: parent.height * 0.55; radius: 2
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 2
                        color: ThemeManager.primaryColor
                        opacity: 0.8
                    }

                    Behavior on color { ColorAnimation { duration: 100 } }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left:           parent.left
                        anchors.leftMargin:     16
                        spacing: 12

                        ColorIcon {
                            source: Icons.vectorSquare
                            color:  ThemeManager.primaryColor
                            width: 18; height: 18
                            anchors.verticalCenter: parent.verticalCenter
                            opacity: card.isLast ? 1.0 : 0.7
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                text:  card.workspaceName
                                color: cardMouse.containsMouse || card.isLast
                                           ? ThemeManager.primaryColor
                                           : ThemeManager.textColor
                                font.pixelSize: 13
                                font.bold: card.isLast
                                Behavior on color { ColorAnimation { duration: 100 } }
                            }

                            Text {
                                visible: card.isLast
                                text:    "Last opened"
                                color:   ThemeManager.successColor
                                opacity: 0.75
                                font.pixelSize: 9
                                font.weight: Font.Medium
                            }
                        }
                    }

                    // Three-dots menu trigger — visible on hover
                    Rectangle {
                        id: kebabBtn
                        width: 26; height: 26; radius: 13
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right:          parent.right
                        anchors.rightMargin:    12
                        opacity: cardMouse.containsMouse || kebabHover.containsMouse ? 1.0 : 0.0
                        color: kebabHover.containsMouse
                                   ? Qt.rgba(ThemeManager.primaryColor.r,
                                             ThemeManager.primaryColor.g,
                                             ThemeManager.primaryColor.b, 0.16)
                                   : "transparent"
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                        Behavior on color   { ColorAnimation   { duration: 100 } }

                        Text {
                            anchors.centerIn: parent
                            text: "⋮"
                            font.pixelSize: 18
                            font.bold: true
                            color: ThemeManager.primaryColor
                        }

                        MouseArea {
                            id: kebabHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            onClicked: function(mouse) {
                                // Open menu right-aligned to the kebab button, just below it
                                cardMenu.openAt(kebabBtn.x + kebabBtn.width - cardMenu.width,
                                                kebabBtn.y + kebabBtn.height + 4)
                            }
                        }
                    }

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        anchors.rightMargin: 44  // leave room for the kebab button
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.RightButton) {
                                cardMenu.openAt(mouse.x, mouse.y)
                                return
                            }
                            root.workspaceOpenRequested(card.workspaceName)
                        }
                    }

                    // ── Context menu (themed) ─────────────────────────────────
                    ContextMenu {
                        id: cardMenu
                        items: [
                            { label: "Open",       icon: "▶" },
                            { label: "Rename…",    icon: "✎" },
                            { label: "Duplicate",  icon: "⎘" },
                            { label: "Export…",    icon: "↥" },
                            { separator: true },
                            { label: "Delete",     icon: "✕", danger: true }
                        ]
                        onItemSelected: function(idx, item) {
                            switch (item.label) {
                            case "Open":
                                root.workspaceOpenRequested(card.workspaceName); break
                            case "Rename…":
                                root.workspaceRenameRequested(card.workspaceName); break
                            case "Duplicate":
                                const ok = WorkspaceManager.duplicateWorkspace(card.workspaceName)
                                if (!ok) console.warn("Duplicate failed for", card.workspaceName)
                                break
                            case "Export…":
                                root.workspaceExportRequested(card.workspaceName); break
                            case "Delete":
                                root.workspaceDeleteRequested(card.workspaceName); break
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Dismiss (X) button ────────────────────────────────────────────────────
    AppBarButton {
        anchors.top:         parent.top
        anchors.right:       parent.right
        anchors.topMargin:   6
        anchors.rightMargin: 6
        icon.source: Icons.close
        icon.color:  ThemeManager.foregroundColor
        width: 36; height: 36
        opacity: dismissHover.containsMouse ? 0.7 : 0.3
        onClicked: root.dismissed = true
        AppToolTip { text: "Continue without opening"; visible: parent.hovered; delay: 600 }

        MouseArea {
            id: dismissHover
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            onClicked: mouse.accepted = false
        }
    }

    // ── Internal action-row component ─────────────────────────────────────────
    component ActionRow: Rectangle {
        id: row
        property string icon:  ""
        property string label: ""
        signal clicked()

        width:  leftPanel.width - 72
        height: 38
        radius: 5
        color:  rowMouse.containsMouse
                    ? Qt.rgba(ThemeManager.primaryColor.r,
                              ThemeManager.primaryColor.g,
                              ThemeManager.primaryColor.b, 0.08)
                    : "transparent"
        border.width: rowMouse.containsMouse ? 1 : 0
        border.color: Qt.rgba(ThemeManager.primaryColor.r,
                              ThemeManager.primaryColor.g,
                              ThemeManager.primaryColor.b, 0.3)
        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on border.color { ColorAnimation { duration: 100 } }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left:           parent.left
            anchors.leftMargin:     10
            spacing: 10

            ColorIcon {
                source: row.icon
                color:  ThemeManager.primaryColor
                width: 16; height: 16
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text:  row.label
                color: rowMouse.containsMouse ? ThemeManager.textColor : ThemeManager.textSecondaryColor
                font.pixelSize: 13
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: 100 } }
            }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape:  Qt.PointingHandCursor
            onClicked:    row.clicked()
        }
    }
}

