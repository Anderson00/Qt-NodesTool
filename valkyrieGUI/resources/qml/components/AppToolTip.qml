// Themed tooltip that follows ThemeManager colors.
//
// Why a custom component instead of overriding qrc:/QtQuick/Controls.2/ToolTip.qml:
// Qaterial/Material loads its ToolTip from the compiled plugin (DLL) internal
// resources, not from the engine's import path. The only reliable override is
// to set `background` and `contentItem` on an individual ToolTip instance —
// which QQC2 always respects, regardless of the active style.
//
// Usage (replaces ToolTip.text / ToolTip.visible / ToolTip.delay pattern):
//   SomeButton {
//       AppToolTip { text: "My label"; visible: parent.hovered; delay: 500 }
//   }
//   MouseArea {
//       AppToolTip { text: "My label"; visible: parent.containsMouse }
//   }
import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0

ToolTip {
    id: control

    // Default delay to match the app's existing 500 ms convention
    delay: 500

    // Center above the parent item
    x: parent ? (parent.width - implicitWidth) / 2 : 0
    y: -implicitHeight - 6

    horizontalPadding: 10
    verticalPadding:    5

    // ── Themed content ──────────────────────────────────────────────────────
    contentItem: Text {
        text:     control.text
        font:     control.font
        color:    ThemeManager.textColor
        wrapMode: Text.Wrap
    }

    // ── Themed background ──────────────────────────────────────────────────
    background: Rectangle {
        color:        ThemeManager.surfaceColor
        border.color: Qt.rgba(ThemeManager.borderColor.r,
                              ThemeManager.borderColor.g,
                              ThemeManager.borderColor.b, 0.7)
        border.width: 1
        radius:       4
    }

    enter: Transition { NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 80; easing.type: Easing.OutCubic } }
    exit:  Transition { NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 60; easing.type: Easing.InCubic } }
}

