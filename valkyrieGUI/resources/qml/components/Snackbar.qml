import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0

// Snackbar — brief notification bar with optional action button.
// Automatically dismisses after `duration` ms.
//
// Usage:
//   Snackbar { id: snack }
//   snack.show("File saved!", "Undo", "success")
//   snack.onActionClicked: undoSave()
Popup {
    id: root

    property string message:     ""
    property string actionLabel: ""
    property int    duration:    3000
    property string type:        "info"   // info | success | warning | danger
    property color  accentColor: _typeColor
    property int    maxWidth:    480

    signal actionClicked()
    signal dismissed()

    readonly property color _typeColor: {
        switch (root.type) {
        case "success": return ThemeManager.successColor
        case "warning": return ThemeManager.warningColor
        case "danger":  return ThemeManager.dangerColor
        default:        return ThemeManager.primaryColor
        }
    }

    function show(msg, action, t) {
        root.message     = msg     || ""
        root.actionLabel = action  || ""
        root.type        = t       || "info"
        _timer.restart()
        root.open()
    }

    // Position: bottom centre of the window overlay
    parent: Overlay.overlay           // makes x/y relative to full window overlay
    x: parent ? Math.round((parent.width - root.width) / 2) : 0
    y: parent ? parent.height - root.height - 24 : 0

    width:   Math.min(Math.max(contentRow.implicitWidth + 32, 260), root.maxWidth)
    height:  52
    padding: 0

    closePolicy: Popup.NoAutoClose
    modal: false

    enter: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
        NumberAnimation { property: "y"; from: root.y + 48; to: root.y; duration: 220; easing.type: Easing.OutCubic }
    }
    exit: Transition {
        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 180 }
    }

    background: Rectangle {
        radius: 8; color: ThemeManager.surfaceColor
        border.color: root.accentColor; border.width: 1

        // Left accent strip
        Rectangle { width: 4; height: parent.height; radius: 8; color: root.accentColor }
    }

    contentItem: Row {
        id: contentRow
        anchors { left: parent.left; right: parent.right; leftMargin: 18; rightMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 12

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.message
            font.pixelSize: 13; color: ThemeManager.textColor
            elide: Text.ElideRight
            width: parent.width - (root.actionLabel ? actionBtn.width + 12 : 0) - 20
        }

        Rectangle {
            id: actionBtn
            visible: root.actionLabel !== ""
            anchors.verticalCenter: parent.verticalCenter
            width: actionTxt.implicitWidth + 20; height: 28; radius: 5
            color: actMa.containsMouse ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.18) : "transparent"
            border.color: root.accentColor; border.width: 1
            Behavior on color { ColorAnimation { duration: 80 } }
            Text {
                id: actionTxt; anchors.centerIn: parent; text: root.actionLabel
                font.pixelSize: 12; font.bold: true; color: root.accentColor
            }
            MouseArea {
                id: actMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: { root.actionClicked(); root.close() }
            }
        }
    }

    Timer {
        id: _timer; interval: root.duration
        onTriggered: { root.dismissed(); root.close() }
    }
}

