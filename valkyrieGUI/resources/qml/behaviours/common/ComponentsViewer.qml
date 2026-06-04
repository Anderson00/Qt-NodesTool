import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import App.Theme 1.0
import App.Icons 1.0
import '../../components'

Item {
    id: root
    anchors.fill: parent

    property var behaviourObject
    property bool allOpened: true

    // Staggered async loading — one section activates every 80 ms so the UI
    // never blocks. Each Section's Loader is asynchronous; it shows a skeleton
    // shimmer while the component tree is being built.
    property int _loadIndex: -1
    Timer {
        id: _stagger
        interval: 80
        repeat: true
        running: true
        onTriggered: {
            root._loadIndex++
            if (root._loadIndex >= 12) stop()
        }
    }

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
        property int sectionIndex:  0
        opened: root.allOpened
        loaderActive: sectionIndex <= root._loadIndex
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
                sectionIndex: 0
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
                                label: qsTr("Filled")
                                NewButton {
                                    anchors.centerIn: parent
                                    text: qsTr("Filled"); variant: "filled"
                                    iconSource: Icons.play
                                }
                            }
                            Tile {
                                label: qsTr("Outlined")
                                NewButton {
                                    anchors.centerIn: parent
                                    text: qsTr("Outlined"); variant: "outlined"
                                    iconSource: Icons.play
                                }
                            }
                            Tile {
                                label: qsTr("Text")
                                NewButton { anchors.centerIn: parent; text: qsTr("Text"); variant: "text" }
                            }
                            Tile {
                                label: qsTr("Rounded")
                                NewButton { anchors.centerIn: parent; text: qsTr("Rounded"); variant: "rounded" }
                            }
                            Tile {
                                label: qsTr("Danger")
                                NewButton {
                                    anchors.centerIn: parent
                                    text: qsTr("Delete"); variant: "filled"
                                    backgroundColor: ThemeManager.dangerColor
                                }
                            }
                            Tile {
                                label: qsTr("Icon only")
                                NewButton {
                                    anchors.centerIn: parent
                                    iconSource: Icons.cog; variant: "rounded"
                                    implicitWidth: 40; implicitHeight: 40
                                }
                            }
                            Tile {
                                label: qsTr("Disabled")
                                NewButton { anchors.centerIn: parent; text: qsTr("Disabled"); enabled: false }
                            }
                            Tile {
                                label: qsTr("IconButton")
                                IconButton {
                                    anchors.centerIn: parent
                                    iconSource: Icons.play
                                    width: 60; height: 60
                                }
                            }
                        }
                    }
                }
            }

            // ===================== SELECTION =====================
            Section {
                sectionIndex: 1
                title: qsTr("Selection controls")
                contentHeight: 210
                loader: Component {
                    Item {
                        Flow {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 12

                            Tile {
                                label: qsTr("CheckBox"); height: 170
                                Column {
                                    anchors.fill: parent; spacing: 6
                                    CustomCheckBox { text: qsTr("Unchecked") }
                                    CustomCheckBox { text: qsTr("Checked"); checked: true }
                                    CustomCheckBox { text: qsTr("Tri-state"); tristate: true; checkState: Qt.PartiallyChecked }
                                }
                            }
                            Tile {
                                label: qsTr("RadioButton"); height: 170
                                Column {
                                    anchors.fill: parent; spacing: 6
                                    ButtonGroup { id: radioGroup }
                                    CustomRadioButton { text: qsTr("Option A"); ButtonGroup.group: radioGroup; checked: true }
                                    CustomRadioButton { text: qsTr("Option B"); ButtonGroup.group: radioGroup }
                                    CustomRadioButton { text: qsTr("Disabled"); enabled: false }
                                }
                            }
                            Tile {
                                label: qsTr("Switch"); height: 180
                                Column {
                                    anchors.fill: parent; spacing: 10
                                    CustomSwitch { text: qsTr("Off") }
                                    CustomSwitch { text: qsTr("On"); checked: true }
                                    CustomSwitch { text: qsTr("Disabled"); enabled: false; checked: true }
                                }
                            }
                        }
                    }
                }
            }

            // ===================== TEXT INPUTS =====================
            Section {
                sectionIndex: 2
                title: qsTr("Text inputs")
                contentHeight: 300
                loader: Component {
                    Item {
                        Flow {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 12

                            Tile {
                                label: qsTr("CustomTextField")
                                CustomTextField {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    placeholderText: qsTr("Type something...")
                                }
                            }
                            Tile {
                                label: qsTr("PasswordField")
                                PasswordField {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    showStrength: true; text: qsTr("Abc123!")
                                }
                            }
                            Tile {
                                label: qsTr("NumberSpinBox")
                                NumberSpinBox {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    from: 0; to: 1000; value: 42; suffixText: "px"
                                }
                            }
                            Tile {
                                label: qsTr("TagInput"); width: 280; height: 160
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
                sectionIndex: 3
                title: qsTr("Selectors")
                contentHeight: 260
                loader: Component {
                    Item {
                        Flow {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 12

                            Tile {
                                label: qsTr("ComboBox")
                                CustomComboBox {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    model: ["x86", "x86_64", "ARM", "ARM64", "MIPS"]
                                }
                            }
                            Tile {
                                label: qsTr("SearchableSelect")
                                SearchableSelect {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    model: ["Apple", "Banana", "Cherry", "Date", "Elderberry",
                                            "Fig", "Grape", "Honeydew"]
                                }
                            }
                            Tile {
                                label: qsTr("DatePicker")
                                CustomDatePicker {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            Tile {
                                label: qsTr("ColorPicker")
                                ColorPicker {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    value: ThemeManager.primaryColor
                                    label: qsTr("Color:")
                                }
                            }
                        }
                    }
                }
            }

            // ===================== SLIDERS =====================
            Section {
                sectionIndex: 4
                title: qsTr("Sliders")
                contentHeight: 240
                loader: Component {
                    Item {
                        Flow {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 12

                            Tile {
                                label: qsTr("CustomSlider")
                                CustomSlider {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    from: 0; to: 100; value: 35
                                }
                            }
                            Tile {
                                label: qsTr("CustomSliderVertical"); height: 220
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
                sectionIndex: 5
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
                sectionIndex: 6
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
                                    { src: Icons.play,        c: "#2ecc71" },
                                    { src: Icons.pause,       c: "#f1c40f" },
                                    { src: Icons.stop,        c: "#e74c3c" },
                                    { src: Icons.cog,         c: ThemeManager.primaryColor },
                                    { src: Icons.information, c: "#3498db" },
                                    { src: Icons.chartLine,   c: ThemeManager.accentColor }
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
                sectionIndex: 7
                title: qsTr("New Inputs")
                contentHeight: 440
                loader: Component {
                    Item {
                        Flow {
                            anchors.fill: parent; anchors.margins: 8; spacing: 12

                            Tile {
                                label: qsTr("RangeSlider"); width: 280
                                RangeSlider {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    from: 0; to: 100; firstValue: 20; secondValue: 75
                                    showLabels: true; showValues: true
                                }
                            }
                            Tile {
                                label: qsTr("SegmentedControl"); width: 300
                                SegmentedControl {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    model: ["Day", "Week", "Month", "Year"]
                                }
                            }
                            Tile {
                                label: qsTr("MultiSelect"); width: 280; height: 140
                                MultiSelect {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    model: ["Alpha", "Beta", "Gamma", "Delta", "Epsilon"]
                                    selected: ["Alpha", "Gamma"]
                                    placeholder: qsTr("Choose items…")
                                }
                            }
                            Tile {
                                label: qsTr("OTPInput"); width: 300
                                OTPInput {
                                    anchors.centerIn: parent
                                    digits: 6; numbersOnly: true
                                }
                            }
                            Tile {
                                label: qsTr("TimePicker"); width: 260; height: 200
                                TimePicker {
                                    anchors.centerIn: parent
                                    hours: 14; minutes: 30; seconds: 0; showSeconds: true
                                }
                            }
                            Tile {
                                label: qsTr("AutocompleteInput"); width: 280; height: 140
                                AutocompleteInput {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.top: parent.top
                                    suggestions: ["Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape"]
                                    placeholder: qsTr("Type a fruit…")
                                }
                            }
                        }
                    }
                }
            }

            // ===================== DISPLAY & FEEDBACK =====================
            Section {
                sectionIndex: 8
                title: qsTr("Display & Feedback")
                contentHeight: 520
                loader: Component {
                    Item {
                        Flow {
                            anchors.fill: parent; anchors.margins: 8; spacing: 12

                            Tile {
                                label: qsTr("Badge"); width: 200; height: 130
                                Row {
                                    anchors.centerIn: parent; spacing: 14
                                    Badge { count: 3 }
                                    Badge { count: 99; max: 50; badgeColor: ThemeManager.warningColor }
                                    Badge { count: -1 }
                                }
                            }
                            Tile {
                                label: qsTr("Chip"); width: 260; height: 130
                                Flow {
                                    anchors.fill: parent; spacing: 8
                                    Chip { label: qsTr("Debug"); closeable: true }
                                    Chip { label: qsTr("Active"); selectable: true; selected: true }
                                    Chip { label: qsTr("CPU"); chipColor: Qt.rgba(ThemeManager.accentColor.r, ThemeManager.accentColor.g, ThemeManager.accentColor.b, 0.18) }
                                }
                            }
                            Tile {
                                label: qsTr("Avatar"); width: 260; height: 130
                                Row {
                                    anchors.centerIn: parent; spacing: 12
                                    Avatar { name: "Alice"; size: 44; showStatus: true; status: "online" }
                                    Avatar { name: "Bob"; size: 44; showStatus: true; status: "away" }
                                    Avatar { name: "Carol"; size: 44; showStatus: true; status: "busy" }
                                    Avatar { size: 44; showStatus: true; status: "offline" }
                                }
                            }
                            Tile {
                                label: qsTr("ProgressCircle"); width: 200; height: 160
                                Row {
                                    anchors.centerIn: parent; spacing: 16
                                    ProgressCircle { value: 0.72; size: 64; showLabel: true; label: qsTr("72%") }
                                    ProgressCircle { value: 0.35; size: 48; strokeWidth: 4; progressColor: ThemeManager.warningColor; showLabel: true; label: qsTr("35%") }
                                }
                            }
                            Tile {
                                label: qsTr("Skeleton"); width: 240; height: 150
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
                                label: qsTr("StatusDot"); width: 200; height: 160
                                Column {
                                    anchors.fill: parent; spacing: 8
                                    StatusDot { status: "online";  showLabel: true; showPulse: true }
                                    StatusDot { status: "away";    showLabel: true }
                                    StatusDot { status: "busy";    showLabel: true }
                                    StatusDot { status: "offline"; showLabel: true }
                                }
                            }
                            Tile {
                                label: qsTr("Timeline"); width: 280; height: 220
                                Timeline {
                                    anchors.fill: parent
                                    events: [
                                        { title: qsTr("Build started"),   subtitle: qsTr("10:02 AM"), color: ThemeManager.primaryColor },
                                        { title: qsTr("Tests passed"),    subtitle: qsTr("10:04 AM"), color: ThemeManager.successColor },
                                        { title: qsTr("Deploy queued"),   subtitle: qsTr("10:05 AM") }
                                    ]
                                }
                            }
                            Tile {
                                label: qsTr("EmptyState"); width: 260; height: 200
                                EmptyState {
                                    anchors.fill: parent
                                    icon: "📭"
                                    title: qsTr("No results")
                                    subtitle: qsTr("Try adjusting your search")
                                    actionLabel: "Clear filters"
                                }
                            }
                        }
                    }
                }
            }

            // ===================== DATA & LISTS =====================
            Section {
                sectionIndex: 9
                title: qsTr("Data & Lists")
                contentHeight: 500
                loader: Component {
                    Item {
                        Column {
                            anchors.fill: parent; anchors.margins: 8; spacing: 16

                            Text {
                                text: qsTr("DataTable (sortable — click headers)")
                                color: ThemeManager.textSecondaryColor; font.pixelSize: 11
                            }
                            DataTable {
                                width: parent.width; height: 200
                                columns: [
                                    { key: "name",   label: qsTr("Name"),   width: 140 },
                                    { key: "type",   label: qsTr("Type"),   width: 100 },
                                    { key: "size",   label: qsTr("Size"),   width: 80  },
                                    { key: "status", label: qsTr("Status"), width: 100 }
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
                                text: qsTr("Pagination")
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
                sectionIndex: 10
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
                            title: qsTr("Delete node?")
                            message: "This action will remove the node and all its connections. This cannot be undone."
                            type: "danger"; confirmLabel: "Delete"
                            onConfirmed: console.log("Confirmed deletion")
                        }

                        Snackbar { id: snackRef }

                        CommandPalette {
                            id: paletteRef
                            commands: [
                                { label: qsTr("Add CPU Node"),      shortcut: "Ctrl+1" },
                                { label: qsTr("Toggle Dark Mode"),  shortcut: "Ctrl+D" },
                                { label: qsTr("Save Workspace"),    shortcut: "Ctrl+S" },
                                { label: qsTr("Open Settings"),     shortcut: "Ctrl+," },
                                { label: qsTr("Run All Nodes"),     shortcut: "F5"     }
                            ]
                            onCommandSelected: function(cmd) { console.log("Cmd:", cmd.label) }
                        }

                        ContextMenu {
                            id: ctxRef
                            items: [
                                { label: qsTr("Copy"),       icon: "⎘", shortcut: "Ctrl+C" },
                                { label: qsTr("Paste"),      icon: "⌗", shortcut: "Ctrl+V" },
                                { separator: true },
                                { label: qsTr("Delete"),     icon: "✕", danger: true }
                            ]
                            onItemSelected: function(i, item) { console.log("Ctx:", item.label) }
                        }

                        Flow {
                            anchors.fill: parent; anchors.margins: 8; spacing: 10

                            NewButton {
                                text: qsTr("AlertDialog")
                                variant: "outlined"
                                Layout.preferredWidth: 200
                                leftPadding: 18; rightPadding: 18

                                onClicked: alertRef.open()
                            }
                            NewButton {
                                text: qsTr("Snackbar (success)")
                                variant: "outlined"
                                Layout.preferredWidth: 200
                                leftPadding: 18; rightPadding: 18
                                onClicked: snackRef.show("Workspace saved!", "Undo", "success")
                            }
                            NewButton {
                                text: qsTr("Snackbar (danger)")
                                variant: "outlined"
                                Layout.preferredWidth: 200
                                leftPadding: 18; rightPadding: 18
                                onClicked: snackRef.show("Build failed.", "", "danger")
                            }
                            NewButton {
                                text: qsTr("CommandPalette")
                                variant: "outlined"
                                Layout.preferredWidth: 200
                                leftPadding: 18; rightPadding: 18
                                onClicked: paletteRef.open()
                            }
                            NewButton {
                                text: qsTr("ContextMenu")
                                variant: "outlined"
                                Layout.preferredWidth: 200
                                leftPadding: 18; rightPadding: 18
                                onClicked: ctxRef.openAt(x, y + height + 4)
                            }
                        }
                    }
                }
            }

            // ===================== NAVIGATION =====================
            Section {
                sectionIndex: 11
                title: qsTr("Navigation")
                contentHeight: 380
                loader: Component {
                    Item {
                        Column {
                            anchors.fill: parent; anchors.margins: 8; spacing: 20

                            Text { text: qsTr("TabBar"); color: ThemeManager.textSecondaryColor; font.pixelSize: 11 }
                            TabBar {
                                width: parent.width; tabHeight: 44
                                tabs: [
                                    { label: qsTr("Overview"),  icon: "⬡" },
                                    { label: qsTr("Nodes"),     icon: "◈" },
                                    { label: qsTr("Network"),   icon: "⇄" },
                                    { label: qsTr("Settings"),  icon: "⚙" }
                                ]
                            }

                            Text { text: qsTr("Stepper (horizontal)"); color: ThemeManager.textSecondaryColor; font.pixelSize: 11 }
                            Stepper {
                                width: parent.width; height: 60
                                steps: ["Connect", "Configure", "Deploy", "Monitor"]
                                currentStep: 2
                            }

                            Text { text: qsTr("BreadcrumbBar"); color: ThemeManager.textSecondaryColor; font.pixelSize: 11 }
                            BreadcrumbBar {
                                items: [
                                    { label: qsTr("Workspace") },
                                    { label: qsTr("Projects")  },
                                    { label: qsTr("Valkyrie")  },
                                    { label: qsTr("Nodes")     }
                                ]
                                onItemClicked: function(i, item) { console.log("Breadcrumb:", item.label) }
                            }
                        }
                    }
                }
            }

            // ===================== UTILITIES =====================
            Section {
                sectionIndex: 12
                title: qsTr("Utilities")
                contentHeight: 460
                loader: Component {
                    Item {
                        Flow {
                            anchors.fill: parent; anchors.margins: 8; spacing: 12

                            Tile {
                                label: qsTr("Divider — labeled"); width: 280
                                Divider {
                                    anchors.left: parent.left; anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    label: qsTr("OR")
                                }
                            }
                            Tile {
                                label: qsTr("Divider — plain"); width: 200
                                Divider { anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
                            }

                            Tile {
                                label: qsTr("LoadingSpinner"); width: 200; height: 130
                                Row {
                                    anchors.centerIn: parent; spacing: 20
                                    LoadingSpinner { size: 20 }
                                    LoadingSpinner { size: 32; color: ThemeManager.accentColor }
                                    LoadingSpinner { size: 48; thickness: 5; color: ThemeManager.successColor }
                                }
                            }

                            Tile {
                                label: qsTr("SplitPane"); width: 340; height: 160
                                SplitPane {
                                    anchors.fill: parent
                                    orientation: Qt.Horizontal
                                    initialSplit: 0.4
                                    firstPanel: Component {
                                        Rectangle { color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.12)
                                            Text { anchors.centerIn: parent; text: qsTr("Left"); color: ThemeManager.textColor; font.pixelSize: 12 }
                                        }
                                    }
                                    secondPanel: Component {
                                        Rectangle { color: Qt.rgba(ThemeManager.accentColor.r, ThemeManager.accentColor.g, ThemeManager.accentColor.b, 0.12)
                                            Text { anchors.centerIn: parent; text: qsTr("Right"); color: ThemeManager.textColor; font.pixelSize: 12 }
                                        }
                                    }
                                }
                            }

                            Tile {
                                label: qsTr("CodeBlock"); width: 380; height: 200
                                CodeBlock {
                                    anchors.fill: parent
                                    language: "cpp"
                                    showCopyButton: true
                                    code: '#include <QApplication>\n#include "MainWindow.h"\n\nint main(int argc, char *argv[]) {\n    QApplication app(argc, argv);\n    MainWindow w;\n    w.show();\n    return app.exec();\n}'
                                }
                            }

                            Tile {
                                label: qsTr("Kbd — shortcuts"); width: 300; height: 140
                                Column {
                                    anchors.fill: parent; spacing: 10
                                    Row { spacing: 12
                                        Text { text: qsTr("Save:");      color: ThemeManager.textSecondaryColor; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                        Kbd { keys: "Ctrl+S" }
                                    }
                                    Row { spacing: 12
                                        Text { text: qsTr("Palette:");   color: ThemeManager.textSecondaryColor; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                        Kbd { keys: "Ctrl+P" }
                                    }
                                    Row { spacing: 12
                                        Text { text: qsTr("Undo:");      color: ThemeManager.textSecondaryColor; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                                        Kbd { keys: "Ctrl+Z" }
                                    }
                                    Row { spacing: 12
                                        Text { text: qsTr("Run all:");   color: ThemeManager.textSecondaryColor; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
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
