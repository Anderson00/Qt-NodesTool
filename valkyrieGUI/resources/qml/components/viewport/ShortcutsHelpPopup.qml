import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls.Material 2.12
import App.Theme 1.0

Popup {
    id: root
    x: 0
    y: 0
    width: parent.width
    height: parent.height
    modal: true
    dim: false // Prevents Qt from drawing a SECOND dark overlay behind us
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 0
    margins: 0

    background: Rectangle {
        color: Qt.rgba(ThemeManager.backgroundColor.r, ThemeManager.backgroundColor.g, ThemeManager.backgroundColor.b, 0.85)
    }

    // Keyboard shortcut to close it when pressing ? again or Esc
    Shortcut {
        sequence: "Shift+?"
        onActivated: root.close()
        enabled: root.visible
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 64
        spacing: 24

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Keyboard Shortcuts"
                font.pixelSize: 22
                font.bold: true
                color: ThemeManager.textColor
                Layout.fillWidth: true
            }
            Button {
                text: "✕"
                font.pixelSize: 16
                flat: true
                Layout.preferredWidth: 40
                Material.foreground: ThemeManager.textColor
                onClicked: root.close()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: ThemeManager.borderColor
        }

        ScrollView {
            id: scroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            Flow {
                width: scroll.availableWidth
                spacing: 64

                // Helper component for sections
                component ShortcutSection: ColumnLayout {
                    property string title
                    property var items: [] // array of {key: "...", desc: "..."}
                    spacing: 16
                    width: 400

                    Text {
                        text: title
                        font.pixelSize: 18
                        font.bold: true
                        color: ThemeManager.primaryColor
                    }

                    GridLayout {
                        columns: 2
                        columnSpacing: 32
                        rowSpacing: 8
                        Layout.fillWidth: true

                        Repeater {
                            model: items
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                // Key badge
                                Rectangle {
                                    color: Qt.darker(ThemeManager.surfaceColor, 1.2)
                                    border.color: ThemeManager.borderColor
                                    border.width: 1
                                    radius: 4
                                    implicitWidth: keyText.implicitWidth + 16
                                    implicitHeight: keyText.implicitHeight + 8
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        id: keyText
                                        anchors.centerIn: parent
                                        text: modelData.key
                                        color: ThemeManager.textColor
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                }

                                // Description
                                Text {
                                    text: modelData.desc
                                    color: ThemeManager.textSecondaryColor
                                    font.pixelSize: 13
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    Layout.alignment: Qt.AlignVCenter
                                }
                            }
                        }
                    }
                }

                ShortcutSection {
                    title: "General"
                    items: [
                        {key: "Ctrl + O", desc: "Open Workspace"},
                        {key: "Ctrl + S", desc: "Save Workspace"},
                        {key: "Ctrl + Shift + S", desc: "Save Workspace As"},
                        {key: "Ctrl + H", desc: "Toggle History Panel"},
                        {key: "Shift + ?", desc: "Show this help overlay"}
                    ]
                }

                ShortcutSection {
                    title: "Nodes & Canvas"
                    items: [
                        {key: "F", desc: "Focus camera on selected node"},
                        {key: "G", desc: "Toggle Snap to Grid"},
                        {key: "Ctrl + A", desc: "Select All Nodes"},
                        {key: "Ctrl + C", desc: "Copy selected nodes"},
                        {key: "Ctrl + V", desc: "Paste nodes"},
                        {key: "Ctrl + D", desc: "Duplicate selected nodes"},
                        {key: "Ctrl + G", desc: "Group selected nodes"},
                        {key: "Ctrl + Shift + G", desc: "Ungroup selected nodes"},
                        {key: "Del / Backspace", desc: "Delete selected nodes"},
                        {key: "Shift + Drag", desc: "Marquee selection box"},
                        {key: "Esc", desc: "Cancel action or clear selection"}
                    ]
                }

                ShortcutSection {
                    title: "Virtual Desktops"
                    items: [
                        {key: "Ctrl + Shift + N", desc: "Add new Virtual Desktop"},
                        {key: "Ctrl + Right", desc: "Switch to next Desktop"},
                        {key: "Ctrl + Left", desc: "Switch to previous Desktop"},
                        {key: "Ctrl + Tab", desc: "Show Desktop Overview (Exposé)"},
                        {key: "Ctrl + 1..9", desc: "Jump to Desktop 1 through 9"}
                    ]
                }

                ShortcutSection {
                    title: "Tools"
                    items: [
                        {key: "Ctrl + Shift + C", desc: "Toggle Camera overlay"},
                        {key: "Ctrl + Shift + V", desc: "Toggle Visualization window"}
                    ]
                }
            }
        }
    }
}
