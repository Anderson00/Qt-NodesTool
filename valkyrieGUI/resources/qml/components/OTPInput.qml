import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import App.Theme 1.0

// OTPInput — N-digit one-time-password / PIN entry.
// Each digit occupies its own box. Auto-advances focus on input.
//
// Usage:
//   OTPInput {
//       digits: 6
//       onCodeComplete: function(code) { verify(code) }
//   }
Item {
    id: root

    property int    digits:      6
    property bool   masked:      false      // show ● instead of digit
    property bool   numbersOnly: true
    property color  accentColor: ThemeManager.primaryColor
    property color  backgroundColor: Qt.rgba(1, 1, 1, 0.06)
    property color  borderColor: Qt.rgba(1, 1, 1, 0.18)
    property int    boxSize:     42
    property int    spacing:     8
    property int    fontSize:    20
    property string code:        ""         // read-only: current code string

    signal codeComplete(string code)

    implicitWidth:  root.digits * root.boxSize + (root.digits - 1) * root.spacing
    implicitHeight: root.boxSize

    // Internal values array
    property var _vals: { var a = []; for (var i = 0; i < root.digits; i++) a.push(""); return a }

    function _rebuild() {
        var s = ""
        for (var i = 0; i < root.digits; i++) s += root._vals[i]
        root.code = s
        if (s.length === root.digits) root.codeComplete(s)
    }

    function clear() {
        var a = []
        for (var i = 0; i < root.digits; i++) a.push("")
        root._vals = a
        root._rebuild()
        if (digitRepeater.itemAt(0)) digitRepeater.itemAt(0).forceActiveFocus()
    }

    // Validator declared outside ternary (QML doesn't allow inline object in ternary)
    IntValidator { id: _digitValidator; bottom: 0; top: 9 }

    Row {
        spacing: root.spacing

        Repeater {
            id: digitRepeater
            model: root.digits

            delegate: Rectangle {
                id: box
                width: root.boxSize; height: root.boxSize; radius: 6
                color: root.backgroundColor
                border.width: 2
                border.color: input.activeFocus ? root.accentColor : root.borderColor
                Behavior on border.color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: root.masked && root._vals[index] !== "" ? "●" : root._vals[index]
                    font.pixelSize: root.fontSize; font.bold: true
                    color: ThemeManager.textColor
                }

                TextInput {
                    id: input
                    anchors.fill: parent
                    opacity: 0
                    font.pixelSize: root.fontSize
                    maximumLength: 1
                    inputMethodHints: root.numbersOnly ? Qt.ImhDigitsOnly : Qt.ImhNone
                    validator: root.numbersOnly ? _digitValidator : null
                    cursorVisible: false

                    onTextChanged: {
                        if (text.length === 0) {
                            var a = root._vals.slice()
                            a[index] = ""
                            root._vals = a
                            root._rebuild()
                            return
                        }
                        var ch = text[text.length - 1]
                        if (root.numbersOnly && !(/[0-9]/.test(ch))) { text = ""; return }
                        var arr = root._vals.slice()
                        arr[index] = ch
                        root._vals = arr
                        root._rebuild()
                        // advance
                        if (index < root.digits - 1) {
                            var next = digitRepeater.itemAt(index + 1)
                            if (next) next.children[1].forceActiveFocus() // TextInput is child 1
                        }
                        text = ""
                    }

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Backspace) {
                            var arr = root._vals.slice()
                            if (arr[index] !== "") {
                                arr[index] = ""; root._vals = arr; root._rebuild()
                            } else if (index > 0) {
                                var prev = digitRepeater.itemAt(index - 1)
                                if (prev) {
                                    prev.children[1].forceActiveFocus()
                                    arr[index - 1] = ""; root._vals = arr; root._rebuild()
                                }
                            }
                            event.accepted = true
                            return
                        }
                        // allow paste
                        if (event.matches(StandardKey.Paste)) {
                            event.accepted = false
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: input.forceActiveFocus()
                }
            }
        }
    }
}
