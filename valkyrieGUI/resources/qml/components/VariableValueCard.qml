import QtQuick 2.15
import QtQuick.Controls 2.15 as Ctrl
import QtQuick.Layouts 1.14
import App.Theme 1.0
import App.Variables 1.0

// ─────────────────────────────────────────────────────────────────────────────
// VariableValueCard — type-aware value viewer/editor for a NodeVariable.
//
// Usage:
//   VariableValueCard {
//       variable: someNodeVar   // NodeVariable*
//       editable: true
//       compact:  false
//   }
// ─────────────────────────────────────────────────────────────────────────────
Item {
    id: root

    property var  variable:  null   // NodeVariable*
    property bool editable:  true
    property bool compact:   false
    property bool showName:  true
    property bool showType:  true

    signal valueEdited(string newValue)

    implicitHeight: _content.implicitHeight + (compact ? 0 : 8)
    implicitWidth:  200

    // Helper colours from the type config (matches VariablesDrawer)
    readonly property var _typeConfig: ({
        "STRING":  "#3B82F6", "NUMBER": "#F59E0B", "INT":     "#EF4444",
        "BOOLEAN": "#10B981", "COLOR":  "#8B5CF6", "ARRAY":   "#F97316",
        "LIST":    "#06B6D4", "DICT":   "#84CC16", "VEC2":    "#F43F5E", "VEC3": "#A855F7"
    })
    readonly property var _typeSymbol: ({
        "STRING": "\"\"","NUMBER":"#","INT":"\u2124","BOOLEAN":"\u2713","COLOR":"\u25C6",
        "ARRAY":"[ ]","LIST":"\u27E8\u27E9","DICT":"{}","VEC2":"\u2197","VEC3":"\u2295"
    })

    function _color(t) { return _typeConfig[t] || ThemeManager.textColor.toString() }
    function _symbol(t){ return _typeSymbol[t] || "?" }

    // ── Parse VEC2/VEC3 from "x,y,z" string ──────────────────────────────────
    function _vecParts(val, n) {
        var parts = (val || "0").split(",")
        var result = []
        for (var i = 0; i < n; i++)
            result.push(parts.length > i ? parseFloat(parts[i].trim()) : 0.0)
        return result
    }

    Column {
        id: _content
        anchors { left: parent.left; right: parent.right; top: parent.top }
        anchors.margins: compact ? 0 : 4
        spacing: 4

        // ── Header row (type badge + name) ────────────────────────────────────
        RowLayout {
            visible: root.showType || root.showName
            width: parent.width; spacing: 6

            Rectangle {
                visible: root.showType
                width: _symTxt.implicitWidth + 10; height: 18; radius: 3
                color: Qt.rgba(
                    parseInt(_color(root.variable ? root.variable.type : "STRING").slice(1,3),16)/255,
                    parseInt(_color(root.variable ? root.variable.type : "STRING").slice(3,5),16)/255,
                    parseInt(_color(root.variable ? root.variable.type : "STRING").slice(5,7),16)/255,
                    0.2)
                Text {
                    id: _symTxt; anchors.centerIn: parent
                    text: _symbol(root.variable ? root.variable.type : "STRING")
                    font.pixelSize: 9
                    color: _color(root.variable ? root.variable.type : "STRING")
                }
            }

            Text {
                visible: root.showName && root.variable !== null
                Layout.fillWidth: true
                text: root.variable ? root.variable.name : ""
                font.pixelSize: 11; font.bold: true
                color: ThemeManager.textColor; elide: Text.ElideRight
            }

            // Lock icon
            ColorIcon {
                visible: root.variable && root.variable.readOnly
                source: Icons.lockOutline
                color: ThemeManager.primaryColor; opacity: 0.6
                width: 10; height: 10
            }
        }

        // ── Value area (type-aware) ────────────────────────────────────────────
        Loader {
            width: parent.width
            sourceComponent: {
                if (!root.variable) return null
                var t = root.variable.type
                if (t === "NUMBER" || t === "INT") return _numComp
                if (t === "BOOLEAN")               return _boolComp
                if (t === "COLOR")                 return _colorComp
                if (t === "VEC2")                  return _vec2Comp
                if (t === "VEC3")                  return _vec3Comp
                if (t === "LIST" || t === "DICT" || t === "ARRAY") return _jsonComp
                return _stringComp
            }
        }
    }

    // ── STRING ────────────────────────────────────────────────────────────────
    Component {
        id: _stringComp
        Rectangle {
            height: 28; radius: 4
            color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                           ThemeManager.textColor.b, 0.06)
            border.width: _strIn.activeFocus ? 1 : 0
            border.color: ThemeManager.primaryColor

            TextInput {
                id: _strIn
                anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter
                font.pixelSize: 11; color: ThemeManager.textColor
                clip: true; selectionColor: ThemeManager.primaryColor
                readOnly: !root.editable || (root.variable && root.variable.readOnly)
                text: root.variable ? (root.variable.value || "") : ""
                onActiveFocusChanged: {
                    if (!activeFocus && root.variable)
                        VariableManager.setVariableValue(root.variable.id, text)
                }
                Keys.onReturnPressed: {
                    if (root.variable) VariableManager.setVariableValue(root.variable.id, text)
                }
            }
        }
    }

    // ── NUMBER / INT ──────────────────────────────────────────────────────────
    Component {
        id: _numComp
        RowLayout {
            spacing: 8

            Ctrl.Slider {
                id: _slider
                Layout.fillWidth: true
                from: -100; to: 100; stepSize: (root.variable && root.variable.type === "INT") ? 1 : 0
                value: root.variable ? parseFloat(root.variable.value || "0") : 0
                enabled: root.editable && !(root.variable && root.variable.readOnly)

                background: Rectangle {
                    x: _slider.leftPadding; y: _slider.topPadding + _slider.availableHeight/2 - height/2
                    width: _slider.availableWidth; height: 3; radius: 1.5
                    color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                                   ThemeManager.textColor.b, 0.15)
                    Rectangle {
                        width: _slider.visualPosition * parent.width
                        height: parent.height; radius: 1.5
                        color: ThemeManager.primaryColor
                    }
                }
                handle: Rectangle {
                    x: _slider.leftPadding + _slider.visualPosition * (_slider.availableWidth - width)
                    y: _slider.topPadding + _slider.availableHeight/2 - height/2
                    width: 12; height: 12; radius: 6
                    color: ThemeManager.primaryColor
                }
                onMoved: {
                    if (root.variable) {
                        var v = (root.variable.type === "INT") ? Math.round(value).toString() : value.toFixed(4)
                        VariableManager.setVariableValue(root.variable.id, v)
                    }
                }
            }

            Rectangle {
                width: 52; height: 26; radius: 4
                color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                               ThemeManager.textColor.b, 0.08)
                border.width: _numIn.activeFocus ? 1 : 0
                border.color: ThemeManager.primaryColor
                TextInput {
                    id: _numIn
                    anchors.fill: parent; anchors.margins: 4
                    horizontalAlignment: TextInput.AlignRight
                    verticalAlignment: TextInput.AlignVCenter
                    font.pixelSize: 11; color: ThemeManager.textColor
                    clip: true; selectionColor: ThemeManager.primaryColor
                    readOnly: !root.editable || (root.variable && root.variable.readOnly)
                    text: root.variable ? (root.variable.value || "0") : "0"
                    validator: root.variable && root.variable.type === "INT"
                               ? intVal : dblVal
                    onActiveFocusChanged: {
                        if (!activeFocus && root.variable)
                            VariableManager.setVariableValue(root.variable.id, text)
                    }
                    Keys.onReturnPressed: {
                        if (root.variable) VariableManager.setVariableValue(root.variable.id, text)
                    }
                }
                DoubleValidator { id: dblVal; notation: DoubleValidator.StandardNotation }
                IntValidator    { id: intVal }
            }
        }
    }

    // ── BOOLEAN ───────────────────────────────────────────────────────────────
    Component {
        id: _boolComp
        Rectangle {
            height: 26; radius: 13; width: implicitWidth
            property bool val: root.variable ? (root.variable.value === "true") : false
            implicitWidth: _boolTxt.implicitWidth + 24
            color: val ? Qt.rgba(0.07,0.73,0.51,0.2) : Qt.rgba(0.94,0.27,0.27,0.2)
            border.width: 1; border.color: val ? "#10B981" : "#EF4444"
            Behavior on color { ColorAnimation { duration: 100 } }
            Text {
                id: _boolTxt; anchors.centerIn: parent
                text: parent.val ? "true" : "false"
                font.pixelSize: 11; font.bold: true
                color: parent.val ? "#10B981" : "#EF4444"
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.editable && !(root.variable && root.variable.readOnly)
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (root.variable)
                        VariableManager.setVariableValue(root.variable.id, root.variable.value === "true" ? "false" : "true")
                }
            }
        }
    }

    // ── COLOR ─────────────────────────────────────────────────────────────────
    Component {
        id: _colorComp
        ColorPicker {
            showHex: true; label: ""
            height: 34
            enabled: root.editable && !(root.variable && root.variable.readOnly)
            value: (root.variable && root.variable.value) ? root.variable.value : "#888888"
            onAccepted: function(c) {
                if (root.variable) VariableManager.setVariableValue(root.variable.id, c.toString().toUpperCase())
            }
        }
    }

    // ── VEC2 ──────────────────────────────────────────────────────────────────
    Component {
        id: _vec2Comp
        RowLayout {
            spacing: 6
            Repeater {
                model: ["X","Y"]
                delegate: Rectangle {
                    Layout.fillWidth: true; height: 26; radius: 4
                    color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                                   ThemeManager.textColor.b, 0.06)
                    border.width: _vIn.activeFocus ? 1 : 0
                    border.color: ThemeManager.primaryColor
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 4; spacing: 4
                        Text { text: modelData; font.pixelSize: 9; color: "#F43F5E"; opacity: 0.9 }
                        TextInput {
                            id: _vIn; Layout.fillWidth: true
                            verticalAlignment: TextInput.AlignVCenter
                            font.pixelSize: 11; color: ThemeManager.textColor
                            clip: true; selectionColor: ThemeManager.primaryColor
                            readOnly: !root.editable || (root.variable && root.variable.readOnly)
                            text: {
                                var p = _vecParts(root.variable ? root.variable.value : "0,0", 2)
                                return (modelData === "X" ? p[0] : p[1]).toFixed(3)
                            }
                            validator: DoubleValidator { notation: DoubleValidator.StandardNotation }
                            onActiveFocusChanged: {
                                if (!activeFocus && root.variable) {
                                    var p = _vecParts(root.variable.value, 2)
                                    var val = modelData === "X"
                                        ? (text + "," + p[1].toFixed(3))
                                        : (p[0].toFixed(3) + "," + text)
                                    VariableManager.setVariableValue(root.variable.id, val)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── VEC3 ──────────────────────────────────────────────────────────────────
    Component {
        id: _vec3Comp
        Column {
            spacing: 4
            RowLayout {
                width: parent.width; spacing: 4
                Repeater {
                    model: ["X","Y","Z"]
                    delegate: Rectangle {
                        Layout.fillWidth: true; height: 26; radius: 4
                        color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                                       ThemeManager.textColor.b, 0.06)
                        border.width: _v3In.activeFocus ? 1 : 0
                        border.color: ThemeManager.primaryColor
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 5; anchors.rightMargin: 3; spacing: 3
                            Text { text: modelData; font.pixelSize: 9; color: "#A855F7"; opacity: 0.9 }
                            TextInput {
                                id: _v3In; Layout.fillWidth: true
                                verticalAlignment: TextInput.AlignVCenter
                                font.pixelSize: 10; color: ThemeManager.textColor
                                clip: true; selectionColor: ThemeManager.primaryColor
                                readOnly: !root.editable || (root.variable && root.variable.readOnly)
                                text: {
                                    var p = _vecParts(root.variable ? root.variable.value : "0,0,0", 3)
                                    var i = ["X","Y","Z"].indexOf(modelData)
                                    return p[i].toFixed(3)
                                }
                                validator: DoubleValidator { notation: DoubleValidator.StandardNotation }
                                onActiveFocusChanged: {
                                    if (!activeFocus && root.variable) {
                                        var p = _vecParts(root.variable.value, 3)
                                        var i = ["X","Y","Z"].indexOf(modelData)
                                        p[i] = parseFloat(text)
                                        VariableManager.setVariableValue(root.variable.id, p.join(","))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // Magnitude display
            Text {
                text: {
                    var p = _vecParts(root.variable ? root.variable.value : "0,0,0", 3)
                    var mag = Math.sqrt(p[0]*p[0] + p[1]*p[1] + p[2]*p[2])
                    return "mag: " + mag.toFixed(4)
                }
                font.pixelSize: 9; color: ThemeManager.textColor; opacity: 0.4
            }
        }
    }

    // ── ARRAY / LIST / DICT ───────────────────────────────────────────────────
    Component {
        id: _jsonComp
        Rectangle {
            height: Math.min(120, _jsonTxt.implicitHeight + 16); radius: 4
            clip: true
            color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g,
                           ThemeManager.textColor.b, 0.04)
            border.color: root.variable
                ? Qt.rgba(
                    parseInt((_typeConfig[root.variable.type] || "#888").slice(1,3),16)/255,
                    parseInt((_typeConfig[root.variable.type] || "#888").slice(3,5),16)/255,
                    parseInt((_typeConfig[root.variable.type] || "#888").slice(5,7),16)/255,
                    0.25)
                : ThemeManager.borderColor
            border.width: 1

            Ctrl.ScrollView {
                anchors.fill: parent; clip: true
                Ctrl.ScrollBar.vertical.policy: Ctrl.ScrollBar.AsNeeded
                TextEdit {
                    id: _jsonTxt
                    width: parent.width
                    leftPadding: 8; rightPadding: 8; topPadding: 6; bottomPadding: 6
                    font.family: "Consolas, Courier New, monospace"
                    font.pixelSize: 10; color: ThemeManager.textColor
                    wrapMode: TextEdit.Wrap
                    readOnly: !root.editable || (root.variable && root.variable.readOnly)
                    text: root.variable ? (root.variable.value || "") : ""
                    onActiveFocusChanged: {
                        if (!activeFocus && root.variable)
                            VariableManager.setVariableValue(root.variable.id, text)
                    }
                }
            }
        }
    }
}
