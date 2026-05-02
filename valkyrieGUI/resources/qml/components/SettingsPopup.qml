import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.0
import App.Theme 1.0
import App.Properties 1.0
import App.Presets 1.0
import Qaterial as Qaterial

Popup {
    id: root

    modal: true
    dim: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: 0

    width: 840
    height: 640

    x: parent ? (parent.width  - width)  / 2 : 0
    y: parent ? (parent.height - height) / 2 : 0

    property string selectedCategory: "appearance"

    onAboutToShow: selectedCategory = "appearance"

    // ── Shared inline components ───────────────────────────────────────────────
    component SectionLabel: Text {
        width: parent ? parent.width : 0
        font.pixelSize: 10
        font.letterSpacing: 1.2
        color: ThemeManager.textColor
        opacity: 0.45
        topPadding: 20
        bottomPadding: 10
    }

    component ColorRow: RowLayout {
        property string label: ""
        property color value: "black"
        signal accepted(color c)
        width: parent ? parent.width : 0
        height: 44
        Text {
            Layout.fillWidth: true
            text: parent.label
            font.pixelSize: 12
            color: ThemeManager.textColor
            verticalAlignment: Text.AlignVCenter
        }
        ColorPicker {
            value: parent.value
            showHex: true
            onAccepted: function(c) { parent.accepted(c) }
        }
    }

    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.55)
    }

    background: Rectangle {
        color: ThemeManager.backgroundColor
        radius: 10
        border.width: 1
        border.color: ThemeManager.borderColor
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
                contentHeight: appearanceColumn.implicitHeight
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                rightPadding: ScrollBar.vertical.visible ? ScrollBar.vertical.width + 4 : 0
                clip: true

                Column {
                    id: appearanceColumn
                    width: parent.width
                    spacing: 0

                    Text {
                        text: "Appearance"
                        font.pixelSize: 15
                        font.bold: true
                        color: ThemeManager.textColor
                        bottomPadding: 20
                    }

                    // ── THEME MODE ──────────────────────────────────────────────
                    SectionLabel { text: "THEME MODE" }

                    RowLayout {
                        width: parent.width
                        height: 44
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: ThemeManager.isDarkMode ? "Dark Mode" : "Light Mode"
                            font.pixelSize: 12
                            color: ThemeManager.textColor
                            verticalAlignment: Text.AlignVCenter
                        }

                        // Light button
                        Rectangle {
                            width: 68; height: 30; radius: 6
                            color: !ThemeManager.isDarkMode ? ThemeManager.primaryColor
                                                            : Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.4)
                            border.width: 1
                            border.color: !ThemeManager.isDarkMode ? ThemeManager.primaryColor : ThemeManager.borderColor
                            Behavior on color { ColorAnimation { duration: 150 } }
                            opacity: lightHover.containsMouse ? 0.8 : 1
                            Text {
                                anchors.centerIn: parent
                                text: "☀  Light"
                                font.pixelSize: 11
                                color: !ThemeManager.isDarkMode ? ThemeManager.backgroundColor : ThemeManager.textColor
                            }
                            MouseArea {
                                id: lightHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ThemeManager.setThemeMode(ThemeManager.ThemeMode.Light)
                            }
                        }

                        // Dark button
                        Rectangle {
                            width: 68; height: 30; radius: 6
                            color: ThemeManager.isDarkMode ? ThemeManager.primaryColor
                                                           : Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.4)
                            border.width: 1
                            border.color: ThemeManager.isDarkMode ? ThemeManager.primaryColor : ThemeManager.borderColor
                            Behavior on color { ColorAnimation { duration: 150 } }
                            opacity: darkHover.containsMouse ? 0.8 : 1
                            Text {
                                anchors.centerIn: parent
                                text: "☾  Dark"
                                font.pixelSize: 11
                                color: ThemeManager.isDarkMode ? ThemeManager.backgroundColor : ThemeManager.textColor
                            }
                            MouseArea {
                                id: darkHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ThemeManager.setThemeMode(ThemeManager.ThemeMode.Dark)
                            }
                        }
                    }

                    Item { width: 1; height: 8 }
                    Rectangle { width: parent.width; height: 1; color: ThemeManager.borderColor; opacity: 0.3 }

                    // ── PRESETS ─────────────────────────────────────────────────
                    SectionLabel { text: "PRESETS" }

                    Flow {
                        width: parent.width
                        spacing: 10
                        bottomPadding: 4

                        Repeater {
                            model: PresetManager.presets

                            delegate: Rectangle {
                                id: presetCard

                                // keep outer modelData accessible inside nested Repeater
                                property var preset: modelData

                                width: 155
                                height: 90
                                radius: 9
                                color: preset.backgroundColor
                                clip: true

                                scale: presetMa.containsMouse ? 1.04 : 1.0
                                Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutQuad } }

                                border.width: presetMa.containsMouse ? 2 : 1
                                border.color: presetMa.containsMouse
                                              ? preset.primaryColor
                                              : Qt.rgba(preset.borderColor.r,
                                                        preset.borderColor.g,
                                                        preset.borderColor.b, 0.6)
                                Behavior on border.width { NumberAnimation { duration: 130 } }

                                // ── 6-color strip at top ──────────────────────────
                                Row {
                                    id: colorStrip
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 8

                                    property list<color> colors: [
                                        presetCard.preset.primaryColor,
                                        presetCard.preset.secondaryColor,
                                        presetCard.preset.accentColor,
                                        presetCard.preset.successColor,
                                        presetCard.preset.warningColor,
                                        presetCard.preset.dangerColor
                                    ]

                                    Repeater {
                                        model: colorStrip.colors
                                        Rectangle {
                                            width: presetCard.width / 6
                                            height: colorStrip.height
                                            color: modelData
                                        }
                                    }
                                }

                                // ── surface accent bar (left) ─────────────────────
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: colorStrip.bottom
                                    anchors.bottom: footerBar.top
                                    width: 4
                                    color: preset.surfaceColor
                                    opacity: 0.5
                                }

                                // ── footer bar ────────────────────────────────────
                                Rectangle {
                                    id: footerBar
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 26
                                    color: Qt.rgba(0, 0, 0, 0.30)

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 6
                                        text: preset.name
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: preset.textColor
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    id: presetMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: PresetManager.applyPreset(index)
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 8 }
                    Rectangle { width: parent.width; height: 1; color: ThemeManager.borderColor; opacity: 0.3 }

                    // ── STRUCTURAL ──────────────────────────────────────────────
                    SectionLabel { text: "STRUCTURAL" }

                    ColorRow {
                        label: "Background"
                        value: ThemeManager.backgroundColor
                        onAccepted: function(c) { ThemeManager.backgroundColor = c }
                    }
                    ColorRow {
                        label: "Surface"
                        value: ThemeManager.surfaceColor
                        onAccepted: function(c) { ThemeManager.surfaceColor = c }
                    }
                    ColorRow {
                        label: "Foreground (panels)"
                        value: ThemeManager.foregroundColor
                        onAccepted: function(c) { ThemeManager.foregroundColor = c }
                    }
                    ColorRow {
                        label: "Border"
                        value: ThemeManager.borderColor
                        onAccepted: function(c) { ThemeManager.borderColor = c }
                    }
                    ColorRow {
                        label: "Shadow"
                        value: ThemeManager.shadowColor
                        onAccepted: function(c) { ThemeManager.shadowColor = c }
                    }

                    Rectangle { width: parent.width; height: 1; color: ThemeManager.borderColor; opacity: 0.3 }

                    // ── BRAND / ACTIONS ─────────────────────────────────────────
                    SectionLabel { text: "BRAND / ACTIONS" }

                    ColorRow {
                        label: "Primary"
                        value: ThemeManager.primaryColor
                        onAccepted: function(c) { ThemeManager.primaryColor = c }
                    }
                    ColorRow {
                        label: "Secondary"
                        value: ThemeManager.secondaryColor
                        onAccepted: function(c) { ThemeManager.secondaryColor = c }
                    }
                    ColorRow {
                        label: "Accent"
                        value: ThemeManager.accentColor
                        onAccepted: function(c) { ThemeManager.accentColor = c }
                    }

                    Rectangle { width: parent.width; height: 1; color: ThemeManager.borderColor; opacity: 0.3 }

                    // ── SEMANTIC STATES ─────────────────────────────────────────
                    SectionLabel { text: "SEMANTIC STATES" }

                    ColorRow {
                        label: "Success"
                        value: ThemeManager.successColor
                        onAccepted: function(c) { ThemeManager.successColor = c }
                    }
                    ColorRow {
                        label: "Warning"
                        value: ThemeManager.warningColor
                        onAccepted: function(c) { ThemeManager.warningColor = c }
                    }
                    ColorRow {
                        label: "Danger"
                        value: ThemeManager.dangerColor
                        onAccepted: function(c) { ThemeManager.dangerColor = c }
                    }

                    Rectangle { width: parent.width; height: 1; color: ThemeManager.borderColor; opacity: 0.3 }

                    // ── TYPOGRAPHY ──────────────────────────────────────────────
                    SectionLabel { text: "TYPOGRAPHY" }

                    ColorRow {
                        label: "Text"
                        value: ThemeManager.textColor
                        onAccepted: function(c) { ThemeManager.textColor = c }
                    }
                    ColorRow {
                        label: "Text Secondary"
                        value: ThemeManager.textSecondaryColor
                        onAccepted: function(c) { ThemeManager.textSecondaryColor = c }
                    }
                    ColorRow {
                        label: "Selection"
                        value: ThemeManager.selectionColor
                        onAccepted: function(c) { ThemeManager.selectionColor = c }
                    }

                    Item { width: 1; height: 28 }
                }
            }

            // ════════════════════ VIEWPORT ══════════════════════════════════════
            ScrollView {
                anchors.fill: parent
                anchors.margins: 28
                visible: selectedCategory === "viewport"
                contentWidth: availableWidth
                contentHeight: viewportColumn.implicitHeight
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                rightPadding: ScrollBar.vertical.visible ? ScrollBar.vertical.width + 4 : 0
                clip: true

                Column {
                    id: viewportColumn
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
                contentHeight: generalColumn.implicitHeight
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                rightPadding: ScrollBar.vertical.visible ? ScrollBar.vertical.width + 4 : 0
                clip: true

                Column {
                    id: generalColumn
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
