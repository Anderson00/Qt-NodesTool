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
                text: qsTr("Keyboard Shortcuts")
                font.pixelSize: 22
                font.bold: true
                color: ThemeManager.textColor
                Layout.fillWidth: true
            }
            Button {
                text: qsTr("✕")
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
                    title: qsTr("General")
                    items: [
                        {key: "Ctrl + O", desc: qsTr("Open Workspace")},
                        {key: "Ctrl + S", desc: qsTr("Save Workspace")},
                        {key: "Ctrl + Shift + S", desc: qsTr("Save Workspace As")},
                        {key: "Ctrl + H", desc: qsTr("Toggle History Panel")},
                        {key: "Shift + ?", desc: qsTr("Show this help overlay")}
                    ]
                }

                ShortcutSection {
                    title: qsTr("Nodes & Canvas")
                    items: [
                        {key: "F", desc: qsTr("Focus camera on selected node")},
                        {key: "G", desc: qsTr("Toggle Snap to Grid")},
                        {key: "Ctrl + A", desc: qsTr("Select All Nodes")},
                        {key: "Ctrl + C", desc: qsTr("Copy selected nodes")},
                        {key: "Ctrl + V", desc: qsTr("Paste nodes")},
                        {key: "Ctrl + D", desc: qsTr("Duplicate selected nodes")},
                        {key: "Ctrl + G", desc: qsTr("Group selected nodes")},
                        {key: "Ctrl + Shift + G", desc: qsTr("Ungroup selected nodes")},
                        {key: "Del / Backspace", desc: qsTr("Delete selected nodes")},
                        {key: "Shift + Drag", desc: qsTr("Marquee selection box")},
                        {key: "Esc", desc: qsTr("Cancel action or clear selection")}
                    ]
                }

                ShortcutSection {
                    title: qsTr("Virtual Desktops")
                    items: [
                        {key: "Ctrl + Shift + N", desc: qsTr("Add new Virtual Desktop")},
                        {key: "Ctrl + Right", desc: qsTr("Switch to next Desktop")},
                        {key: "Ctrl + Left", desc: qsTr("Switch to previous Desktop")},
                        {key: "Ctrl + Tab", desc: qsTr("Show Desktop Overview (Exposé)")},
                        {key: "Ctrl + 1..9", desc: qsTr("Jump to Desktop 1 through 9")}
                    ]
                }

                ShortcutSection {
                    title: qsTr("Tools")
                    items: [
                        {key: "Ctrl + Shift + C", desc: qsTr("Toggle Camera overlay")},
                        {key: "Ctrl + Shift + V", desc: qsTr("Toggle Visualization window")}
                    ]
                }

                ShortcutSection {
                    title: qsTr("Presentation Mode")
                    items: [
                        {key: "F10",       desc: qsTr("Cycle Presentation Mode (Off → Quiet → Locked → Off)")},
                        {key: "Shift+F10", desc: qsTr("Exit Presentation Mode immediately")},
                        {key: "Esc",       desc: qsTr("Exit Presentation Mode")},
                        {key: "F5",        desc: qsTr("Next Stage")},
                        {key: "Shift+F5",  desc: qsTr("Previous Stage")}
                    ]
                }
            }
        }
    }
}
