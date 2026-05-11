// Global ToolTip style override — shadows the default Material/Qaterial tooltip.
// Loaded automatically because QMLWindow adds "qrc:///" to the engine's import
// paths, and this file sits at qrc:/QtQuick/Controls.2/ToolTip.qml, which the
// QQC2 resolver checks before the compiled-in style QML files.
import QtQuick 2.15
import QtQuick.Templates 2.15 as T
import App.Theme 1.0

T.ToolTip {
    id: control

    // Center above/below the parent item (QQC2 default behaviour)
    x: parent ? (parent.width - implicitWidth) / 2 : 0
    y: -implicitHeight - 8

    implicitWidth:  Math.max(implicitBackgroundWidth  + leftInset  + rightInset,
                             contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset   + bottomInset,
                             contentHeight + topPadding + bottomPadding)

    margins:          4
    horizontalPadding: 10
    verticalPadding:    5

    closePolicy: T.Popup.CloseOnEscape | T.Popup.CloseOnPressOutsideParent

    // ── Content ────────────────────────────────────────────────────────────
    contentItem: Text {
        text:     control.text
        font:     control.font
        color:    ThemeManager.textColor
        wrapMode: Text.Wrap
    }

    // ── Background ─────────────────────────────────────────────────────────
    background: Rectangle {
        color:        ThemeManager.surfaceColor
        border.color: Qt.rgba(ThemeManager.borderColor.r,
                              ThemeManager.borderColor.g,
                              ThemeManager.borderColor.b, 0.7)
        border.width: 1
        radius:       4
    }

    // ── Fade transitions ───────────────────────────────────────────────────
    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 80; easing.type: Easing.OutCubic }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 60; easing.type: Easing.InCubic }
    }
}

