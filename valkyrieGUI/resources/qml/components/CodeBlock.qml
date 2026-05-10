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
                text: root.code
                font.family: "Consolas, monospace"
                font.pixelSize: root.fontSize
                color: root.textColor
                wrapMode: root.wrapText ? Text.Wrap : Text.NoWrap
                lineHeight: 1.5
                textFormat: Text.PlainText
            }
        }
    }
}
