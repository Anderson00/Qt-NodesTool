import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.0
import App.Theme 1.0
import App.Desktop 1.0
import App.Icons 1.0

import ".."

// Horizontal strip of virtual-desktop tabs, sitting between the top app bar
// and the canvas container. Each tab represents one DesktopManager entry; the
// active tab is highlighted. Double-clicking a tab activates inline rename.
Rectangle {
    id: root
    height: 36
    color: Qt.darker(ThemeManager.backgroundColor, 1.22)

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left:   parent.left
        anchors.right:  parent.right
        height: 1
        color:   ThemeManager.primaryColor
        opacity: 0.18
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin:  8
        anchors.rightMargin: 8
        spacing: 4

        // ── Tabs (scrollable) ────────────────────────────────────────────────
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ScrollBar.horizontal.policy: ScrollBar.AsNeeded
            ScrollBar.vertical.policy:   ScrollBar.AlwaysOff
            clip: true

            Row {
                spacing: 4
                height: root.height

                Repeater {
                    id: tabsRepeater
                    model: DesktopManager.desktopList

                    delegate: Rectangle {
                        id: tab
                        readonly property bool isActive: modelData.id === DesktopManager.currentDesktopId
                        property bool editing: false

                        height: 26
                        width: Math.max(96, tabContent.implicitWidth + 36)
                        radius: 13
                        anchors.verticalCenter: parent.verticalCenter

                        color: isActive
                                ? Qt.rgba(modelData.color.r !== undefined ? modelData.color.r : 0.3,
                                          0.6, 0.6, 0.18)
                                : tabHover.containsMouse
                                    ? Qt.rgba(ThemeManager.primaryColor.r,
                                              ThemeManager.primaryColor.g,
                                              ThemeManager.primaryColor.b, 0.08)
                                    : "transparent"
                        border.width: isActive ? 1 : 0
                        border.color: isActive ? modelData.color : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        // ── Color dot ─────────────────────────────────────
                        Rectangle {
                            anchors.left:           parent.left
                            anchors.leftMargin:     10
                            anchors.verticalCenter: parent.verticalCenter
                            width:  8; height: 8; radius: 4
                            color:  modelData.color
                        }

                        // ── Tab content (text OR text input) ──────────────
                        Row {
                            id: tabContent
                            anchors.left:           parent.left
                            anchors.leftMargin:     22
                            anchors.right:          parent.right
                            anchors.rightMargin:    10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 4

                            // View mode
                            Text {
                                visible: !tab.editing
                                text:    modelData.name
                                color:   tab.isActive ? modelData.color : ThemeManager.textColor
                                font.pixelSize: 11
                                font.bold:      tab.isActive
                                opacity:        tab.isActive ? 1.0 : 0.85
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: 100 } }
                            }
                            Text {
                                visible: !tab.editing && modelData.nodeCount > 0
                                text:    "(" + modelData.nodeCount + ")"
                                color:   ThemeManager.textSecondaryColor
                                font.pixelSize: 9
                                opacity: 0.55
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            // Edit mode
                            TextInput {
                                id: tabRenameField
                                visible: tab.editing
                                width:   parent.width - 8
                                color:   ThemeManager.textColor
                                font.pixelSize: 11
                                font.bold:      true
                                selectByMouse:  true
                                anchors.verticalCenter: parent.verticalCenter

                                function commit() {
                                    const n = (tabRenameField.text || "").trim()
                                    if (n !== "" && n !== modelData.name)
                                        DesktopManager.renameDesktop(modelData.id, n)
                                    tab.editing = false
                                }
                                function cancel() { tab.editing = false }
                                Keys.onReturnPressed: commit()
                                Keys.onEnterPressed:  commit()
                                Keys.onEscapePressed: cancel()
                                onActiveFocusChanged: if (!activeFocus && tab.editing) commit()
                            }
                        }

                        MouseArea {
                            id: tabHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape:  Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: function(mouse) {
                                if (mouse.button === Qt.RightButton) {
                                    tabMenu.popup()
                                    return
                                }
                                if (!tab.editing)
                                    DesktopManager.switchToDesktop(modelData.id)
                            }
                            onDoubleClicked: {
                                tabRenameField.text = modelData.name
                                tab.editing = true
                                Qt.callLater(function() {
                                    tabRenameField.selectAll()
                                    tabRenameField.forceActiveFocus()
                                })
                            }
                        }

                        // ── Context menu ──────────────────────────────────
                        Menu {
                            id: tabMenu
                            // Capture this tab's identity so nested Repeater
                            // delegates don't shadow `modelData`.
                            readonly property string tabId:   modelData.id
                            readonly property string tabName: modelData.name

                            background: Rectangle {
                                implicitWidth: 180
                                color: ThemeManager.surfaceColor
                                radius: 6
                                border.color: ThemeManager.borderColor
                                border.width: 1
                            }
                            MenuItem {
                                text: "Rename"
                                onTriggered: {
                                    tabRenameField.text = tabMenu.tabName
                                    tab.editing = true
                                    Qt.callLater(function() {
                                        tabRenameField.selectAll()
                                        tabRenameField.forceActiveFocus()
                                    })
                                }
                            }
                            MenuItem {
                                text: "Duplicate"
                                onTriggered: DesktopManager.duplicateDesktop(tabMenu.tabId)
                            }
                            Menu {
                                title: "Color"
                                Repeater {
                                    model: ["#4CAF50", "#2196F3", "#FF9800", "#9C27B0", "#F44336", "#00BCD4", "#FF5722", "#607D8B"]
                                    MenuItem {
                                        text: "■ " + modelData
                                        onTriggered: DesktopManager.setDesktopColor(tabMenu.tabId, modelData)
                                    }
                                }
                            }
                            MenuSeparator {}
                            MenuItem {
                                text: "Delete"
                                enabled: DesktopManager.desktopCount > 1
                                onTriggered: DesktopManager.removeDesktop(tabMenu.tabId)
                            }
                        }
                    }
                }
            }
        }

        // ── Add desktop button ───────────────────────────────────────────────
        Rectangle {
            width: 28; height: 26; radius: 13
            color: addHover.containsMouse
                       ? Qt.rgba(ThemeManager.primaryColor.r,
                                 ThemeManager.primaryColor.g,
                                 ThemeManager.primaryColor.b, 0.18)
                       : "transparent"
            border.color: ThemeManager.primaryColor
            border.width: 1
            Behavior on color { ColorAnimation { duration: 100 } }
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "+"
                font.pixelSize: 15
                font.bold: true
                color: ThemeManager.primaryColor
            }

            MouseArea {
                id: addHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onClicked: DesktopManager.addDesktop("")
            }

            AppToolTip { text: "New desktop (Ctrl+Shift+N)"; visible: addHover.containsMouse; delay: 500 }
        }

        // ── Desktop count badge ──────────────────────────────────────────────
        Text {
            text: DesktopManager.desktopCount + " desktop" + (DesktopManager.desktopCount === 1 ? "" : "s")
            color: ThemeManager.textSecondaryColor
            font.pixelSize: 10
            opacity: 0.55
            Layout.alignment: Qt.AlignVCenter
            Layout.leftMargin: 6
        }
    }
}
