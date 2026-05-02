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

    width: 740
    height: 540

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

    // ── Color presets ──────────────────────────────────────────────────────────
    readonly property var colorPresets: [
        { name: "Valkyrie Dark",
          bg:"#0D1117", surface:"#161B22", fg:"#1E2530", border:"#30363D", shadow:"#780D1117",
          primary:"#7C6AF7", secondary:"#A78BFA", accent:"#22D3EE",
          success:"#34D399", warning:"#FBBF24", danger:"#F87171",
          text:"#E6EDF3", textSec:"#8B949E", selection:"#337C6AF7" },

        { name: "Valkyrie Light",
          bg:"#F0F2F5", surface:"#FFFFFF", fg:"#E4E8EF", border:"#CBD5E1", shadow:"#190D1117",
          primary:"#5B6AF0", secondary:"#8B5CF6", accent:"#06B6D4",
          success:"#10B981", warning:"#F59E0B", danger:"#EF4444",
          text:"#1A1A2E", textSec:"#64748B", selection:"#335B6AF0" },

        { name: "Dracula",
          bg:"#282A36", surface:"#21222C", fg:"#343746", border:"#6272A4", shadow:"#99000000",
          primary:"#BD93F9", secondary:"#FF79C6", accent:"#8BE9FD",
          success:"#50FA7B", warning:"#FFB86C", danger:"#FF5555",
          text:"#F8F8F2", textSec:"#6272A4", selection:"#33BD93F9" },

        { name: "Nord",
          bg:"#2E3440", surface:"#3B4252", fg:"#434C5E", border:"#4C566A", shadow:"#99000000",
          primary:"#88C0D0", secondary:"#81A1C1", accent:"#5E81AC",
          success:"#A3BE8C", warning:"#EBCB8B", danger:"#BF616A",
          text:"#ECEFF4", textSec:"#D8DEE9", selection:"#3388C0D0" },

        { name: "Cyberpunk",
          bg:"#0D0D0D", surface:"#1A1A1A", fg:"#141414", border:"#333333", shadow:"#CC000000",
          primary:"#FFE600", secondary:"#FF2D78", accent:"#00F5FF",
          success:"#00FF9C", warning:"#FF8C00", danger:"#FF2D78",
          text:"#FFFFFF", textSec:"#888888", selection:"#33FFE600" },

        { name: "Ocean",
          bg:"#0A1628", surface:"#112240", fg:"#1A3A5C", border:"#233554", shadow:"#AA000000",
          primary:"#64FFDA", secondary:"#7F5AF0", accent:"#38BDF8",
          success:"#2CB67D", warning:"#FFCF40", danger:"#FF6B6B",
          text:"#CCD6F6", textSec:"#8892B0", selection:"#3364FFDA" },

        { name: "Sunset",
          bg:"#1A1025", surface:"#241533", fg:"#2D1B42", border:"#3D2856", shadow:"#AA000000",
          primary:"#FF6B35", secondary:"#FF4D6D", accent:"#FFD166",
          success:"#06D6A0", warning:"#FFD166", danger:"#EF233C",
          text:"#F8EDEB", textSec:"#B8B5B9", selection:"#33FF6B35" },

        { name: "Forest",
          bg:"#1A2318", surface:"#1E2B1C", fg:"#243322", border:"#344A31", shadow:"#AA000000",
          primary:"#4CAF50", secondary:"#8BC34A", accent:"#00BCD4",
          success:"#4CAF50", warning:"#FFC107", danger:"#F44336",
          text:"#E8F5E9", textSec:"#A5C8A0", selection:"#334CAF50" },

        { name: "Rose Pinheiro",
          bg:"#191724", surface:"#1F1D2E", fg:"#26233A", border:"#403D52", shadow:"#AA000000",
          primary:"#EBBCBA", secondary:"#C4A7E7", accent:"#9CCFD8",
          success:"#31748F", warning:"#F6C177", danger:"#EB6F92",
          text:"#E0DEF4", textSec:"#908CAA", selection:"#33EBBCBA" }
    ]

    function applyPreset(p) {
        ThemeManager.backgroundColor    = p.bg
        ThemeManager.surfaceColor       = p.surface
        ThemeManager.foregroundColor    = p.fg
        ThemeManager.borderColor        = p.border
        ThemeManager.shadowColor        = p.shadow
        ThemeManager.primaryColor       = p.primary
        ThemeManager.secondaryColor     = p.secondary
        ThemeManager.accentColor        = p.accent
        ThemeManager.successColor       = p.success
        ThemeManager.warningColor       = p.warning
        ThemeManager.dangerColor        = p.danger
        ThemeManager.textColor          = p.text
        ThemeManager.textSecondaryColor = p.textSec
        ThemeManager.selectionColor     = p.selection
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
                        spacing: 8
                        bottomPadding: 4

                        Repeater {
                            model: root.colorPresets

                            delegate: Rectangle {
                                id: presetCard
                                width: 138
                                height: 76
                                radius: 8
                                color: modelData.bg
                                border.width: presetMa.containsMouse ? 2 : 1
                                border.color: presetMa.containsMouse
                                              ? modelData.primary
                                              : Qt.rgba(
                                                    Qt.color(modelData.border).r,
                                                    Qt.color(modelData.border).g,
                                                    Qt.color(modelData.border).b, 0.7)
                                clip: true

                                Behavior on border.width { NumberAnimation { duration: 100 } }

                                // ── top color strip ──
                                Row {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 6

                                    Repeater {
                                        model: [modelData.primary, modelData.secondary,
                                                modelData.accent,  modelData.success,
                                                modelData.warning, modelData.danger]
                                        Rectangle {
                                            width: presetCard.width / 6
                                            height: 6
                                            color: modelData
                                        }
                                    }
                                }

                                // ── bg/surface mini preview ──
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.bottom: parent.bottom
                                    anchors.top: parent.top
                                    anchors.topMargin: 6
                                    width: 20
                                    color: modelData.surface
                                    opacity: 0.6
                                }

                                // ── name ──
                                Text {
                                    anchors.centerIn: parent
                                    anchors.horizontalCenterOffset: 10
                                    text: modelData.name
                                    font.pixelSize: 11
                                    font.bold: presetMa.containsMouse
                                    color: modelData.text
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                MouseArea {
                                    id: presetMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.applyPreset(modelData)
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
