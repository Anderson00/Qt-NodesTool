import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0

// CodeBlock — styled code display with optional copy button and scrollbars.
//
// Usage:
//   CodeBlock {
//       code: "int main() {\n    return 0;\n}"
//       language: "cpp"
//       showCopyButton: true
//       maxHeight: 300
//   }
Item {
    id: root

    property string code:           ""
    property string language:       ""
    property bool   showCopyButton: true
    property int    maxHeight:      0      // 0 = unlimited
    property color  bgColor:        Qt.darker(ThemeManager.backgroundColor, 1.3)
    property color  textColor:      ThemeManager.textColor
    property color  borderColor:    ThemeManager.borderColor
    property int    fontSize:       12
    property bool   wrapText:       false

    // ── Syntax highlighting ───────────────────────────────────────────────────
    // Returns HTML string for use with textFormat: Text.RichText.
    // Uses VS Code Dark+ colour palette.
    function _highlight(src, lang) {
        var langId = lang.toLowerCase()

        // Colour tokens (VS Code Dark+ inspired)
        var C_KW      = "#569cd6"  // blue      – keywords
        var C_STR     = "#ce9178"  // orange    – string literals
        var C_COMMENT = "#6a9955"  // green     – comments
        var C_NUM     = "#b5cea8"  // pale-green – numbers
        var C_TYPE    = "#4ec9b0"  // teal      – Types / Classes
        var C_PREPROC = "#c586c0"  // purple    – preprocessor directives
        var C_FUNC    = "#dcdcaa"  // yellow    – function calls

        // HTML helpers (declared as function statements so they are hoisted)
        function span(color, text) { return '<span style="color:' + color + '">' + text + '</span>' }
        function esc(s) {
            return s.replace(/&/g, '&amp;')
                    .replace(/</g, '&lt;')
                    .replace(/>/g, '&gt;')
                    .replace(/ /g, '&nbsp;')
                    .replace(/\t/g, '&nbsp;&nbsp;&nbsp;&nbsp;')
                    .replace(/\n/g, '<br/>')
        }

        // Keyword sets per language
        var kwMap = {
            "c":     "auto break case char const continue default do double else enum extern false float for goto if inline int long register return short signed sizeof static struct switch true typedef union unsigned void volatile while",
            "cpp":   "auto bool break case catch char class const constexpr continue default delete do double else enum explicit extern false final float for friend goto if inline int long namespace new nullptr operator override private protected public register return short signed sizeof static struct switch template this throw true try typedef typename union unsigned using virtual void volatile while",
            "js":    "async await break case catch class const continue debugger default delete do else export extends false finally for from function if import in instanceof let new null of return static super switch this throw true try typeof undefined var void while with yield",
            "javascript": "async await break case catch class const continue debugger default delete do else export extends false finally for from function if import in instanceof let new null of return static super switch this throw true try typeof undefined var void while with yield",
            "ts":    "abstract any as async await boolean break case catch class const continue declare default delete do else enum export extends false finally for from function if implements import in instanceof interface let module namespace new null number object of override return static string super switch this throw true try type typeof undefined unknown var void while with yield",
            "typescript": "abstract any as async await boolean break case catch class const continue declare default delete do else enum export extends false finally for from function if implements import in instanceof interface let module namespace new null number object of override return static string super switch this throw true try type typeof undefined unknown var void while with yield",
            "python": "and as assert async await break class continue def del elif else except False finally for from global if import in is lambda None nonlocal not or pass raise return True try while with yield",
            "qml":   "alias anchors as break case catch const continue default else export false finally for function id if import in instanceof let null on property readonly required return signal static super switch this throw true try typeof undefined var void while with",
            "json":  "true false null",
            "bash":  "case do done elif else esac fi for function if in local readonly return select then until while",
            "sh":    "case do done elif else esac fi for function if in local readonly return select then until while",
            "rust":  "as async await break const continue crate dyn else enum extern false fn for if impl in let loop match mod move mut pub ref return self Self static struct super trait true type union unsafe use where while",
            "go":    "break case chan const continue default defer else fallthrough false for func go goto if import interface map nil package range return select struct switch true type var"
        }

        // Build a fast lookup set
        var kwSet = {}
        var kwStr = kwMap[langId] || ""
        var kwArr = kwStr.split(" ")
        for (var ki = 0; ki < kwArr.length; ki++) { if (kwArr[ki]) kwSet[kwArr[ki]] = true }

        var hasPoundComment = /^(python|bash|sh|cmake|yaml|toml|ruby|r)$/.test(langId)
        var hasPoundPreproc = /^(c|cpp)$/.test(langId)
        var hasLineSlash    = !hasPoundComment
        var hasBlock        = /^(c|cpp|js|javascript|ts|typescript|qml|java|go|rust|css)$/.test(langId)

        var out = ""
        var i   = 0
        var n   = src.length

        while (i < n) {
            var ch = src[i]

            // ── line comment //
            if (hasLineSlash && ch === '/' && i+1 < n && src[i+1] === '/') {
                var e = src.indexOf('\n', i); if (e < 0) e = n
                out += span(C_COMMENT, esc(src.substring(i, e))); i = e; continue
            }
            // ── block comment /* */
            if (hasBlock && ch === '/' && i+1 < n && src[i+1] === '*') {
                var e2 = src.indexOf('*/', i+2); e2 = (e2 < 0) ? n : e2 + 2
                out += span(C_COMMENT, esc(src.substring(i, e2))); i = e2; continue
            }
            // ── # — preprocessor (C/C++) or line comment (Python/Bash)
            if (ch === '#' && (hasPoundComment || hasPoundPreproc)) {
                var e3 = src.indexOf('\n', i); if (e3 < 0) e3 = n
                out += span(hasPoundPreproc ? C_PREPROC : C_COMMENT,
                            esc(src.substring(i, e3))); i = e3; continue
            }
            // ── double-quoted string
            if (ch === '"') {
                var j = i + 1
                while (j < n) { if (src[j] === '\\') { j += 2 } else if (src[j] === '"') { j++; break } else j++ }
                out += span(C_STR, esc(src.substring(i, j))); i = j; continue
            }
            // ── single-quoted string
            if (ch === "'") {
                var j2 = i + 1
                while (j2 < n) { if (src[j2] === '\\') { j2 += 2 } else if (src[j2] === "'") { j2++; break } else j2++ }
                out += span(C_STR, esc(src.substring(i, j2))); i = j2; continue
            }
            // ── backtick template literal
            if (ch === '`') {
                var j3 = i + 1
                while (j3 < n) { if (src[j3] === '\\') { j3 += 2 } else if (src[j3] === '`') { j3++; break } else j3++ }
                out += span(C_STR, esc(src.substring(i, j3))); i = j3; continue
            }
            // ── number literal
            if (ch >= '0' && ch <= '9') {
                var j4 = i
                while (j4 < n && /[\w.]/.test(src[j4])) j4++
                out += span(C_NUM, esc(src.substring(i, j4))); i = j4; continue
            }
            // ── identifier / keyword / type / function-call
            if (/[a-zA-Z_]/.test(ch)) {
                var j5 = i
                while (j5 < n && /\w/.test(src[j5])) j5++
                var word  = src.substring(i, j5)
                var after = j5
                while (after < n && (src[after] === ' ' || src[after] === '\t')) after++
                if (kwSet[word]) {
                    out += span(C_KW, esc(word))
                } else if (after < n && src[after] === '(') {
                    out += span(C_FUNC, esc(word))
                } else if (word.length > 0 && word[0] >= 'A' && word[0] <= 'Z') {
                    out += span(C_TYPE, esc(word))
                } else {
                    out += esc(word)
                }
                i = j5; continue
            }
            // ── everything else (operators, punctuation, whitespace, newlines)
            out += esc(ch); i++
        }

        return out
    }

    implicitWidth:  400
    implicitHeight: Math.min(
        (root.maxHeight > 0 ? root.maxHeight : 9999),
        _scroll.contentHeight + _header.height + 2
    )

    Rectangle {
        anchors.fill: parent
        color: root.bgColor
        border.color: root.borderColor; border.width: 1; radius: 6; clip: true

        // ── Header bar ────────────────────────────────────────────────────────
        Rectangle {
            id: _header
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 34
            color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.05)
            z: 2

            Text {
                anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                text: root.language !== "" ? root.language.toLowerCase() : "code"
                font.pixelSize: 11; color: ThemeManager.textSecondaryColor; opacity: 0.7
                font.family: "monospace"
            }

            Rectangle {
                id: copyBtn
                visible: root.showCopyButton
                anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                width: copyTxt.implicitWidth + 20; height: 24; radius: 4
                color: copyMa.containsMouse
                       ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.18)
                       : Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.08)
                border.color: ThemeManager.borderColor; border.width: 1
                Behavior on color { ColorAnimation { duration: 80 } }

                Text {
                    id: copyTxt; anchors.centerIn: parent
                    text: _copied ? "✓ Copied" : "⎘ Copy"
                    font.pixelSize: 10; color: _copied ? ThemeManager.successColor : ThemeManager.textSecondaryColor
                }

                property bool _copied: false
                MouseArea {
                    id: copyMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        // Copy to clipboard via TextEdit trick
                        _clipHelper.text = root.code
                        _clipHelper.selectAll()
                        _clipHelper.copy()
                        copyBtn._copied = true
                        _copyTimer.restart()
                    }
                }
                Timer {
                    id: _copyTimer; interval: 1800
                    onTriggered: copyBtn._copied = false
                }
            }

            Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 1; color: root.borderColor; opacity: 0.4 }
        }

        // Hidden TextEdit for clipboard
        TextEdit {
            id: _clipHelper; visible: false; width: 0; height: 0
        }

        // ── Code area ─────────────────────────────────────────────────────────
        ScrollView {
            id: _scroll
            anchors { top: _header.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
            clip: true
            ScrollBar.horizontal.policy: ScrollBar.AsNeeded
            ScrollBar.vertical.policy:   ScrollBar.AsNeeded

            Text {
                leftPadding: 14; rightPadding: 14; topPadding: 12; bottomPadding: 12
                text: root.language !== "" ? root._highlight(root.code, root.language) : root.code
                font.family: "Consolas, monospace"
                font.pixelSize: root.fontSize
                color: root.textColor          // default colour for un-spanned tokens
                wrapMode: root.wrapText ? Text.Wrap : Text.NoWrap
                lineHeight: 1.5
                textFormat: root.language !== "" ? Text.RichText : Text.PlainText
            }
        }
    }
}
