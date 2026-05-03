import QtQuick 2.15
import QtQuick.Controls 2.15 as Contrl
import QtQuick.Layouts 1.14
import App.Theme 1.0
import Qaterial 1.0 as Qaterial

Item {
    id: root

    // Variable types and their visual identity
    readonly property var typeConfig: ({
        "STRING":  { color: "#3B82F6", symbol: "\"\"", label: "String"  },
        "NUMBER":  { color: "#F59E0B", symbol: "#",    label: "Number"  },
        "BOOLEAN": { color: "#10B981", symbol: "✓",    label: "Boolean" },
        "COLOR":   { color: "#8B5CF6", symbol: "◆",    label: "Color"   },
        "ARRAY":   { color: "#F97316", symbol: "[ ]",  label: "Array"   }
    })

    property string typeFilter: "ALL"
    property string searchText: ""
    property bool   addFormOpen: false

    // Persistent variable store (runtime only until backend integration)
    ListModel {
        id: variablesModel
    }

    property var _typeKeys: ["STRING", "NUMBER", "BOOLEAN", "COLOR", "ARRAY"]

    function _addVariable(name, type, value) {
        if (!name.trim()) return
        variablesModel.append({
            varName:  name.trim(),
            varType:  type,
            varValue: value,
            editing:  false
        })
        addFormOpen = false
        newVarName.text  = ""
        newVarValue.text = ""
        newVarType.currentIndex = 0
    }

    function _typeColor(type) {
        return typeConfig[type] ? typeConfig[type].color : ThemeManager.textColor.toString()
    }

    function _typeSymbol(type) {
        return typeConfig[type] ? typeConfig[type].symbol : "?"
    }

    ColumnLayout {
        anchors.fill: parent; spacing: 0

        // ── Header ─────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 38
            color: Qt.darker(ThemeManager.backgroundColor, 1.15)

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left; anchors.right: parent.right
                height: 1; color: ThemeManager.primaryColor; opacity: 0.15
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12; anchors.rightMargin: 8; spacing: 6

                Qaterial.ColorIcon {
                    source: Qaterial.Icons.magnify
                    color: ThemeManager.textColor; opacity: 0.4
                    width: 14; height: 14
                }

                Item {
                    Layout.fillWidth: true; height: parent.height

                    Text {
                        anchors.fill: parent; verticalAlignment: Text.AlignVCenter
                        text: "Search variables…"
                        color: ThemeManager.textColor; opacity: 0.3; font.pixelSize: 12
                        visible: !varSearch.text.length && !varSearch.activeFocus
                    }
                    TextInput {
                        id: varSearch
                        anchors.fill: parent; verticalAlignment: TextInput.AlignVCenter
                        color: ThemeManager.textColor; font.pixelSize: 12; clip: true
                        selectionColor: ThemeManager.primaryColor
                        onTextChanged: root.searchText = text
                    }
                }

                // Variable count badge
                Rectangle {
                    height: 18; width: countBadge.implicitWidth + 12; radius: 9
                    color: Qt.rgba(ThemeManager.primaryColor.r,
                                   ThemeManager.primaryColor.g,
                                   ThemeManager.primaryColor.b, 0.15)
                    Text {
                        id: countBadge
                        anchors.centerIn: parent
                        text: variablesModel.count
                        font.pixelSize: 10; color: ThemeManager.primaryColor
                    }
                }

                // Add button
                Rectangle {
                    width: 24; height: 24; radius: 5
                    color: root.addFormOpen
                           ? ThemeManager.primaryColor
                           : Qt.rgba(ThemeManager.primaryColor.r,
                                     ThemeManager.primaryColor.g,
                                     ThemeManager.primaryColor.b, 0.15)
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Qaterial.ColorIcon {
                        source: root.addFormOpen ? Qaterial.Icons.close : Qaterial.Icons.plus
                        color: root.addFormOpen ? ThemeManager.backgroundColor : ThemeManager.primaryColor
                        width: 14; height: 14; anchors.centerIn: parent
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: root.addFormOpen = !root.addFormOpen
                    }
                }
            }
        }

        // ── Add variable form ───────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: root.addFormOpen ? 120 : 0
            clip: true
            color: Qt.darker(ThemeManager.backgroundColor, 1.08)
            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left; anchors.right: parent.right
                height: 1; color: ThemeManager.primaryColor; opacity: 0.12
            }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 8
                visible: root.addFormOpen

                // Row 1: Name + Type
                RowLayout {
                    Layout.fillWidth: true; spacing: 8

                    // Name field
                    Rectangle {
                        Layout.fillWidth: true; height: 30; radius: 4
                        color: Qt.rgba(ThemeManager.textColor.r,
                                       ThemeManager.textColor.g,
                                       ThemeManager.textColor.b, 0.06)
                        border.width: newVarName.activeFocus ? 1 : 0
                        border.color: ThemeManager.primaryColor

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                            spacing: 4

                            Text {
                                text: "name"
                                font.pixelSize: 9; color: ThemeManager.textColor; opacity: 0.35
                            }
                            TextInput {
                                id: newVarName
                                Layout.fillWidth: true
                                font.pixelSize: 12; color: ThemeManager.textColor
                                clip: true; selectionColor: ThemeManager.primaryColor
                            }
                        }
                    }

                    // Type selector
                    Rectangle {
                        width: 80; height: 30; radius: 4
                        color: Qt.rgba(ThemeManager.textColor.r,
                                       ThemeManager.textColor.g,
                                       ThemeManager.textColor.b, 0.06)

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 4
                            spacing: 4

                            Rectangle {
                                width: 8; height: 8; radius: 4
                                color: root._typeColor(root._typeKeys[newVarType.currentIndex])
                            }
                            Text {
                                Layout.fillWidth: true
                                text: root._typeKeys[newVarType.currentIndex]
                                font.pixelSize: 10; color: ThemeManager.textColor
                                elide: Text.ElideRight
                            }
                            Qaterial.ColorIcon {
                                source: Qaterial.Icons.chevronDown
                                color: ThemeManager.textColor; opacity: 0.5
                                width: 10; height: 10
                            }
                        }

                        Contrl.ComboBox {
                            id: newVarType
                            anchors.fill: parent; opacity: 0
                            model: root._typeKeys
                        }
                    }
                }

                // Row 2: Value
                Rectangle {
                    Layout.fillWidth: true; height: 30; radius: 4
                    color: Qt.rgba(ThemeManager.textColor.r,
                                   ThemeManager.textColor.g,
                                   ThemeManager.textColor.b, 0.06)
                    border.width: newVarValue.activeFocus ? 1 : 0
                    border.color: ThemeManager.primaryColor

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                        spacing: 4

                        Text {
                            text: "value"
                            font.pixelSize: 9; color: ThemeManager.textColor; opacity: 0.35
                        }
                        TextInput {
                            id: newVarValue
                            Layout.fillWidth: true
                            font.pixelSize: 12; color: ThemeManager.textColor
                            clip: true; selectionColor: ThemeManager.primaryColor
                            Keys.onReturnPressed: root._addVariable(
                                newVarName.text,
                                root._typeKeys[newVarType.currentIndex],
                                newVarValue.text
                            )
                        }
                    }
                }

                // Row 3: Actions
                RowLayout {
                    Layout.fillWidth: true; spacing: 8

                    Item { Layout.fillWidth: true }

                    // Cancel
                    Rectangle {
                        height: 24; width: cancelBtn.implicitWidth + 16; radius: 4
                        color: Qt.rgba(ThemeManager.textColor.r,
                                       ThemeManager.textColor.g,
                                       ThemeManager.textColor.b, 0.08)
                        Text {
                            id: cancelBtn
                            anchors.centerIn: parent
                            text: "Cancel"; font.pixelSize: 11; color: ThemeManager.textColor; opacity: 0.6
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.addFormOpen = false
                                newVarName.text  = ""
                                newVarValue.text = ""
                            }
                        }
                    }

                    // Add
                    Rectangle {
                        height: 24; width: addBtn.implicitWidth + 16; radius: 4
                        color: newVarName.text.trim().length > 0
                               ? ThemeManager.primaryColor
                               : Qt.rgba(ThemeManager.primaryColor.r,
                                         ThemeManager.primaryColor.g,
                                         ThemeManager.primaryColor.b, 0.25)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            id: addBtn
                            anchors.centerIn: parent
                            text: "Add Variable"; font.pixelSize: 11
                            color: ThemeManager.backgroundColor
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root._addVariable(
                                newVarName.text,
                                root._typeKeys[newVarType.currentIndex],
                                newVarValue.text
                            )
                        }
                    }
                }
            }
        }

        // ── Type filter chips ───────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 32; color: "transparent"

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left; anchors.right: parent.right
                height: 1; color: ThemeManager.primaryColor; opacity: 0.08
            }

            Flickable {
                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                contentWidth: typeChips.implicitWidth
                clip: true; flickableDirection: Flickable.HorizontalFlick; interactive: false

                Row {
                    id: typeChips
                    anchors.verticalCenter: parent.verticalCenter; spacing: 6

                    Repeater {
                        model: ["ALL"].concat(root._typeKeys)
                        delegate: Rectangle {
                            property bool active: root.typeFilter === modelData
                            property string chipColor: modelData === "ALL"
                                ? ThemeManager.primaryColor.toString()
                                : root._typeColor(modelData)
                            height: 18; width: chipLbl.implicitWidth + 14; radius: 9
                            color: active
                                   ? chipColor
                                   : Qt.rgba(ThemeManager.primaryColor.r,
                                             ThemeManager.primaryColor.g,
                                             ThemeManager.primaryColor.b, 0.12)
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                id: chipLbl
                                anchors.centerIn: parent
                                text: modelData === "ALL" ? "All"
                                      : (root._typeSymbol(modelData) + " " + root.typeConfig[modelData].label)
                                font.pixelSize: 9
                                color: active ? "#ffffff" : ThemeManager.textColor
                                opacity: active ? 1.0 : 0.6
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: root.typeFilter = modelData
                            }
                        }
                    }
                }
            }
        }

        // ── Variable list ────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true

            // Empty state
            Column {
                anchors.centerIn: parent; spacing: 12
                visible: variablesModel.count === 0

                Rectangle {
                    width: 48; height: 48; radius: 24; anchors.horizontalCenter: parent.horizontalCenter
                    color: Qt.rgba(ThemeManager.primaryColor.r,
                                   ThemeManager.primaryColor.g,
                                   ThemeManager.primaryColor.b, 0.08)

                    Qaterial.ColorIcon {
                        source: Qaterial.Icons.codeJson
                        color: ThemeManager.primaryColor; opacity: 0.4
                        width: 22; height: 22; anchors.centerIn: parent
                    }
                }
                Text {
                    text: "No variables yet"
                    font.pixelSize: 12; color: ThemeManager.textColor; opacity: 0.35
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: "Click + to add a global variable"
                    font.pixelSize: 10; color: ThemeManager.textColor; opacity: 0.22
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            ListView {
                id: varList
                anchors.fill: parent; clip: true
                spacing: 0

                Contrl.ScrollBar.vertical: Contrl.ScrollBar {
                    contentItem: Rectangle {
                        implicitWidth: 3; radius: 1.5
                        color: ThemeManager.primaryColor; opacity: 0.4
                    }
                }

                model: variablesModel

                delegate: Item {
                    id: varRow
                    width: varList.width; height: visible ? 44 : 0
                    visible: {
                        if (root.typeFilter !== "ALL" && varType !== root.typeFilter)
                            return false
                        if (root.searchText && varName.toLowerCase().indexOf(root.searchText.toLowerCase()) < 0)
                            return false
                        return true
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: rowHover.containsMouse
                               ? Qt.rgba(ThemeManager.primaryColor.r,
                                         ThemeManager.primaryColor.g,
                                         ThemeManager.primaryColor.b, 0.06)
                               : "transparent"
                        Behavior on color { ColorAnimation { duration: 80 } }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.leftMargin: 10; anchors.rightMargin: 10
                            height: 1; color: ThemeManager.primaryColor; opacity: 0.07
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10; anchors.rightMargin: 8; spacing: 8

                            // Type badge
                            Rectangle {
                                width: 28; height: 20; radius: 4
                                color: Qt.rgba(
                                    parseInt(root._typeColor(varType).slice(1,3), 16)/255,
                                    parseInt(root._typeColor(varType).slice(3,5), 16)/255,
                                    parseInt(root._typeColor(varType).slice(5,7), 16)/255,
                                    0.2
                                )
                                Text {
                                    anchors.centerIn: parent
                                    text: root._typeSymbol(varType)
                                    font.pixelSize: 9
                                    color: root._typeColor(varType)
                                }
                            }

                            // Name
                            Text {
                                Layout.preferredWidth: 80
                                text: varName; font.pixelSize: 12; font.bold: true
                                color: ThemeManager.textColor; elide: Text.ElideRight
                            }

                            // Value (inline edit)
                            Item {
                                Layout.fillWidth: true; height: 28

                                Rectangle {
                                    anchors.fill: parent; radius: 4
                                    color: editing
                                           ? Qt.rgba(ThemeManager.textColor.r,
                                                     ThemeManager.textColor.g,
                                                     ThemeManager.textColor.b, 0.08)
                                           : "transparent"
                                    border.width: editing ? 1 : 0
                                    border.color: ThemeManager.primaryColor

                                    Text {
                                        anchors.fill: parent
                                        anchors.leftMargin: editing ? 6 : 0
                                        verticalAlignment: Text.AlignVCenter
                                        text: varValue || "—"
                                        font.pixelSize: 11
                                        color: varValue
                                               ? ThemeManager.textColor
                                               : ThemeManager.textColor
                                        opacity: varValue ? 0.75 : 0.3
                                        elide: Text.ElideRight
                                        visible: !editing
                                    }

                                    TextInput {
                                        id: valueEdit
                                        anchors.fill: parent; anchors.leftMargin: 6
                                        verticalAlignment: TextInput.AlignVCenter
                                        font.pixelSize: 11; color: ThemeManager.textColor
                                        clip: true; selectionColor: ThemeManager.primaryColor
                                        visible: editing
                                        text: varValue

                                        onActiveFocusChanged: {
                                            if (!activeFocus && editing) {
                                                variablesModel.setProperty(index, "varValue", text)
                                                variablesModel.setProperty(index, "editing", false)
                                            }
                                        }
                                        Keys.onReturnPressed: {
                                            variablesModel.setProperty(index, "varValue", text)
                                            variablesModel.setProperty(index, "editing", false)
                                        }
                                        Keys.onEscapePressed: {
                                            text = varValue
                                            variablesModel.setProperty(index, "editing", false)
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.IBeamCursor
                                    visible: !editing
                                    onDoubleClicked: {
                                        variablesModel.setProperty(index, "editing", true)
                                        valueEdit.text = varValue
                                        valueEdit.forceActiveFocus()
                                    }
                                }
                            }

                            // Delete button (visible on hover)
                            Rectangle {
                                width: 20; height: 20; radius: 4
                                visible: rowHover.containsMouse
                                color: delHover.containsMouse
                                       ? "#EF4444"
                                       : Qt.rgba(ThemeManager.textColor.r,
                                                 ThemeManager.textColor.g,
                                                 ThemeManager.textColor.b, 0.1)
                                Behavior on color { ColorAnimation { duration: 80 } }

                                Qaterial.ColorIcon {
                                    source: Qaterial.Icons.trashCanOutline
                                    color: delHover.containsMouse ? "#ffffff" : ThemeManager.textColor
                                    opacity: delHover.containsMouse ? 1.0 : 0.5
                                    width: 11; height: 11; anchors.centerIn: parent
                                }
                                MouseArea {
                                    id: delHover
                                    anchors.fill: parent; hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: variablesModel.remove(index)
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: rowHover; anchors.fill: parent; hoverEnabled: true
                        // passes through to children — just for hover state
                        propagateComposedEvents: true
                        onClicked: mouse.accepted = false
                        onPressed: mouse.accepted = false
                    }
                }
            }
        }
    }
}
