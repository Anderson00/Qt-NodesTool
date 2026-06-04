import QtQuick 2.15
import QtQuick.Controls 2.15 as Contrl
import QtQuick.Layouts 1.14
import App.Theme 1.0
import App.Variables 1.0
import App.Icons 1.0


import '../../components'

Item {
    id: root

    readonly property var typeConfig: ({
        "STRING":  { color: "#3B82F6", symbol: "\"\"", label: qsTr("String")  },
        "NUMBER":  { color: "#F59E0B", symbol: "#",    label: qsTr("Number")  },
        "INT":     { color: "#EF4444", symbol: "\u2124",  label: qsTr("Int")     },
        "BOOLEAN": { color: "#10B981", symbol: "✓",    label: qsTr("Boolean") },
        "COLOR":   { color: "#8B5CF6", symbol: "◆",    label: qsTr("Color")   },
        "ARRAY":   { color: "#F97316", symbol: "[ ]",  label: qsTr("Array")   },
        "LIST":    { color: "#06B6D4", symbol: "⟨⟩", label: qsTr("List") },
        "DICT":    { color: "#84CC16", symbol: "{}",    label: qsTr("Dict")    },
        "VEC2":    { color: "#F43F5E", symbol: "↗",  label: qsTr("Vec2")    },
        "VEC3":    { color: "#A855F7", symbol: "⊕",  label: qsTr("Vec3")    }
    })

    property string typeFilter:      "ALL"
    property string searchText:      ""
    property bool   addFormOpen:     false
    property bool   _newVarReadOnly: false
    property string _newVarType:     "STRING"
    property bool   _newVarBool:     false
    property color  _newVarColor:    "#7C6AF7"
    property string _newVarVecX:     "0"
    property string _newVarVecY:     "0"
    property string _newVarVecZ:     "0"

    readonly property var _typeKeys: ["STRING", "NUMBER", "INT", "BOOLEAN", "COLOR", "ARRAY", "LIST", "DICT", "VEC2", "VEC3"]

    function _typeColor(t) {
        return typeConfig[t] ? typeConfig[t].color : ThemeManager.textColor.toString()
    }
    function _typeSymbol(t) {
        return typeConfig[t] ? typeConfig[t].symbol : "?"
    }

    function _addVariable() {
        var name = newVarName.text.trim()
        if (!name) return
        var val = ""
        if (root._newVarType === "BOOLEAN")
            val = root._newVarBool ? "true" : "false"
        else if (root._newVarType === "COLOR")
            val = root._newVarColor.toString().toUpperCase()
        else if (root._newVarType === "VEC2")
            val = (root._newVarVecX || "0") + "," + (root._newVarVecY || "0")
        else if (root._newVarType === "VEC3")
            val = (root._newVarVecX || "0") + "," + (root._newVarVecY || "0") + "," + (root._newVarVecZ || "0")
        else
            val = newVarValue.text
        VariableManager.addVariable(name, root._newVarType, val, root._newVarReadOnly)
        _resetForm()
    }

    function _resetForm() {
        root.addFormOpen      = false
        root._newVarReadOnly  = false
        root._newVarBool      = false
        root._newVarColor     = "#7C6AF7"
        root._newVarType      = "STRING"
        root._newVarVecX      = "0"
        root._newVarVecY      = "0"
        root._newVarVecZ      = "0"
        newVarName.text       = ""
        newVarValue.text      = ""
        newVarType.currentIndex = 0
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

                ColorIcon {
                    source: Icons.magnify
                    color: ThemeManager.textColor; opacity: 0.4; width: 14; height: 14
                }

                Item {
                    Layout.fillWidth: true; height: parent.height
                    Text {
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.leftMargin: 2; anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("Search variables…"); font.pixelSize: 12
                        color: ThemeManager.textColor; opacity: 0.3
                        visible: !varSearch.text.length && !varSearch.activeFocus
                    }
                    TextInput {
                        id: varSearch
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.leftMargin: 2; anchors.verticalCenter: parent.verticalCenter
                        height: 22
                        color: ThemeManager.textColor; font.pixelSize: 12; clip: true
                        selectionColor: ThemeManager.primaryColor
                        verticalAlignment: TextInput.AlignVCenter
                        onTextChanged: root.searchText = text
                    }
                }

                Rectangle {
                    height: 18; width: countBadge.implicitWidth + 12; radius: 9
                    color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
                                   ThemeManager.primaryColor.b, 0.15)
                    Text {
                        id: countBadge; anchors.centerIn: parent
                        text: VariableManager.count; font.pixelSize: 10
                        color: ThemeManager.primaryColor
                    }
                }

                Rectangle {
                    width: 24; height: 24; radius: 5
                    color: root.addFormOpen
                           ? ThemeManager.primaryColor
                           : Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
                                     ThemeManager.primaryColor.b, 0.15)
                    Behavior on color { ColorAnimation { duration: 120 } }
                    ColorIcon {
                        source: root.addFormOpen ? Icons.close : Icons.plus
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
            Layout.preferredHeight: _formH
            clip: true
            color: Qt.darker(ThemeManager.backgroundColor, 1.08)

            property real _formH: root.addFormOpen ? 152 : 0
            Behavior on _formH { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left; anchors.right: parent.right
                height: 1; color: ThemeManager.primaryColor; opacity: 0.12
            }

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 10; spacing: 8

                // Row 1: Name + Type
                RowLayout {
                    Layout.fillWidth: true; spacing: 8

                    Rectangle {
                        Layout.fillWidth: true; height: 30; radius: 4
                        color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                                       ThemeManager.textColor.b, 0.06)
                        border.width: newVarName.activeFocus ? 1 : 0
                        border.color: ThemeManager.primaryColor

                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("name"); font.pixelSize: 9
                            color: ThemeManager.textColor; opacity: 0.35
                            visible: !newVarName.text.length && !newVarName.activeFocus
                        }
                        TextInput {
                            id: newVarName
                            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            font.pixelSize: 12; color: ThemeManager.textColor
                            clip: true; selectionColor: ThemeManager.primaryColor
                            Keys.onReturnPressed: root._addVariable()
                        }
                    }

                    Rectangle {
                        width: 84; height: 30; radius: 4
                        color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                                       ThemeManager.textColor.b, 0.06)

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 4
                            spacing: 4; enabled: false
                            Rectangle {
                                width: 8; height: 8; radius: 4
                                color: root._typeColor(root._newVarType)
                            }
                            Text {
                                Layout.fillWidth: true; text: root._newVarType
                                font.pixelSize: 10; color: ThemeManager.textColor; elide: Text.ElideRight
                            }
                            ColorIcon {
                                source: Icons.chevronDown
                                color: ThemeManager.textColor; opacity: 0.5; width: 10; height: 10
                            }
                        }

                        CustomComboBox {
                            id: newVarType
                            anchors.fill: parent; opacity: 0
                            model: root._typeKeys
                            onCurrentIndexChanged: root._newVarType = root._typeKeys[currentIndex]
                        }
                    }
                }

                // Row 2: Type-aware value input
                Item {
                    Layout.fillWidth: true
                    height: root._newVarType === "COLOR" ? 36
                          : (root._newVarType === "VEC2") ? 30
                          : (root._newVarType === "VEC3") ? 30
                          : 30

                    // ── STRING / NUMBER / INT / ARRAY / LIST / DICT ──────────
                    Rectangle {
                        visible: root._newVarType !== "BOOLEAN" && root._newVarType !== "COLOR"
                              && root._newVarType !== "VEC2"    && root._newVarType !== "VEC3"
                        anchors.fill: parent; radius: 4
                        color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                                       ThemeManager.textColor.b, 0.06)
                        border.width: newVarValue.activeFocus ? 1 : 0
                        border.color: ThemeManager.primaryColor

                        Text {
                            anchors.left: parent.left; anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 9; color: ThemeManager.textColor; opacity: 0.35
                            text: root._newVarType === "ARRAY" ? "1.0, 2.5, -3.0"
                                : root._newVarType === "LIST"  ? '[1, "text", true]'
                                : root._newVarType === "DICT"  ? '{"key": "value"}'
                                : root._newVarType === "INT"   ? "0"
                                : "value"
                            visible: !newVarValue.text.length && !newVarValue.activeFocus
                        }
                        TextInput {
                            id: newVarValue
                            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            font.pixelSize: 12; color: ThemeManager.textColor
                            clip: true; selectionColor: ThemeManager.primaryColor
                            validator: root._newVarType === "NUMBER" ? _formNumValidator
                                     : root._newVarType === "INT"    ? _formIntValidator
                                     : null
                            inputMethodHints: (root._newVarType === "NUMBER" || root._newVarType === "INT")
                                             ? Qt.ImhFormattedNumbersOnly : Qt.ImhNone
                            Keys.onReturnPressed: root._addVariable()
                        }
                        DoubleValidator  { id: _formNumValidator; notation: DoubleValidator.StandardNotation }
                        IntValidator     { id: _formIntValidator }
                    }

                    // ── BOOLEAN ──────────────────────────────────────────────
                    RowLayout {
                        visible: root._newVarType === "BOOLEAN"
                        anchors.fill: parent; spacing: 8

                        Rectangle {
                            Layout.fillWidth: true; height: 30; radius: 4
                            color: root._newVarBool
                                   ? Qt.rgba(0.07, 0.73, 0.51, 0.2)
                                   : Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                                             ThemeManager.textColor.b, 0.06)
                            border.width: root._newVarBool ? 1 : 0; border.color: "#10B981"
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text { anchors.centerIn: parent; text: qsTr("TRUE"); font.pixelSize: 11
                                   font.bold: root._newVarBool
                                   color: root._newVarBool ? "#10B981" : ThemeManager.textColor
                                   opacity: root._newVarBool ? 1.0 : 0.4 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: root._newVarBool = true }
                        }

                        Rectangle {
                            Layout.fillWidth: true; height: 30; radius: 4
                            color: !root._newVarBool
                                   ? Qt.rgba(0.94, 0.27, 0.27, 0.2)
                                   : Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                                             ThemeManager.textColor.b, 0.06)
                            border.width: !root._newVarBool ? 1 : 0; border.color: "#EF4444"
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text { anchors.centerIn: parent; text: qsTr("FALSE"); font.pixelSize: 11
                                   font.bold: !root._newVarBool
                                   color: !root._newVarBool ? "#EF4444" : ThemeManager.textColor
                                   opacity: !root._newVarBool ? 1.0 : 0.4 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: root._newVarBool = false }
                        }
                    }

                    // ── COLOR ─────────────────────────────────────────────────
                    ColorPicker {
                        id: newVarColorPicker
                        visible: root._newVarType === "COLOR"
                        anchors.fill: parent
                        showHex: true; label: ""
                        value: root._newVarColor
                        onAccepted: function(c) { root._newVarColor = c }
                    }

                    // ── VEC2 ──────────────────────────────────────────────────
                    RowLayout {
                        visible: root._newVarType === "VEC2"
                        anchors.fill: parent; spacing: 6

                        Repeater {
                            model: [{lbl:"X", prop:"_newVarVecX"}, {lbl:"Y", prop:"_newVarVecY"}]
                            delegate: Rectangle {
                                Layout.fillWidth: true; height: 30; radius: 4
                                color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                                               ThemeManager.textColor.b, 0.06)
                                border.width: vecIn.activeFocus ? 1 : 0
                                border.color: ThemeManager.primaryColor
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 6; spacing: 4
                                    Text { text: modelData.lbl; font.pixelSize: 9
                                           color: ThemeManager.primaryColor; opacity: 0.8 }
                                    TextInput {
                                        id: vecIn
                                        Layout.fillWidth: true
                                        verticalAlignment: TextInput.AlignVCenter
                                        font.pixelSize: 11; color: ThemeManager.textColor
                                        clip: true; selectionColor: ThemeManager.primaryColor
                                        text: modelData.prop === "_newVarVecX" ? root._newVarVecX : root._newVarVecY
                                        validator: DoubleValidator { notation: DoubleValidator.StandardNotation }
                                        onTextChanged: {
                                            if (modelData.prop === "_newVarVecX") root._newVarVecX = text
                                            else root._newVarVecY = text
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── VEC3 ──────────────────────────────────────────────────
                    RowLayout {
                        visible: root._newVarType === "VEC3"
                        anchors.fill: parent; spacing: 4

                        Repeater {
                            model: [{lbl:"X",prop:"X"},{lbl:"Y",prop:"Y"},{lbl:"Z",prop:"Z"}]
                            delegate: Rectangle {
                                Layout.fillWidth: true; height: 30; radius: 4
                                color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                                               ThemeManager.textColor.b, 0.06)
                                border.width: vec3In.activeFocus ? 1 : 0
                                border.color: ThemeManager.primaryColor
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 6; spacing: 4
                                    Text { text: modelData.lbl; font.pixelSize: 9
                                           color: ThemeManager.primaryColor; opacity: 0.8 }
                                    TextInput {
                                        id: vec3In
                                        Layout.fillWidth: true
                                        verticalAlignment: TextInput.AlignVCenter
                                        font.pixelSize: 11; color: ThemeManager.textColor
                                        clip: true; selectionColor: ThemeManager.primaryColor
                                        text: modelData.lbl === "X" ? root._newVarVecX
                                            : modelData.lbl === "Y" ? root._newVarVecY
                                            : root._newVarVecZ
                                        validator: DoubleValidator { notation: DoubleValidator.StandardNotation }
                                        onTextChanged: {
                                            if (modelData.lbl === "X")      root._newVarVecX = text
                                            else if (modelData.lbl === "Y") root._newVarVecY = text
                                            else                            root._newVarVecZ = text
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Row 3: ReadOnly + Cancel + Add
                RowLayout {
                    Layout.fillWidth: true; spacing: 8

                    CustomCheckBox {
                        text: ""
                        checked: root._newVarReadOnly
                        onCheckedChanged: {
                            root._newVarReadOnly = checked
                        }
                    }

                    Text {
                        text: qsTr("Read-only"); font.pixelSize: 11
                        color: ThemeManager.textColor; opacity: 0.6
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        height: 24; width: cancelLbl.implicitWidth + 16; radius: 4
                        color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                                       ThemeManager.textColor.b, 0.08)
                        Text {
                            id: cancelLbl; anchors.centerIn: parent
                            text: qsTr("Cancel"); font.pixelSize: 11
                            color: ThemeManager.textColor; opacity: 0.6
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root._resetForm()
                        }
                    }

                    Rectangle {
                        height: 24; width: addLbl.implicitWidth + 16; radius: 4
                        color: newVarName.text.trim().length > 0
                               ? ThemeManager.primaryColor
                               : Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
                                         ThemeManager.primaryColor.b, 0.25)
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            id: addLbl; anchors.centerIn: parent
                            text: qsTr("Add Variable"); font.pixelSize: 11
                            color: ThemeManager.backgroundColor
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root._addVariable()
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
                            color: active ? chipColor
                                   : Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
                                             ThemeManager.primaryColor.b, 0.12)
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Text {
                                id: chipLbl; anchors.centerIn: parent
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

            Column {
                anchors.centerIn: parent; spacing: 12
                visible: VariableManager.count === 0

                Rectangle {
                    width: 48; height: 48; radius: 24; anchors.horizontalCenter: parent.horizontalCenter
                    color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
                                   ThemeManager.primaryColor.b, 0.08)
                    ColorIcon {
                        source: Icons.codeJson; color: ThemeManager.primaryColor; opacity: 0.4
                        width: 22; height: 22; anchors.centerIn: parent
                    }
                }
                Text {
                    text: qsTr("No variables yet"); font.pixelSize: 12
                    color: ThemeManager.textColor; opacity: 0.35
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                Text {
                    text: qsTr("Click + to add a global variable"); font.pixelSize: 10
                    color: ThemeManager.textColor; opacity: 0.22
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            ListView {
                id: varList
                anchors.fill: parent; clip: true; spacing: 0

                Contrl.ScrollBar.vertical: Contrl.ScrollBar {
                    contentItem: Rectangle {
                        implicitWidth: 3; radius: 1.5
                        color: ThemeManager.primaryColor; opacity: 0.4
                    }
                }

                model: VariableManager.variables

                delegate: Item {
                    id: varRow
                    property var    varObj:    modelData
                    property bool   _editing:  false
                    property string _editText: ""

                    function _passFilter() {
                        if (!varObj) return false
                        if (root.typeFilter !== "ALL" && varObj.type !== root.typeFilter) return false
                        if (root.searchText && varObj.name.toLowerCase().indexOf(
                                root.searchText.toLowerCase()) < 0) return false
                        return true
                    }

                    width: varList.width
                    height: _passFilter() ? 44 : 0
                    visible: _passFilter()
                    clip: true

                    Rectangle {
                        anchors.fill: parent
                        color: rowHover.containsMouse
                               ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
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
                                    parseInt(root._typeColor(varObj ? varObj.type : "STRING").slice(1,3), 16)/255,
                                    parseInt(root._typeColor(varObj ? varObj.type : "STRING").slice(3,5), 16)/255,
                                    parseInt(root._typeColor(varObj ? varObj.type : "STRING").slice(5,7), 16)/255,
                                    0.2)
                                Text {
                                    anchors.centerIn: parent
                                    text: root._typeSymbol(varObj ? varObj.type : "STRING")
                                    font.pixelSize: 9
                                    color: root._typeColor(varObj ? varObj.type : "STRING")
                                }
                            }

                            // Name
                            Text {
                                Layout.preferredWidth: 72
                                text: varObj ? varObj.name : ""
                                font.pixelSize: 12; font.bold: true
                                color: ThemeManager.textColor; elide: Text.ElideRight
                            }

                            // ── Value area (type-aware) ──────────────────────
                            Item {
                                Layout.fillWidth: true
                                height: (varObj && varObj.type === "COLOR") ? 34 : 26

                                // ── COLOR: inline ColorPicker (its own popup handles picking) ──
                                ColorPicker {
                                    visible: varObj && varObj.type === "COLOR"
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: Math.min(parent.width, 160)
                                    height: parent.height
                                    showHex: true; label: ""
                                    enabled: varObj && !varObj.readOnly
                                    value: (varObj && varObj.value) ? varObj.value : "#888888"
                                    onAccepted: function(c) {
                                        if (varObj)
                                            VariableManager.setVariableValue(
                                                varObj.id, c.toString().toUpperCase())
                                    }
                                }

                                // ── BOOLEAN: pill toggle ──────────────────────
                                Item {
                                    visible: varObj && varObj.type === "BOOLEAN"
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 20
                                    width: boolPill.width

                                    Rectangle {
                                        id: boolPill
                                        height: 20; radius: 10
                                        width: boolLbl.implicitWidth + 16
                                        color: (varObj && varObj.value === "true")
                                               ? Qt.rgba(0.07, 0.73, 0.51, 0.22)
                                               : Qt.rgba(0.94, 0.27, 0.27, 0.22)
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        Text {
                                            id: boolLbl; anchors.centerIn: parent
                                            text: varObj ? (varObj.value || "false") : "false"
                                            font.pixelSize: 10; font.bold: true
                                            color: (varObj && varObj.value === "true")
                                                   ? "#10B981" : "#EF4444"
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: varObj && !varObj.readOnly
                                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: {
                                                if (varObj)
                                                    VariableManager.setVariableValue(
                                                        varObj.id,
                                                        varObj.value === "true" ? "false" : "true")
                                            }
                                        }
                                    }
                                }

                                // ── STRING / NUMBER / ARRAY ───────────────────
                                Item {
                                    visible: varObj && varObj.type !== "COLOR" && varObj.type !== "BOOLEAN"
                                    anchors.fill: parent

                                    Rectangle {
                                        anchors.fill: parent; radius: 4
                                        color: varRow._editing
                                               ? Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                                                         ThemeManager.textColor.b, 0.08)
                                               : "transparent"
                                        border.width: varRow._editing ? 1 : 0
                                        border.color: ThemeManager.primaryColor

                                        Text {
                                            visible: !varRow._editing
                                            anchors.fill: parent; anchors.leftMargin: 4
                                            verticalAlignment: Text.AlignVCenter
                                            text: varObj ? (varObj.value || "—") : "—"
                                            font.pixelSize: 11; color: ThemeManager.textColor
                                            opacity: (varObj && varObj.value) ? 0.75 : 0.3
                                            elide: Text.ElideRight
                                        }

                                        TextInput {
                                            id: valueEdit
                                            visible: varRow._editing
                                            anchors.fill: parent; anchors.leftMargin: 6
                                            verticalAlignment: TextInput.AlignVCenter
                                            font.pixelSize: 11; color: ThemeManager.textColor
                                            clip: true; selectionColor: ThemeManager.primaryColor
                                            text: varRow._editText
                                            validator: (varObj && varObj.type === "NUMBER")
                                                       ? _rowNumValidator : null
                                            inputMethodHints: (varObj && varObj.type === "NUMBER")
                                                              ? Qt.ImhFormattedNumbersOnly : Qt.ImhNone

                                            onActiveFocusChanged: {
                                                if (!activeFocus && varRow._editing) {
                                                    VariableManager.setVariableValue(varObj.id, text)
                                                    varRow._editing = false
                                                }
                                            }
                                            Keys.onReturnPressed: {
                                                VariableManager.setVariableValue(varObj.id, text)
                                                varRow._editing = false
                                            }
                                            Keys.onEscapePressed: { varRow._editing = false }
                                        }

                                        DoubleValidator {
                                            id: _rowNumValidator
                                            notation: DoubleValidator.StandardNotation
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        visible: !varRow._editing
                                        cursorShape: (!varObj || varObj.readOnly)
                                                     ? Qt.ArrowCursor : Qt.IBeamCursor
                                        onDoubleClicked: {
                                            if (!varObj || varObj.readOnly) return
                                            varRow._editText = varObj.value
                                            varRow._editing  = true
                                            valueEdit.forceActiveFocus()
                                        }
                                    }
                                }

                            }

                            // ReadOnly lock
                            ColorIcon {
                                source: Icons.lockOutline
                                color: ThemeManager.primaryColor
                                opacity: (varObj && varObj.readOnly) ? 0.65 : 0.0
                                width: 12; height: 12
                                Behavior on opacity { NumberAnimation { duration: 100 } }
                            }

                            // Action buttons (hover)
                            Row {
                                spacing: 4
                                visible: rowHover.containsMouse && !varRow._editing

                                Rectangle {
                                    width: 20; height: 20; radius: 4
                                    color: lockHover.containsMouse
                                           ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
                                                     ThemeManager.primaryColor.b, 0.25)
                                           : Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                                                     ThemeManager.textColor.b, 0.1)
                                    Behavior on color { ColorAnimation { duration: 80 } }
                                    ColorIcon {
                                        source: (varObj && varObj.readOnly)
                                                ? Icons.lockOutline : Icons.lockOpenOutline
                                        color: ThemeManager.primaryColor; opacity: 0.7
                                        width: 11; height: 11; anchors.centerIn: parent
                                    }
                                    MouseArea {
                                        id: lockHover; anchors.fill: parent
                                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (varObj)
                                                VariableManager.setVariableReadOnly(varObj.id, !varObj.readOnly)
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 20; height: 20; radius: 4
                                    color: delHover.containsMouse ? "#EF4444"
                                           : Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                                                     ThemeManager.textColor.b, 0.1)
                                    Behavior on color { ColorAnimation { duration: 80 } }
                                    ColorIcon {
                                        source: Icons.trashCanOutline
                                        color: delHover.containsMouse ? "#ffffff" : ThemeManager.textColor
                                        opacity: delHover.containsMouse ? 1.0 : 0.5
                                        width: 11; height: 11; anchors.centerIn: parent
                                    }
                                    MouseArea {
                                        id: delHover; anchors.fill: parent
                                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { if (varObj) VariableManager.removeVariable(varObj.id) }
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: rowHover; anchors.fill: parent; hoverEnabled: true
                        propagateComposedEvents: true
                        onClicked: mouse.accepted = false
                        onPressed: mouse.accepted = false
                    }
                }
            }
        }
    }
}

