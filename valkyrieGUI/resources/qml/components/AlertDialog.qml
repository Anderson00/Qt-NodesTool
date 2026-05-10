import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import App.Theme 1.0

// AlertDialog — modal dialog with title, body and confirm/cancel actions.
//
// Usage:
//   AlertDialog {
//       id: dlg
//       title: "Delete item?"
//       message: "This action cannot be undone."
//       type: "danger"          // "info" | "warning" | "danger" | "success"
//       confirmLabel: "Delete"
//       onConfirmed: doDelete()
//   }
//   // Open: dlg.open()  Close: dlg.close()
Dialog {
    id: root

    // Dialog.title is FINAL — set directly, do not redeclare
    title:                "Alert"
    property string message:      ""
    property string type:         "info"   // info | warning | danger | success
    property string confirmLabel: "OK"
    property string cancelLabel:  "Cancel"
    property bool   showCancel:   true

    signal confirmed()
    signal cancelled()

    readonly property color _accentColor: {
        switch (root.type) {
        case "warning": return ThemeManager.warningColor
        case "danger":  return ThemeManager.dangerColor
        case "success": return ThemeManager.successColor
        default:        return ThemeManager.primaryColor
        }
    }

    readonly property string _icon: {
        switch (root.type) {
        case "warning": return "⚠"
        case "danger":  return "✕"
        case "success": return "✓"
        default:        return "ℹ"
        }
    }

    modal: true
    anchors.centerIn: Overlay.overlay
    padding: 0
    closePolicy: Popup.CloseOnEscape

    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.45)
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    enter:  Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 160; easing.type: Easing.OutCubic } }
    exit:   Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 120 } }

    background: Rectangle {
        radius: 10; color: ThemeManager.surfaceColor
        border.color: root._accentColor; border.width: 1
        layer.enabled: true
        layer.effect: null   // shadow via drop shadow below
        Rectangle { anchors.fill: parent; radius: parent.radius; color: "transparent"
                    border.color: Qt.rgba(0,0,0,0.25); border.width: 1 }
    }

    contentItem: ColumnLayout {
        spacing: 0
        width: 360

        // ── Top accent strip ──────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true; height: 4
            radius: 10
            color: root._accentColor
            // Only round top corners
            Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 4; color: parent.color }
        }

        // ── Body ──────────────────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.margins: 24
            spacing: 14

            // Icon + title row
            RowLayout {
                spacing: 12
                Rectangle {
                    width: 36; height: 36; radius: 18
                    color: Qt.rgba(root._accentColor.r, root._accentColor.g, root._accentColor.b, 0.15)
                    Text { anchors.centerIn: parent; text: root._icon; font.pixelSize: 18; color: root._accentColor }
                }
                Text {
                    Layout.fillWidth: true
                    text: root.title
                    font.pixelSize: 16; font.bold: true
                    color: ThemeManager.textColor; wrapMode: Text.Wrap
                }
            }

            // Message
            Text {
                Layout.fillWidth: true
                text: root.message
                font.pixelSize: 13; color: ThemeManager.textSecondaryColor
                wrapMode: Text.Wrap; lineHeight: 1.45
            }
        }

        // ── Buttons ───────────────────────────────────────────────────────────
        Rectangle { Layout.fillWidth: true; height: 1; color: ThemeManager.borderColor; opacity: 0.4 }

        RowLayout {
            Layout.fillWidth: true; Layout.margins: 16; spacing: 10

            Item { Layout.fillWidth: true }

            // Cancel
            Rectangle {
                visible: root.showCancel
                width: cancelTxt.implicitWidth + 32; height: 34; radius: 6
                color: cancelMa.containsMouse
                       ? Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.08)
                       : "transparent"
                border.color: ThemeManager.borderColor; border.width: 1
                Behavior on color { ColorAnimation { duration: 80 } }
                Text {
                    id: cancelTxt; anchors.centerIn: parent; text: root.cancelLabel
                    font.pixelSize: 13; color: ThemeManager.textColor
                }
                MouseArea {
                    id: cancelMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { root.cancelled(); root.close() }
                }
            }

            // Confirm
            Rectangle {
                width: confirmTxt.implicitWidth + 32; height: 34; radius: 6
                color: confirmMa.containsMouse ? Qt.darker(root._accentColor, 1.15) : root._accentColor
                Behavior on color { ColorAnimation { duration: 80 } }
                Text {
                    id: confirmTxt; anchors.centerIn: parent; text: root.confirmLabel
                    font.pixelSize: 13; font.bold: true; color: "#FFFFFF"
                }
                MouseArea {
                    id: confirmMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { root.confirmed(); root.close() }
                }
            }
        }
    }
}
