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
                    implicitWidth: 140
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

            // bottom padding
            Item { width: parent.width; height: 12 }
        }
    }
}
