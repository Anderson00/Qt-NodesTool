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

                    // ── Save current theme as preset ──────────────────────────
                    RowLayout {
                        width: parent.width
                        height: 38
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            height: 34
                            radius: 6
                            color: ThemeManager.foregroundColor
                            border.width: 1
                            border.color: presetNameInput.activeFocus
                                          ? ThemeManager.primaryColor
                                          : ThemeManager.borderColor
                            Behavior on border.color { ColorAnimation { duration: 120 } }

                            TextInput {
                                id: presetNameInput
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter
                                color: ThemeManager.textColor
                                selectionColor: ThemeManager.selectionColor
                                font.pixelSize: 12
                                clip: true

                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: "Name for new preset…"
                                    color: ThemeManager.textSecondaryColor
                                    font.pixelSize: 12
                                    visible: presetNameInput.text.length === 0 && !presetNameInput.activeFocus
                                }

                                Keys.onReturnPressed: savePresetBtn.doSave()
                                Keys.onEnterPressed:  savePresetBtn.doSave()
                            }
                        }

                        Rectangle {
                            id: savePresetBtn
                            width: 110; height: 34
                            radius: 6
                            color: ThemeManager.primaryColor
                            opacity: presetNameInput.text.trim().length > 0
                                     ? (savePresetMa.containsMouse ? 0.85 : 1.0)
                                     : 0.35
                            Behavior on opacity { NumberAnimation { duration: 120 } }

                            function doSave() {
                                const n = presetNameInput.text.trim()
                                if (n.length === 0) return
                                PresetManager.saveCurrentAsPreset(n)
                                presetNameInput.text = ""
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "Save Current"
                                font.pixelSize: 11
                                font.bold: true
                                color: ThemeManager.backgroundColor
                            }

                            MouseArea {
                                id: savePresetMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: presetNameInput.text.trim().length > 0
                                             ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                                onClicked: savePresetBtn.doSave()
                            }
                        }
                    }

                    Item { height: 10; width: 1 }

                    // ── Preset cards ──────────────────────────────────────────
                    Flow {
                        width: parent.width
                        spacing: 10
                        bottomPadding: 4

                        Repeater {
                            model: PresetManager.presets

                            delegate: Rectangle {
                                id: presetCard

                                property var preset: modelData

                                width: 163
                                height: 94
                                radius: 9
                                color: preset.backgroundColor
                                clip: true

                                scale: bodyMa.containsMouse ? 1.04 : 1.0
                                Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutQuad } }

                                border.width: bodyMa.containsMouse ? 2 : 1
                                border.color: bodyMa.containsMouse
                                              ? preset.primaryColor
                                              : Qt.rgba(preset.borderColor.r,
                                                        preset.borderColor.g,
                                                        preset.borderColor.b, 0.6)
                                Behavior on border.width { NumberAnimation { duration: 130 } }

                                // ── 6-color strip ─────────────────────────────
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

                                // ── surface accent bar ────────────────────────
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: colorStrip.bottom
                                    anchors.bottom: footerBar.top
                                    width: 4
                                    color: preset.surfaceColor
                                    opacity: 0.5
                                }

                                // ── click area (behind delete button) ─────────
                                MouseArea {
                                    id: bodyMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: PresetManager.applyPreset(index)
                                }

                                // ── footer bar ────────────────────────────────
                                Rectangle {
                                    id: footerBar
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 26
                                    color: Qt.rgba(0, 0, 0, 0.30)

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 4

                                        // "custom" badge
                                        Rectangle {
                                            visible: !preset.builtin
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 38; height: 14; radius: 7
                                            color: Qt.rgba(preset.primaryColor.r,
                                                           preset.primaryColor.g,
                                                           preset.primaryColor.b, 0.35)
                                            Text {
                                                anchors.centerIn: parent
                                                text: "custom"
                                                font.pixelSize: 8
                                                color: preset.primaryColor
                                            }
                                        }

                                        Text {
                                            width: footerBar.width
                                                   - (preset.builtin ? 0 : 46)
                                                   - 8 - deleteBtn.width - 4
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: preset.name
                                            font.pixelSize: 10
                                            font.bold: true
                                            color: preset.textColor
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                // ── delete button (custom only, on top) ───────
                                Rectangle {
                                    id: deleteBtn
                                    visible: !preset.builtin
                                    anchors.top: colorStrip.bottom
                                    anchors.right: parent.right
                                    anchors.topMargin: 5
                                    anchors.rightMargin: 6
                                    width: 18; height: 18; radius: 9
                                    z: 10
                                    color: deleteMa.containsMouse
                                           ? ThemeManager.dangerColor
                                           : Qt.rgba(ThemeManager.dangerColor.r,
                                                     ThemeManager.dangerColor.g,
                                                     ThemeManager.dangerColor.b, 0.55)
                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "×"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: "white"
                                    }

                                    MouseArea {
                                        id: deleteMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: PresetManager.removePreset(preset.id)
                                    }
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

                    // ── DISPLAY ─────────────────────────────────────────────────
                    SectionLabel { text: "DISPLAY" }

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
                            onToggled: {
                                viewPort.setShowFps(fpsSwitch.checked)
                                GlobalProperties.showFps = fpsSwitch.checked
                            }
                        }
                    }

                    Item { width: 1; height: 8 }
                    Rectangle { width: parent.width; height: 1; color: ThemeManager.borderColor; opacity: 0.3 }

                    // ── GRID PATTERN ─────────────────────────────────────────────
                    SectionLabel { text: "GRID PATTERN" }

                    readonly property var _gridPatterns: [
                        { id: "dots",    label: "Dots",    icon: Qaterial.Icons.dotsGrid },
                        { id: "lines",   label: "Lines",   icon: Qaterial.Icons.viewSequential },
                        { id: "circles", label: "Circles", icon: Qaterial.Icons.circleOutline },
                        { id: "cross",   label: "Cross",   icon: Qaterial.Icons.plus },
                        { id: "x",       label: "X",       icon: Qaterial.Icons.close },
                        { id: "hexagon", label: "Hexagon", icon: Qaterial.Icons.hexagonOutline },
                        { id: "none",    label: "None",    icon: Qaterial.Icons.eyeOffOutline }
                    ]

                    Flow {
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: viewportColumn._gridPatterns

                            delegate: Rectangle {
                                readonly property bool active: GlobalProperties.gridPattern === modelData.id
                                width: 82; height: 68; radius: 8
                                color: active
                                    ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.15)
                                    : ThemeManager.foregroundColor
                                border.width: active ? 2 : 1
                                border.color: active ? ThemeManager.primaryColor : ThemeManager.borderColor
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 6

                                    Qaterial.ColorIcon {
                                        source: modelData.icon
                                        color: active ? ThemeManager.primaryColor : ThemeManager.textSecondaryColor
                                        width: 20; height: 20
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    Text {
                                        text: modelData.label
                                        font.pixelSize: 10
                                        color: active ? ThemeManager.primaryColor : ThemeManager.textSecondaryColor
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: GlobalProperties.gridPattern = modelData.id
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 16 }
                    Rectangle { width: parent.width; height: 1; color: ThemeManager.borderColor; opacity: 0.3 }

                    // ── GRID SIZE ─────────────────────────────────────────────────
                    SectionLabel { text: "GRID SIZE" }

                    readonly property var _gridSizes: [
                        { id: "compact",     label: "Compact",     value: 10 },
                        { id: "normal",      label: "Normal",      value: 20 },
                        { id: "comfortable", label: "Comfortable", value: 40 },
                        { id: "spacious",    label: "Spacious",    value: 60 }
                    ]

                    Flow {
                        width: parent.width
                        spacing: 8
                        bottomPadding: 8

                        Repeater {
                            model: viewportColumn._gridSizes

                            delegate: Rectangle {
                                readonly property bool active: GlobalProperties.gridPreset === modelData.id
                                width: 100; height: 44; radius: 7
                                color: active
                                    ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.15)
                                    : ThemeManager.foregroundColor
                                border.width: active ? 2 : 1
                                border.color: active ? ThemeManager.primaryColor : ThemeManager.borderColor
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Text {
                                        text: modelData.label
                                        font.pixelSize: 11
                                        font.bold: active
                                        color: active ? ThemeManager.primaryColor : ThemeManager.textColor
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    Text {
                                        text: modelData.value + "px"
                                        font.pixelSize: 9
                                        color: ThemeManager.textSecondaryColor
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: GlobalProperties.gridPreset = modelData.id
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 20 }
                    Rectangle { width: parent.width; height: 1; color: ThemeManager.borderColor; opacity: 0.3 }

                    // ── NODES LIST ──────────────────────────────────────────────────
                    SectionLabel { text: "NODES LIST" }

                    readonly property var _nodesListPositions: [
                        { id: "top-left",      label: "Top Left" },
                        { id: "top-center",    label: "Top Center" },
                        { id: "top-right",     label: "Top Right" },
                        { id: "mid-left",      label: "Mid Left" },
                        { id: "mid-right",     label: "Mid Right" },
                        { id: "bottom-left",   label: "Bottom Left" },
                        { id: "bottom-center", label: "Bottom Center" },
                        { id: "bottom-right",  label: "Bottom Right" }
                    ]

                    Flow {
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: viewportColumn._nodesListPositions

                            delegate: Rectangle {
                                readonly property bool active: GlobalProperties.nodesListPosition === modelData.id
                                width: (parent.width - 16) / 3; height: 60; radius: 7
                                color: active
                                    ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.15)
                                    : ThemeManager.foregroundColor
                                border.width: active ? 2 : 1
                                border.color: active ? ThemeManager.primaryColor : ThemeManager.borderColor
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 4

                                    // Position visualization
                                    Rectangle {
                                        width: parent.width
                                        height: 28
                                        radius: 3
                                        color: Qt.rgba(ThemeManager.primaryColor.r,
                                                       ThemeManager.primaryColor.g,
                                                       ThemeManager.primaryColor.b, 0.1)
                                        border.width: 1
                                        border.color: ThemeManager.primaryColor
                                        opacity: 0.6
                                        clip: true

                                        Rectangle {
                                            id: positionMarker
                                            width: 6
                                            height: 6
                                            radius: 3
                                            color: ThemeManager.primaryColor

                                            function updatePosition() {
                                                const id = modelData.id
                                                const w = parent.width
                                                const h = parent.height
                                                const cx = Math.max(2, Math.min(w - 8, w / 2 - 3))
                                                const cy = Math.max(2, Math.min(h - 8, h / 2 - 3))

                                                if (id === "top-left") { x = 2; y = 2 }
                                                else if (id === "top-center") { x = cx; y = 2 }
                                                else if (id === "top-right") { x = Math.max(2, w - 8); y = 2 }
                                                else if (id === "mid-left") { x = 2; y = cy }
                                                else if (id === "mid-right") { x = Math.max(2, w - 8); y = cy }
                                                else if (id === "bottom-left") { x = 2; y = Math.max(2, h - 8) }
                                                else if (id === "bottom-center") { x = cx; y = Math.max(2, h - 8) }
                                                else if (id === "bottom-right") { x = Math.max(2, w - 8); y = Math.max(2, h - 8) }
                                            }

                                            Component.onCompleted: updatePosition()
                                        }
                                    }

                                    Text {
                                        text: modelData.label
                                        font.pixelSize: 10
                                        font.bold: active
                                        color: active ? ThemeManager.primaryColor : ThemeManager.textColor
                                        Layout.alignment: Qt.AlignHCenter
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: GlobalProperties.nodesListPosition = modelData.id
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 20 }
                    Rectangle { width: parent.width; height: 1; color: ThemeManager.borderColor; opacity: 0.3 }

                    // ── NODES CONNECTIONS ───────────────────────────────────────────
                    SectionLabel { text: "NODE CONNECTIONS STYLE" }

                    readonly property var _connectionStyles: [
                        { id: "pills", label: "Pills", desc: "Modern wrapped tags" },
                        { id: "list",  label: "List",  desc: "Classic vertical list" }
                    ]

                    Flow {
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: viewportColumn._connectionStyles

                            delegate: Rectangle {
                                readonly property bool active: GlobalProperties.connectionStyle === modelData.id
                                width: (parent.width - 8) / 2; height: 60; radius: 7
                                color: active
                                    ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.15)
                                    : ThemeManager.foregroundColor
                                border.width: active ? 2 : 1
                                border.color: active ? ThemeManager.primaryColor : ThemeManager.borderColor
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        text: modelData.label
                                        font.pixelSize: 12
                                        font.bold: active
                                        color: active ? ThemeManager.primaryColor : ThemeManager.textColor
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        Behavior on color { ColorAnimation { duration: 120 } }
                                    }

                                    Text {
                                        text: modelData.desc
                                        font.pixelSize: 9
                                        color: ThemeManager.textSecondaryColor
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: GlobalProperties.connectionStyle = modelData.id
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 20 }
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
