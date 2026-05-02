import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.0
import App.Theme 1.0
import App.Properties 1.0
import Qaterial as Qaterial

Popup {
    id: root

    modal: true
    dim: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 0

    width: 660
    height: 480

    x: parent ? (parent.width  - width)  / 2 : 0
    y: parent ? (parent.height - height) / 2 : 0

    property string selectedCategory: "appearance"

    onAboutToShow: selectedCategory = "appearance"

    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.55)
    }

    background: Rectangle {
        color: ThemeManager.backgroundColor
        radius: 10
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)
    }

    contentItem: Item {

        // ── Sidebar ────────────────────────────────────────────────────────────
        Rectangle {
            id: sidebar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: 195
            color: Qt.darker(ThemeManager.backgroundColor, 1.3)
            radius: 10

            // mask right-side radius so it blends with content area
            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: parent.radius
                color: parent.color
            }

            Column {
                anchors.fill: parent

                // Header
                Item {
                    width: parent.width
                    height: 56

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        text: "Settings"
                        font.pixelSize: 16
                        font.bold: true
                        color: ThemeManager.textColor
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: ThemeManager.primaryColor
                    opacity: 0.12
                }

                Item { width: 1; height: 8 }

                // ── Category button: Appearance ──
                Item {
                    width: sidebar.width
                    height: 40

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        radius: 6
                        color: ThemeManager.primaryColor
                        opacity: selectedCategory === "appearance"
                                     ? 0.18 : appearanceHover.containsMouse ? 0.07 : 0
                        Behavior on opacity { NumberAnimation { duration: 110 } }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3; height: 22; radius: 2
                        color: ThemeManager.primaryColor
                        visible: selectedCategory === "appearance"
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        spacing: 10

                        Qaterial.ColorIcon {
                            source: Qaterial.Icons.palette
                            color: selectedCategory === "appearance"
                                       ? ThemeManager.primaryColor : ThemeManager.textColor
                            width: 16; height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 110 } }
                        }

                        Text {
                            text: "Appearance"
                            font.pixelSize: 12
                            color: selectedCategory === "appearance"
                                       ? ThemeManager.primaryColor : ThemeManager.textColor
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 110 } }
                        }
                    }

                    MouseArea {
                        id: appearanceHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: selectedCategory = "appearance"
                    }
                }

                // ── Category button: Viewport ──
                Item {
                    width: sidebar.width
                    height: 40

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        radius: 6
                        color: ThemeManager.primaryColor
                        opacity: selectedCategory === "viewport"
                                     ? 0.18 : viewportHover.containsMouse ? 0.07 : 0
                        Behavior on opacity { NumberAnimation { duration: 110 } }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3; height: 22; radius: 2
                        color: ThemeManager.primaryColor
                        visible: selectedCategory === "viewport"
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        spacing: 10

                        Qaterial.ColorIcon {
                            source: Qaterial.Icons.viewDashboard
                            color: selectedCategory === "viewport"
                                       ? ThemeManager.primaryColor : ThemeManager.textColor
                            width: 16; height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 110 } }
                        }

                        Text {
                            text: "Viewport"
                            font.pixelSize: 12
                            color: selectedCategory === "viewport"
                                       ? ThemeManager.primaryColor : ThemeManager.textColor
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 110 } }
                        }
                    }

                    MouseArea {
                        id: viewportHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: selectedCategory = "viewport"
                    }
                }

                // ── Category button: General ──
                Item {
                    width: sidebar.width
                    height: 40

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        radius: 6
                        color: ThemeManager.primaryColor
                        opacity: selectedCategory === "general"
                                     ? 0.18 : generalHover.containsMouse ? 0.07 : 0
                        Behavior on opacity { NumberAnimation { duration: 110 } }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 3; height: 22; radius: 2
                        color: ThemeManager.primaryColor
                        visible: selectedCategory === "general"
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 18
                        spacing: 10

                        Qaterial.ColorIcon {
                            source: Qaterial.Icons.tune
                            color: selectedCategory === "general"
                                       ? ThemeManager.primaryColor : ThemeManager.textColor
                            width: 16; height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 110 } }
                        }

                        Text {
                            text: "General"
                            font.pixelSize: 12
                            color: selectedCategory === "general"
                                       ? ThemeManager.primaryColor : ThemeManager.textColor
                            anchors.verticalCenter: parent.verticalCenter
                            Behavior on color { ColorAnimation { duration: 110 } }
                        }
                    }

                    MouseArea {
                        id: generalHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: selectedCategory = "general"
                    }
                }
            }
        }

        // ── Close button ───────────────────────────────────────────────────────
        Qaterial.AppBarButton {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 6
            anchors.rightMargin: 6
            width: 36; height: 36
            icon.source: Qaterial.Icons.close
            icon.color: ThemeManager.textColor
            onClicked: root.close()
        }

        // ── Content area ───────────────────────────────────────────────────────
        Item {
            anchors.top: parent.top
            anchors.left: sidebar.right
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true

            // ════════════════════ APPEARANCE ═══════════════════════════════════
            ScrollView {
                anchors.fill: parent
                anchors.margins: 28
                visible: selectedCategory === "appearance"
                contentWidth: availableWidth
                clip: true

                Column {
                    width: parent.width
                    spacing: 0

                    Text {
                        text: "Appearance"
                        font.pixelSize: 15
                        font.bold: true
                        color: ThemeManager.textColor
                        bottomPadding: 20
                    }

                    // Section label
                    Text {
                        text: "THEME COLORS"
                        font.pixelSize: 10
                        font.letterSpacing: 1.2
                        color: ThemeManager.textColor
                        opacity: 0.45
                        bottomPadding: 14
                    }

                    // Primary Color
                    RowLayout {
                        width: parent.width
                        height: 44

                        Text {
                            Layout.fillWidth: true
                            text: "Primary Color"
                            font.pixelSize: 12
                            color: ThemeManager.textColor
                            verticalAlignment: Text.AlignVCenter
                        }
                        ColorPicker {
                            id: primaryColorPicker
                            value: ThemeManager.primaryColor
                            showHex: true
                            onAccepted: function(c) { ThemeManager.primaryColor = c }
                        }
                    }

                    // Accent Color
                    RowLayout {
                        width: parent.width
                        height: 44

                        Text {
                            Layout.fillWidth: true
                            text: "Accent Color"
                            font.pixelSize: 12
                            color: ThemeManager.textColor
                            verticalAlignment: Text.AlignVCenter
                        }
                        ColorPicker {
                            value: ThemeManager.accentColor
                            showHex: true
                            onAccepted: function(c) { ThemeManager.accentColor = c }
                        }
                    }

                    // Background Color
                    RowLayout {
                        width: parent.width
                        height: 44

                        Text {
                            Layout.fillWidth: true
                            text: "Background Color"
                            font.pixelSize: 12
                            color: ThemeManager.textColor
                            verticalAlignment: Text.AlignVCenter
                        }
                        ColorPicker {
                            value: ThemeManager.backgroundColor
                            showHex: true
                            onAccepted: function(c) { ThemeManager.backgroundColor = c }
                        }
                    }

                    // Text Color
                    RowLayout {
                        width: parent.width
                        height: 44

                        Text {
                            Layout.fillWidth: true
                            text: "Text Color"
                            font.pixelSize: 12
                            color: ThemeManager.textColor
                            verticalAlignment: Text.AlignVCenter
                        }
                        ColorPicker {
                            value: ThemeManager.textColor
                            showHex: true
                            onAccepted: function(c) { ThemeManager.textColor = c }
                        }
                    }

                    // Danger Color
                    RowLayout {
                        width: parent.width
                        height: 44

                        Text {
                            Layout.fillWidth: true
                            text: "Danger Color"
                            font.pixelSize: 12
                            color: ThemeManager.textColor
                            verticalAlignment: Text.AlignVCenter
                        }
                        ColorPicker {
                            value: ThemeManager.dangerColor
                            showHex: true
                            onAccepted: function(c) { ThemeManager.dangerColor = c }
                        }
                    }

                    Item { width: 1; height: 20 }

                    Rectangle {
                        width: parent.width; height: 1
                        color: ThemeManager.primaryColor; opacity: 0.1
                    }

                    Item { width: 1; height: 20 }

                    Text {
                        text: "THEME MODE"
                        font.pixelSize: 10
                        font.letterSpacing: 1.2
                        color: ThemeManager.textColor
                        opacity: 0.45
                        bottomPadding: 14
                    }

                    RowLayout {
                        width: parent.width
                        height: 44

                        Text {
                            Layout.fillWidth: true
                            text: "Toggle Light / Dark"
                            font.pixelSize: 12
                            color: ThemeManager.textColor
                            verticalAlignment: Text.AlignVCenter
                        }

                        Rectangle {
                            width: 80; height: 30
                            radius: 6
                            color: ThemeManager.primaryColor
                            opacity: toggleThemeHover.containsMouse ? 0.85 : 1
                            Behavior on opacity { NumberAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: "Toggle"
                                font.pixelSize: 11
                                color: "white"
                            }

                            MouseArea {
                                id: toggleThemeHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ThemeManager.toggleTheme()
                            }
                        }
                    }
                }
            }

            // ════════════════════ VIEWPORT ══════════════════════════════════════
            ScrollView {
                anchors.fill: parent
                anchors.margins: 28
                visible: selectedCategory === "viewport"
                contentWidth: availableWidth
                clip: true

                Column {
                    width: parent.width
                    spacing: 0

                    Text {
                        text: "Viewport"
                        font.pixelSize: 15
                        font.bold: true
                        color: ThemeManager.textColor
                        bottomPadding: 20
                    }

                    Text {
                        text: "DISPLAY"
                        font.pixelSize: 10
                        font.letterSpacing: 1.2
                        color: ThemeManager.textColor
                        opacity: 0.45
                        bottomPadding: 14
                    }

                    RowLayout {
                        width: parent.width
                        height: 44

                        Column {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "Show FPS Counter"
                                font.pixelSize: 12
                                color: ThemeManager.textColor
                            }
                            Text {
                                text: "Display frames per second and frame time"
                                font.pixelSize: 10
                                color: ThemeManager.textColor
                                opacity: 0.45
                            }
                        }

                        CustomSwitch {
                            id: fpsSwitch
                            checked: viewPort.showFps
                            onToggled: viewPort.setShowFps(fpsSwitch.checked)
                        }
                    }
                }
            }

            // ════════════════════ GENERAL ═══════════════════════════════════════
            ScrollView {
                anchors.fill: parent
                anchors.margins: 28
                visible: selectedCategory === "general"
                contentWidth: availableWidth
                clip: true

                Column {
                    width: parent.width
                    spacing: 0

                    Text {
                        text: "General"
                        font.pixelSize: 15
                        font.bold: true
                        color: ThemeManager.textColor
                        bottomPadding: 20
                    }

                    Text {
                        text: "APPLICATION"
                        font.pixelSize: 10
                        font.letterSpacing: 1.2
                        color: ThemeManager.textColor
                        opacity: 0.45
                        bottomPadding: 14
                    }

                    RowLayout {
                        width: parent.width
                        height: 44

                        Column {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "Debug Mode"
                                font.pixelSize: 12
                                color: ThemeManager.textColor
                            }
                            Text {
                                text: "Enable verbose logging and diagnostics"
                                font.pixelSize: 10
                                color: ThemeManager.textColor
                                opacity: 0.45
                            }
                        }

                        CustomSwitch {
                            id: debugSwitch
                            checked: GlobalProperties.debugMode
                            onToggled: {
                                GlobalProperties.debugMode = debugSwitch.checked
                                GlobalProperties.saveProperties()
                            }
                        }
                    }

                    Item { width: 1; height: 20 }

                    Rectangle {
                        width: parent.width; height: 1
                        color: ThemeManager.primaryColor; opacity: 0.1
                    }

                    Item { width: 1; height: 20 }

                    Text {
                        text: "ABOUT"
                        font.pixelSize: 10
                        font.letterSpacing: 1.2
                        color: ThemeManager.textColor
                        opacity: 0.45
                        bottomPadding: 14
                    }

                    RowLayout {
                        width: parent.width
                        height: 44

                        Text {
                            Layout.fillWidth: true
                            text: "Valkyrie Nodes Tool"
                            font.pixelSize: 12
                            color: ThemeManager.textColor
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            text: "v1.0.0"
                            font.pixelSize: 11
                            color: ThemeManager.primaryColor
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
    }
}
