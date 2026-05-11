import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import App.Theme 1.0

// MultiSelect — combobox-style dropdown with checkboxes; selected items shown as chips.
//
// Usage:
//   MultiSelect {
//       model: ["Apple", "Banana", "Cherry", "Durian"]
//       onSelectionChanged: function(selected) { console.log(selected) }
//   }
Item {
    id: root

    property var    model:       []
    property var    selected:    []   // array of selected strings
    property string placeholder: qsTr("Select items…")
    property color  accentColor: ThemeManager.primaryColor
    property color  backgroundColor: Qt.rgba(1, 1, 1, 0.06)
    property color  borderColor: Qt.rgba(1, 1, 1, 0.18)
    property int    radius:      6
    property int    maxDropdownHeight: 220

    signal selectionChanged(var selected)

    implicitWidth:  220
    implicitHeight: Math.max(36, chipFlow.height + 12)

    function _toggle(item) {
        var copy = root.selected.slice()
        var idx  = copy.indexOf(item)
        if (idx === -1) copy.push(item)
        else            copy.splice(idx, 1)
        root.selected = copy
        root.selectionChanged(root.selected)
    }

    function _isSelected(item) { return root.selected.indexOf(item) !== -1 }

    // ── Field box ─────────────────────────────────────────────────────────────
    Rectangle {
        id: field
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.max(36, chipFlow.height + 12)
        radius: root.radius
        color: root.backgroundColor
        border.width: 1
        border.color: popup.visible ? root.accentColor : root.borderColor
        Behavior on border.color { ColorAnimation { duration: 120 } }
        clip: true

        // Field click (must be declared FIRST so chips render on top and receive clicks)
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.visible ? popup.close() : popup.open()
        }

        // Chips flow
        Flow {
            id: chipFlow
            anchors {
                top: parent.top; left: parent.left; right: arrowBtn.left
                margins: 6; rightMargin: 4
            }
            spacing: 4

            // Placeholder
            Text {
                visible: root.selected.length === 0
                text: root.placeholder
                color: Qt.rgba(ThemeManager.textColor.r,
                               ThemeManager.textColor.g,
                               ThemeManager.textColor.b, 0.4)
                font.pixelSize: 13
                height: 24
                verticalAlignment: Text.AlignVCenter
            }

            Repeater {
                model: root.selected
                delegate: Rectangle {
                    height: 22; radius: 11
                    color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.2)
                    width: chipLabel.implicitWidth + 36  // 8 left + label + 4 gap + 18 btn + 6 right

                    Text {
                        id: chipLabel
                        anchors.left: parent.left; anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData; font.pixelSize: 11
                        color: ThemeManager.textColor
                    }

                    // Close button — fixed-size Item for reliable hit testing
                    Item {
                        anchors.right: parent.right; anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16; height: 16

                        Text {
                            anchors.centerIn: parent
                            text: "×"; font.pixelSize: 14; font.bold: true
                            color: Qt.rgba(ThemeManager.textColor.r,
                                           ThemeManager.textColor.g,
                                           ThemeManager.textColor.b, 0.7)
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -3   // slightly larger hit area
                            cursorShape: Qt.PointingHandCursor
                            onClicked: function(mouse) {
                                mouse.accepted = true   // stop propagation to field MouseArea
                                root._toggle(modelData)
                            }
                        }
                    }
                }
            }
        }

        // Arrow indicator
        Canvas {
            id: arrowBtn
            width: 28; height: field.height
            anchors.right: parent.right
            contextType: "2d"
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.fillStyle = ThemeManager.textColor
                ctx.beginPath()
                ctx.moveTo(8, height/2 - 2); ctx.lineTo(18, height/2 - 2); ctx.lineTo(13, height/2 + 4)
                ctx.closePath(); ctx.fill()
            }
            rotation: popup.visible ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: 150 } }
        }

    }

    // ── Dropdown ──────────────────────────────────────────────────────────────
    Popup {
        id: popup
        y: field.height + 4
        width: root.width
        padding: 4
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            radius: root.radius
            color: ThemeManager.surfaceColor
            border.color: root.borderColor
            border.width: 1
        }

        contentItem: ListView {
            id: listView
            model: root.model
            clip: true
            implicitHeight: Math.min(root.maxDropdownHeight, contentHeight + 8)
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            delegate: ItemDelegate {
                width: popup.width - 8
                height: 36
                padding: 0

                background: Rectangle {
                    radius: 4
                    color: hovered ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                }

                contentItem: RowLayout {
                    anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
                    spacing: 8

                    // Checkbox indicator
                    Rectangle {
                        width: 16; height: 16; radius: 3
                        border.width: 2
                        border.color: root._isSelected(modelData) ? root.accentColor
                                                                   : Qt.rgba(1, 1, 1, 0.35)
                        color: root._isSelected(modelData) ? root.accentColor : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }

                        Canvas {
                            anchors.fill: parent; anchors.margins: 3
                            visible: root._isSelected(modelData)
                            onPaint: {
                                var ctx = getContext("2d"); ctx.reset()
                                ctx.strokeStyle = "#ffffff"; ctx.lineWidth = 2
                                ctx.lineCap = "round"; ctx.lineJoin = "round"
                                ctx.beginPath()
                                ctx.moveTo(width * 0.15, height * 0.55)
                                ctx.lineTo(width * 0.42, height * 0.80)
                                ctx.lineTo(width * 0.88, height * 0.22)
                                ctx.stroke()
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData
                        font.pixelSize: 13
                        color: ThemeManager.textColor
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                onClicked: root._toggle(modelData)
            }
        }
    }
}

