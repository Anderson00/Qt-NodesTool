import QtQuick 2.15
import QtQuick.Controls 2.15 as Ctrl
import App.Theme 1.0
import App.Widgets 1.0

// ─────────────────────────────────────────────────────────────────────────────
// CodeEditor — Editable code editor with:
//   • Syntax highlighting via PythonHighlighter (C++ QSyntaxHighlighter)
//   • Line numbers gutter (auto-width)
//   • Current-line highlight bar
//   • Keyboard shortcuts (Tab, Shift+Tab, Enter auto-indent, Ctrl+/, Ctrl+D, Ctrl+Enter)
//   • Vertical + horizontal scrollbars
//
// Usage:
//   CodeEditor {
//       code: behaviourObject.script
//       onCodeChanged: behaviourObject.setScript(newCode)
//       onRunRequested: behaviourObject.run()
//   }
// ─────────────────────────────────────────────────────────────────────────────
Item {
    id: root

    // ── Public API ────────────────────────────────────────────────────────────
    property string code:       ""
    property bool   readOnly:   false

    // Visual
    property int    fontSize:         13
    property color  bgColor:          "#1E1E1E"
    property color  currentLineColor: "#2A2D2E"
    property color  gutterBg:         "#252526"
    property color  gutterFg:         "#5A5A5A"
    property color  textColor_:       "#D4D4D4"
    property color  borderColor_:     "#3C3C3C"

    // Behaviour
    property bool   showLineNumbers:  true
    property bool   autoIndent:       true
    property bool   tabToSpaces:      true
    property int    tabSize:          4

    // Signals
    signal codeModified(string newCode)
    signal runRequested()
    signal saveRequested()

    // ── Internal state ────────────────────────────────────────────────────────
    readonly property int _gutterW: showLineNumbers
                                    ? Math.max(36, _gutterMetrics.advanceWidth(String(_editor.lineCount)) + 20)
                                    : 0

    // Line height in pixels (exact calculation via FontMetrics)
    readonly property real _lineH: Math.max(1, _editorMetrics.lineSpacing)

    // Y position of the highlighted bar under the cursor
    readonly property real _cursorY: _editor.cursorRectangle.y

    // Current line index (0-based)
    readonly property int  _cursorLine: {
        var pos = _editor.cursorPosition
        var text = _editor.text.substring(0, pos)
        return text.split("\n").length - 1
    }

    // ── Sync code property → editor (avoid binding loop) ────────────────────
    onCodeChanged: {
        if (_editor.text !== code)
            _editor.text = code
    }

    // ── Root background ───────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: root.bgColor
        border.color: root.borderColor_
        border.width: 1
        radius: 4
        clip: true

        // ── Current-line highlight (behind text) ──────────────────────────────
        Rectangle {
            id: _lineHighlight
            x:      root._gutterW
            y:      root._cursorY - _scroll.contentItem.y + 0
            width:  parent.width - root._gutterW
            height: Math.max(root._lineH, 1)
            color:  root.currentLineColor
            opacity: _editor.activeFocus ? 0.6 : 0.0
            z: 0
            Behavior on y       { NumberAnimation { duration: 60; easing.type: Easing.OutQuad } }
            Behavior on opacity { NumberAnimation { duration: 80 } }
        }

        // ── Gutter (line numbers) ─────────────────────────────────────────────
        Rectangle {
            id: _gutter
            visible: root.showLineNumbers
            width:   root._gutterW
            anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
            color: root.gutterBg
            z: 2

            // Right border separator
            Rectangle {
                width: 1; anchors { top: parent.top; bottom: parent.bottom; right: parent.right }
                color: root.borderColor_; opacity: 0.6
            }

            // Sync gutter scroll with the editor scroll
            ListView {
                id: _gutterList
                anchors.fill: parent
                anchors.rightMargin: 1
                model: _editor.lineCount
                interactive: false
                clip: true
                
                // Match the padding of the TextEdit so they align perfectly
                topMargin: 8
                bottomMargin: 8

                // Keep gutter Y in sync with editor scroll
                contentY: _scroll.contentItem ? _scroll.contentItem.contentY : 0

                delegate: Item {
                    width: _gutter.width
                    height: root._lineH

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: index + 1
                        font.family: "Consolas, Courier New, monospace"
                        font.pixelSize: root.fontSize - 1
                        color: (index === root._cursorLine)
                               ? ThemeManager.primaryColor
                               : root.gutterFg
                        Behavior on color { ColorAnimation { duration: 80 } }
                    }
                }
            }
        }

        // ── Scroll view (editor area) ─────────────────────────────────────────
        Ctrl.ScrollView {
            id: _scroll
            anchors {
                top:    parent.top
                bottom: parent.bottom
                left:   _gutter.right
                right:  parent.right
            }
            clip: true
            contentWidth: _editor.width
            contentHeight: _editor.height

            // Styled scrollbars matching the project's thin scrollbar style
            Ctrl.ScrollBar.vertical: Ctrl.ScrollBar {
                contentItem: Rectangle {
                    implicitWidth: 4; radius: 2
                    color: ThemeManager.primaryColor; opacity: 0.35
                }
            }
            Ctrl.ScrollBar.horizontal: Ctrl.ScrollBar {
                contentItem: Rectangle {
                    implicitHeight: 4; radius: 2
                    color: ThemeManager.primaryColor; opacity: 0.35
                }
            }

            TextEdit {
                id: _editor

                width: Math.max(_scroll.width, implicitWidth)
                height: Math.max(_scroll.height, implicitHeight)

                topPadding:    8
                bottomPadding: 8
                leftPadding:   10
                rightPadding:  10

                text:          root.code
                readOnly:      root.readOnly
                color:         root.textColor_
                selectByMouse: true
                selectByKeyboard: true
                persistentSelection: true
                selectionColor: Qt.rgba(ThemeManager.primaryColor.r,
                                        ThemeManager.primaryColor.g,
                                        ThemeManager.primaryColor.b, 0.35)
                selectedTextColor: root.textColor_

                font.family:   "Consolas, Courier New, monospace"
                font.pixelSize: root.fontSize
                wrapMode:      TextEdit.NoWrap
                tabStopDistance: root.tabSize * font.pixelSize   // visual tab width

                // Blinking cursor colour
                cursorDelegate: Rectangle {
                    width: 2
                    color: ThemeManager.primaryColor
                    opacity: parent.cursorVisible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                // Attach the C++ Python syntax highlighter
                PythonHighlighter {
                    id: _highlighter
                    textDocument: _editor.textDocument
                }

                // Propagate text changes back to the root property (debounced)
                onTextChanged: {
                    if (root.code !== text) {
                        root.code = text
                        root.codeModified(text)
                    }
                }

                // ── Keyboard shortcuts ────────────────────────────────────────
                Keys.onPressed: function(event) {

                    // ── Ctrl+Enter → run ──────────────────────────────────────
                    if (event.key === Qt.Key_Return &&
                        (event.modifiers & Qt.ControlModifier)) {
                        root.runRequested()
                        event.accepted = true
                        return
                    }

                    // ── Ctrl+S → save ─────────────────────────────────────────
                    if (event.key === Qt.Key_S &&
                        (event.modifiers & Qt.ControlModifier)) {
                        root.saveRequested()
                        event.accepted = true
                        return
                    }

                    // ── Tab → 4 spaces ────────────────────────────────────────
                    if (event.key === Qt.Key_Tab && root.tabToSpaces) {
                        var spaces = ""
                        for (var s = 0; s < root.tabSize; s++) spaces += " "
                        _editor.insert(_editor.cursorPosition, spaces)
                        event.accepted = true
                        return
                    }

                    // ── Shift+Tab → remove up to tabSize leading spaces ────────
                    if (event.key === Qt.Key_Backtab) {
                        var pos     = _editor.cursorPosition
                        var lineStart = _editor.text.lastIndexOf("\n", pos - 1) + 1
                        var removed = 0
                        while (removed < root.tabSize &&
                               lineStart + removed < _editor.text.length &&
                               _editor.text[lineStart + removed] === " ") {
                            removed++
                        }
                        if (removed > 0) {
                            _editor.remove(lineStart, lineStart + removed)
                        }
                        event.accepted = true
                        return
                    }

                    // ── Enter → auto-indent (repeat indentation of current line)
                    if (event.key === Qt.Key_Return && root.autoIndent) {
                        var curPos    = _editor.cursorPosition
                        var lineBegin = _editor.text.lastIndexOf("\n", curPos - 1) + 1
                        var lineText  = _editor.text.substring(lineBegin, curPos)
                        var indent    = ""
                        for (var c = 0; c < lineText.length; c++) {
                            if (lineText[c] === " " || lineText[c] === "\t")
                                indent += lineText[c]
                            else
                                break
                        }
                        // If the current line ends with ':', add one extra level
                        var trimmed = lineText.replace(/\s+$/, "")
                        if (trimmed.endsWith(":")) {
                            for (var e = 0; e < root.tabSize; e++) indent += " "
                        }
                        _editor.insert(curPos, "\n" + indent)
                        event.accepted = true
                        return
                    }

                    // ── Ctrl+/ → toggle line comment ──────────────────────────
                    if (event.key === Qt.Key_Slash &&
                        (event.modifiers & Qt.ControlModifier)) {
                        var cp       = _editor.cursorPosition
                        var lb       = _editor.text.lastIndexOf("\n", cp - 1) + 1
                        var lineEnd  = _editor.text.indexOf("\n", cp)
                        if (lineEnd < 0) lineEnd = _editor.text.length
                        var line     = _editor.text.substring(lb, lineEnd)
                        var ltrim    = line.trimLeft()
                        if (ltrim.startsWith("# ")) {
                            // uncomment: remove "# "
                            var commentIdx = lb + (line.length - ltrim.length)
                            _editor.remove(commentIdx, commentIdx + 2)
                        } else if (ltrim.startsWith("#")) {
                            // uncomment: remove "#"
                            var commentIdx2 = lb + (line.length - ltrim.length)
                            _editor.remove(commentIdx2, commentIdx2 + 1)
                        } else {
                            // comment: insert "# " at line start (after leading spaces)
                            var leadSpaces = line.length - ltrim.length
                            _editor.insert(lb + leadSpaces, "# ")
                        }
                        event.accepted = true
                        return
                    }

                    // ── Ctrl+D → duplicate current line ──────────────────────
                    if (event.key === Qt.Key_D &&
                        (event.modifiers & Qt.ControlModifier)) {
                        var dp       = _editor.cursorPosition
                        var dlb      = _editor.text.lastIndexOf("\n", dp - 1) + 1
                        var dle      = _editor.text.indexOf("\n", dp)
                        if (dle < 0) dle = _editor.text.length
                        var dupLine  = _editor.text.substring(dlb, dle)
                        _editor.insert(dle, "\n" + dupLine)
                        event.accepted = true
                        return
                    }
                }
            }
        }

        // ── Focus ring ────────────────────────────────────────────────────────
        Rectangle {
            anchors.fill: parent; radius: 4
            color: "transparent"
            border.color: ThemeManager.primaryColor
            border.width: _editor.activeFocus ? 1 : 0
            opacity: 0.5
            Behavior on border.width { NumberAnimation { duration: 100 } }
        }
    }

    // ── FontMetrics for gutter width calculation ──────────────────────────────
    FontMetrics {
        id: _gutterMetrics
        font.family: "Consolas, Courier New, monospace"
        font.pixelSize: root.fontSize - 1
    }

    FontMetrics {
        id: _editorMetrics
        font.family: "Consolas, Courier New, monospace"
        font.pixelSize: root.fontSize
    }

    // ── Public method: focus the editor ──────────────────────────────────────
    function focusEditor() {
        _editor.forceActiveFocus()
    }

    // ── Public method: move cursor to a specific line ─────────────────────────
    function goToLine(line) {
        var lines = _editor.text.split("\n")
        var charPos = 0
        var target  = Math.min(line, lines.length - 1)
        for (var i = 0; i < target; i++) charPos += lines[i].length + 1
        _editor.cursorPosition = charPos
        _editor.forceActiveFocus()
    }
}
