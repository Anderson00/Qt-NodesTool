import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import App.Theme 1.0
import '../../components'

Item {
    id: root
    anchors.fill: parent

    property var behaviourObject
    property bool allOpened: true

    // ------- Tile container for a variant -------
    component Tile: Rectangle {
        id: tile
        property string label: ""
        default property alias content: holder.data
        width: 240
        height: 110
        radius: 8
        color: Qt.rgba(1, 1, 1, 0.04)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        Text {
            id: labelText
            visible: tile.label !== ""
            text: tile.label
            color: Qt.rgba(1, 1, 1, 0.55)
            font.pixelSize: 11
            font.bold: true
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 10
        }
        Item {
            id: holder
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.top: labelText.visible ? labelText.bottom : parent.top
            anchors.margins: 10
            anchors.topMargin: labelText.visible ? 6 : 10
        }
    }

    // ------- Section wrapper around Accordion -------
    component Section: Accordion {
        id: sec
        property int contentHeight: 200
        opened: root.allOpened
        loaderHeight: contentHeight
        width: parent ? parent.width : 0

        // Re-sync with global allOpened even after the user toggled this
        // section individually (which would otherwise break the binding).
        Connections {
            target: root
            function onAllOpenedChanged() { sec.opened = root.allOpened }
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        anchors.margins: 8
        clip: true
        contentWidth: width
        contentHeight: contentColumn.height + 16
        boundsBehavior: Flickable.StopAtBounds

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
            id: contentColumn
            width: flick.width - 16
            spacing: 10

            // ===================== HEADER =====================
            Row {
                width: parent.width
                spacing: 12
                bottomPadding: 8

                Column {
                    width: parent.width - toggleAllBtn.width - parent.spacing
                    spacing: 4
                    Text {
                        text: qsTr("Component Showcase")
                        color: ThemeManager.textColor
                        font.pixelSize: 22
                        font.bold: true
                    }
                    Text {
                        text: qsTr("All built-in UI components and their variants")
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.pixelSize: 12
                    }
                }

                NewButton {
                    id: toggleAllBtn
                    anchors.verticalCenter: parent.verticalCenter
                    variant: "outlined"
                    text: root.allOpened ? qsTr("Collapse all") : qsTr("Expand all")
                    leftPadding: 24
                    rightPadding: 24
                    implicitWidth: 160
                    implicitHeight: 36
                    onClicked: root.allOpened = !root.allOpened
                }
            }

            // ===================== BUTTONS =====================
            Section {
                title: qsTr("Buttons")
                contentHeight: 280
                loader: Component {
                    Item {
                        Flow {
                            id: buttonsFlow
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 12

                            Tile {
                                label: "Filled"
                                NewButton {
                                    anchors.centerIn: parent
                                    text: "Filled"; variant: "filled"
                                    iconSource: "qrc:/icons/play.svg"
                                }
                            }
                            Tile {
                                label: "Outlined"
                                NewButton {
                                    anchors.centerIn: parent
                                    text: "Outlined"; variant: "outlined"
                                    iconSource: "qrc:/icons/play.svg"
                                }
                            }
                            Tile {
                                label: "Text"
                                NewButton { anchors.centerIn: parent; text: "Text"; variant: "text" }
                            }
                            Tile {
                                label: "Rounded"
                                NewButton { anchors.centerIn: parent; text: "Rounded"; variant: "rounded" }
                            }
                            Tile {
                                label: "Danger"
                                NewButton {
                                    anchors.centerIn: parent
                                    text: "Delete"; variant: "filled"
                                    backgroundColor: ThemeManager.dangerColor
                                }
                            }
                            Tile {
                                label: "Icon only"
                                NewButton {
                                    anchors.centerIn: parent
                                    iconSource: "qrc:/icons/cog.svg"; variant: "rounded"
                                    implicitWidth: 40; implicitHeight: 40
                                }
                            }
                            Tile {
                                label: "Disabled"
                                NewButton { anchors.centerIn: parent; text: "Disabled"; enabled: false }
                            }
                            Tile {
                                label: "IconButton"
                                IconButton {
                                    anchors.centerIn: parent
                                    iconSource: "qrc:/icons/play.svg"
                                    width: 60; height: 60
                                }
                            }
                        }
                    }
                }
            }

            // ===================== SELECTION =====================
            Section {
                title: qsTr("Selection controls")
                contentHeight: 210
                loader: Component {
                    Item {
                        Flow {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 12

                            Tile {
                                label: "CheckBox"; height: 170
                                Column {
                                    anchors.fill: parent; spacing: 6
                                    CustomCheckBox { text: "Unchecked" }
                                    CustomCheckBox { text: "Checked"; checked: true }
                                    CustomCheckBox { text: "Tri-state"; tristate: true; checkState: Qt.PartiallyChecked }
                                }
                            }
                            Tile {
                                label: "RadioButton"; height: 170
                                Column {
                                    anchors.fill: parent; spacing: 6
                                    ButtonGroup { id: radioGroup }
                                    CustomRadioButton { text: "Option A"; ButtonGroup.group: radioGroup; checked: true }
                                    CustomRadioButton { text: "Option B"; ButtonGroup.group: radioGroup }
                                    CustomRadioButton { text: "Disabled"; enabled: false }
                                }
                            }
                            Tile {
                                label: "Switch"; height: 180
                                Column {
                                    anchors.fill: parent; spacing: 10
                                    CustomSwitch { text: "Off" }
                                    CustomSwitch { text: "On"; checked: true }
                                    CustomSwitch { text: "Disabled"; enabled: false; checked: true }
                                }
                            }
                        }
                    }
                }
            }

            // ===================== TEXT INPUTS =====================
            Section {
                title: qsTr("Text inputs")
                contentHeight: 300
                loader: Component {
                    Item {
                        Flow {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 12

                            Tile {
                                label: "CustomTextField"
                                CustomTextField {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    placeholderText: "Type something..."
                                }
                            }
                            Tile {
                                label: "PasswordField"
                                PasswordField {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    showStrength: true; text: "Abc123!"
                                }
                            }
                            Tile {
                                label: "NumberSpinBox"
                                NumberSpinBox {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    from: 0; to: 1000; value: 42; suffixText: "px"
                                }
                            }
                            Tile {
                                label: "TagInput"; width: 280; height: 160
                                TagInput {
                                    anchors.fill: parent
                                    tags: ["debug", "node", "cpu"]
                                }
                            }
                        }
                    }
                }
            }

            // ===================== SELECTORS =====================
            Section {
                title: qsTr("Selectors")
                contentHeight: 260
                loader: Component {
                    Item {
                        Flow {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 12

                            Tile {
                                label: "ComboBox"
                                CustomComboBox {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    model: ["x86", "x86_64", "ARM", "ARM64", "MIPS"]
                                }
                            }
                            Tile {
                                label: "SearchableSelect"
                                SearchableSelect {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    model: ["Apple", "Banana", "Cherry", "Date", "Elderberry",
                                            "Fig", "Grape", "Honeydew"]
                                }
                            }
                            Tile {
                                label: "DatePicker"
                                CustomDatePicker {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            Tile {
                                label: "ColorPicker"
                                ColorPicker {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    value: ThemeManager.primaryColor
                                    label: "Color:"
                                }
                            }
                        }
                    }
                }
            }

            // ===================== SLIDERS =====================
            Section {
                title: qsTr("Sliders")
                contentHeight: 240
                loader: Component {
                    Item {
                        Flow {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 12

                            Tile {
                                label: "CustomSlider"
                                CustomSlider {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    from: 0; to: 100; value: 35
                                }
                            }
                            Tile {
                                label: "CustomSliderVertical"; height: 220
                                CustomSliderVertical {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    from: 0; to: 100; value: 60
                                }
                            }
                        }
                    }
                }
            }

            // ===================== FILE DROP =====================
            Section {
                title: qsTr("File upload")
                contentHeight: 160
                loader: Component {
                    Item {
                        FileDropZone {
                            anchors.fill: parent
                            anchors.margins: 8
                            title: qsTr("Drop files to import")
                        }
                    }
                }
            }

            // ===================== ICONS =====================
            Section {
                title: qsTr("SvgIcon")
                contentHeight: 120
                loader: Component {
                    Item {
                        Flow {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 12
                            Repeater {
                                model: [
                                    { src: "qrc:/icons/play.svg",        c: "#2ecc71" },
                                    { src: "qrc:/icons/pause.svg",       c: "#f1c40f" },
                                    { src: "qrc:/icons/stop.svg",        c: "#e74c3c" },
                                    { src: "qrc:/icons/cog.svg",         c: ThemeManager.primaryColor },
                                    { src: "qrc:/icons/information.svg", c: "#3498db" },
                                    { src: "qrc:/icons/chart-line.svg",  c: ThemeManager.accentColor }
                                ]
                                Tile {
                                    width: 90; height: 90
                                    SvgIcon {
                                        anchors.centerIn: parent
                                        width: 32; height: 32
                                        source: modelData.src
                                        color: modelData.c
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ===================== NEW INPUTS =====================
            Section {
                title: qsTr("New Inputs")
                contentHeight: 440
                loader: Component {
                    Item {
                        Flow {
                            anchors.fill: parent; anchors.margins: 8; spacing: 12

                            Tile {
                                label: "RangeSlider"; width: 280
                                RangeSlider {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    from: 0; to: 100; firstValue: 20; secondValue: 75
                                    showLabels: true; showValues: true
                                }
                            }
                            Tile {
                                label: "SegmentedControl"; width: 300
                                SegmentedControl {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    model: ["Day", "Week", "Month", "Year"]
                                }
                            }
                            Tile {
                                label: "MultiSelect"; width: 280; height: 140
                                MultiSelect {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    model: ["Alpha", "Beta", "Gamma", "Delta", "Epsilon"]
                                    selected: ["Alpha", "Gamma"]
                                    placeholder: "Choose items…"
                                }
                            }
                            Tile {
                                label: "OTPInput"; width: 300
                                OTPInput {
                                    anchors.centerIn: parent
                                    digits: 6; numbersOnly: true
                                }
                            }
                            Tile {
                                label: "TimePicker"; width: 260; height: 200
                                TimePicker {
                                    anchors.centerIn: parent
                                    hours: 14; minutes: 30; seconds: 0; showSeconds: true
                                }
                            }
                            Tile {
                                label: "AutocompleteInput"; width: 280; height: 140
                                AutocompleteInput {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.top: parent.top
                                    suggestions: ["Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape"]
                                    placeholder: "Type a fruit…"
                                }
                            }
                        }
                    }
                }
            }

            // ===================== DISPLAY & FEEDBACK =====================
            Section {
                title: qsTr("Display & Feedback")
                contentHeight: 520
                loader: Component {
                    Item {
                        Flow {
                            anchors.fill: parent; anchors.margins: 8; spacing: 12

                            Tile {
                                label: "Badge"; width: 200; height: 130
                                Row {
                                    anchors.centerIn: parent; spacing: 14
                                    Badge { count: 3 }
                                    Badge { count: 99; max: 50; badgeColor: ThemeManager.warningColor }
                                    Badge { count: -1 }
                                }
                            }
                            Tile {
                                label: "Chip"; width: 260; height: 130
                                Flow {
                                    anchors.fill: parent; spacing: 8
                                    Chip { label: "Debug"; closeable: true }
                                    Chip { label: "Active"; selectable: true; selected: true }
                                    Chip { label: "CPU"; chipColor: Qt.rgba(ThemeManager.accentColor.r, ThemeManager.accentColor.g, ThemeManager.accentColor.b, 0.18) }
                                }
                            }
                            Tile {
                                label: "Avatar"; width: 260; height: 130
                                Row {
                                    anchors.centerIn: parent; spacing: 12
                                    Avatar { name: "Alice"; size: 44; showStatus: true; status: "online" }
                                    Avatar { name: "Bob"; size: 44; showStatus: true; status: "away" }
                                    Avatar { name: "Carol"; size: 44; showStatus: true; status: "busy" }
                                    Avatar { size: 44; showStatus: true; status: "offline" }
                                }
                            }
                            Tile {
                                label: "ProgressCircle"; width: 200; height: 160
                                Row {
                                    anchors.centerIn: parent; spacing: 16
                                    ProgressCircle { value: 0.72; size: 64; showLabel: true; label: "72%" }
                                    ProgressCircle { value: 0.35; size: 48; strokeWidth: 4; progressColor: ThemeManager.warningColor; showLabel: true; label: "35%" }
                                }
                            }
                            Tile {
                                label: "Skeleton"; width: 240; height: 150
                                Column {
                                    anchors.fill: parent; spacing: 8
                                    Skeleton { width: parent.width; height: 14; shape: "text" }
                                    Skeleton { width: parent.width * 0.8; height: 14; shape: "text" }
                                    Skeleton { width: parent.width; height: 14; shape: "text" }
                                    Row { spacing: 10; Skeleton { width: 36; height: 36; shape: "circle" }
                                    Skeleton { width: 140; height: 36 } }
                                }
                            }
                            Tile {
                                label: "StatusDot"; width: 200; height: 160
                                Column {
                                    anchors.fill: parent; spacing: 8
                                    StatusDot { status: "online";  showLabel: true; showPulse: true }
                                    StatusDot { status: "away";    showLabel: true }
                                    StatusDot { status: "busy";    showLabel: true }
                                    StatusDot { status: "offline"; showLabel: true }
                                }
                            }
                            Tile {
                                label: "Timeline"; width: 280; height: 220
                                Timeline {
                                    anchors.fill: parent
                                    events: [
                                        { title: "Build started",   subtitle: "10:02 AM", color: ThemeManager.primaryColor },
                                        { title: "Tests passed",    subtitle: "10:04 AM", color: ThemeManager.successColor },
                                        { title: "Deploy queued",   subtitle: "10:05 AM" }
                                    ]
                                }
                            }
                            Tile {
                                label: "EmptyState"; width: 260; height: 200
                                EmptyState {
                                    anchors.fill: parent
                                    icon: "📭"
                                    title: "No results"
                                    subtitle: "Try adjusting your search"
                                    actionLabel: "Clear filters"
                                }
                            }
                        }
                    }
                }
            }

            // ===================== DATA & LISTS =====================
            Section {
                title: qsTr("Data & Lists")
                contentHeight: 500
                loader: Component {
                    Item {
                        Column {
                            anchors.fill: parent; anchors.margins: 8; spacing: 16

                            Text {
                                text: "DataTable (sortable — click headers)"
                                color: ThemeManager.textSecondaryColor; font.pixelSize: 11
                            }
                            DataTable {
                                width: parent.width; height: 200
                                columns: [
                                    { key: "name",   label: "Name",   width: 140 },
                                    { key: "type",   label: "Type",   width: 100 },
                                    { key: "size",   label: "Size",   width: 80  },
                                    { key: "status", label: "Status", width: 100 }
                                ]
                                rows: [
                                    { name: "kernel32.dll",   type: "DLL",  size: "1.2 MB", status: "Loaded" },
                                    { name: "ntdll.dll",      type: "DLL",  size: "2.4 MB", status: "Loaded" },
                                    { name: "user32.dll",     type: "DLL",  size: "0.8 MB", status: "Loaded" },
                                    { name: "debug_agent",    type: "EXE",  size: "4.1 MB", status: "Running" },
                                    { name: "libssl.so",      type: "SO",   size: "0.5 MB", status: "Unloaded" }
                                ]
                            }

                            Text {
                                text: "Pagination"
                                color: ThemeManager.textSecondaryColor; font.pixelSize: 11
                            }
                            Pagination {
                                currentPage: 3; totalPages: 15
                                onPageChanged: function(p) { console.log("Page:", p) }
                            }
                        }
                    }
                }
            }

            // ===================== OVERLAYS & MODALS =====================
            Section {
                title: qsTr("Overlays & Modals")
                contentHeight: 200
                loader: Component {
                    Item {
                        property var _snack: snackRef
                        property var _alert: alertRef
                        property var _palette: paletteRef
                        property var _ctx: ctxRef

                        AlertDialog {
                            id: alertRef
                            title: "Delete node?"
                            message: "This action will remove the node and all its connections. This cannot be undone."
                            type: "danger"; confirmLabel: "Delete"
                            onConfirmed: console.log("Confirmed deletion")
                        }

                        Snackbar { id: snackRef }

                        CommandPalette {
                            id: paletteRef
                            commands: [
                                { label: "Add CPU Node",      shortcut: "Ctrl+1" },
                                { label: "Toggle Dark Mode",  shortcut: "Ctrl+D" },
                                { label: "Save Workspace",    shortcut: "Ctrl+S" },
                                { label: "Open Settings",     shortcut: "Ctrl+," },
                                { label: "Run All Nodes",     shortcut: "F5"     }
                            ]
                            onCommandSelected: function(cmd) { console.log("Cmd:", cmd.label) }
                        }

                        ContextMenu {
                            id: ctxRef
                            items: [
                                { label: "Copy",       icon: "⎘", shortcut: "Ctrl+C" },
                                { label: "Paste",      icon: "⌗", shortcut: "Ctrl+V" },
                                { separator: true },
                                { label: "Delete",     icon: "✕", danger: true }
                            ]
                            onItemSelected: function(i, item) { console.log("Ctx:", item.label) }
                        }

                        Flow {
                            anchors.fill: parent; anchors.margins: 8; spacing: 12

                            NewButton {
                                text: "AlertDialog"; variant: "outlined"
                                onClicked: alertRef.open()
                            }
                            NewButton {
                                text: "Snackbar (success)"; variant: "outlined"
                                onClicked: snackRef.show("Workspace saved!", "Undo", "success")
                            }
                            NewButton {
                                text: "Snackbar (danger)"; variant: "outlined"
                                onClicked: snackRef.show("Build failed.", "", "danger")
                            }
                            NewButton {
                                text: "CommandPalette"; variant: "outlined"
                                onClicked: paletteRef.open()
                            }
                            NewButton {
                                text: "ContextMenu"; variant: "outlined"
                                onClicked: ctxRef.openAt(x, y + height + 4)
                            }
                        }
                    }
                }
            }

            // ===================== NAVIGATION =====================
            Section {
                title: qsTr("Navigation")
                contentHeight: 380
                loader: Component {
                    Item {
                        Column {
                            anchors.fill: parent; anchors.margins: 8; spacing: 20

                            Text { text: "TabBar"; color: ThemeManager.textSecondaryColor; font.pixelSize: 11 }
                            TabBar {
                                width: parent.width; tabHeight: 44
                                tabs: [
                                    { label: "Overview",  icon: "⬡" },
                                    { label: "Nodes",     icon: "◈" },
                                    { label: "Network",   icon: "⇄" },
                                    { label: "Settings",  icon: "⚙" }
                                ]
                            }

                            Text { text: "Stepper (horizontal)"; color: ThemeManager.textSecondaryColor; font.pixelSize: 11 }
                            Stepper {
                                width: parent.width; height: 60
                                steps: ["Connect", "Configure", "Deploy", "Monitor"]
                                currentStep: 2
                            }

                            Text { text: "BreadcrumbBar"; color: ThemeManager.textSecondaryColor; font.pixelSize: 11 }
                            BreadcrumbBar {
                                items: [
                                    { label: "Workspace" },
                                    { label: "Projects"  },
                                    { label: "Valkyrie"  },
                                    { label: "Nodes"     }
                                ]
                                onItemClicked: function(i, item) { console.log("Breadcrumb:", item.label) }
                            }
                        }
                    }
                }
            }

            // ===================== UTILITIES =====================
            Section {
                title: qsTr("Utilities")
                contentHeight: 460
                loader: Component {
                    Item {
                        Flow {
                            anchors.fill: parent; anchors.margins: 8; spacing: 12

                            Tile {
                                label: "Divider — labeled"; width: 280
                                Divider {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    label: "OR"
                                }
                            }
                            Tile {
                                label: "Divider — plain"; width: 200
                                Divider { anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
                            }

                            Tile {
                                label: "LoadingSpinner"; width: 200; height: 130
                                Row {
                                    anchors.centerIn: parent; spacing: 20
                                    LoadingSpinner { size: 20 }
                                    LoadingSpinner { size: 32; color: ThemeManager.accentColor }
                                    LoadingSpinner { size: 48; thickness: 5; color: ThemeManager.successColor }
                                }
                            }

                            Tile {
                                label: "SplitPane"; width: 340; height: 160
                                SplitPane {
                                    anchors.fill: parent
                                    orientation: Qt.Horizontal
                                    initialSplit: 0.4
                                    firstPanel: Component {
                                        Rectangle { color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.12)
                                            Text { anchors.centerIn: parent; text: "Left"; color: ThemeManager.textColor; font.pixelSize: 12 }
                                        }
                                    }
                                    secondPanel: Component {
                                        Rectangle { color: Qt.rgba(ThemeManager.accentColor.r, ThemeManager.accentColor.g, ThemeManager.accentColor.b, 0.12)
                                            Text { anchors.centerIn: parent; text: "Right"; color: ThemeManager.textColor; font.pixelSize: 12 }
                                        }
                                    }
                                }
                            }

                            Tile {
                                label: "CodeBlock"; width: 380; height: 200
                                CodeBlock {
                                    anchors.fill: parent
                                    language: "cpp"
                                    showCopyButton: true
                                    code: '#include <QApplication>\n#include "MainWindow.h"\n\nint main(int argc, char *argv[]) {\n    QApplication app(argc, argv);\n    MainWindow w;\n    w.show();\n    return app.exec();\n}'
                                }
                            }

                            Tile {
                                label: "Kbd — shortcuts"; width: 300; height: 140
                                Column {
                                    anchors.fill: parent; spacing: 10
                                    Row { spacing: 12
                                        Text { text: "Save:";      color: ThemeManager.textSecondaryColor; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                        Kbd { keys: "Ctrl+S" }
                                    }
                                    Row { spacing: 12
                                        Text { text: "Palette:";   color: ThemeManager.textSecondaryColor; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                        Kbd { keys: "Ctrl+P" }
                                    }
                                    Row { spacing: 12
                                        Text { text: "Undo:";      color: ThemeManager.textSecondaryColor; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                        Kbd { keys: "Ctrl+Z" }
                                    }
                                    Row { spacing: 12
                                        Text { text: "Run all:";   color: ThemeManager.textSecondaryColor; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                        Kbd { keys: ["F5"] }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // bottom padding
            Item { width: parent.width; height: 12 }
        }
    }
}
