import QtQuick 2.12
import App.Theme 1.0
import Qaterial as Qaterial

// Usage: place as a child, call toast.show(message, type)
// Types: "success" | "error" | "warning" | "info"
Item {
    id: root

    property string message:   ""
    property string toastType: "info"

    function show(msg, typ) {
        message   = msg
        toastType = typ || "info"
        _showAnim.restart()
        _hideTimer.restart()
    }

    readonly property color _typeColor: {
        if (toastType === "success") return ThemeManager.successColor
        if (toastType === "error")   return ThemeManager.dangerColor
        if (toastType === "warning") return ThemeManager.warningColor
        return ThemeManager.primaryColor
    }
    readonly property string _typeIcon: {
        if (toastType === "success") return Qaterial.Icons.checkCircleOutline
        if (toastType === "error")   return Qaterial.Icons.alertCircleOutline
        if (toastType === "warning") return Qaterial.Icons.alertOutline
        return Qaterial.Icons.informationOutline
    }

    implicitWidth:  _bg.implicitWidth
    implicitHeight: _bg.implicitHeight
    opacity: 0

    Rectangle {
        id: _bg
        implicitWidth:  _row.implicitWidth + 52
        implicitHeight: 48
        radius: 8

        color:        ThemeManager.surfaceColor
        border.color: Qt.rgba(root._typeColor.r,
                               root._typeColor.g,
                               root._typeColor.b, 0.35)
        border.width: 1

        // Left accent strip
        Rectangle {
            width:  3
            height: parent.height * 0.55
            radius: 2
            anchors.left:           parent.left
            anchors.leftMargin:     1
            anchors.verticalCenter: parent.verticalCenter
            color: root._typeColor
        }

        Row {
            id: _row
            anchors.verticalCenter: parent.verticalCenter
            anchors.left:           parent.left
            anchors.leftMargin:     20
            spacing: 10

            Qaterial.ColorIcon {
                source: root._typeIcon
                color:  root._typeColor
                width: 16; height: 16
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text:           root.message
                color:          ThemeManager.textColor
                font.pixelSize: 13
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    transform: Translate {
        id: _slide
        y: 8
    }

    SequentialAnimation {
        id: _showAnim
        ParallelAnimation {
            NumberAnimation { target: root;   property: "opacity"; from: 0; to: 1; duration: 210; easing.type: Easing.OutCubic }
            NumberAnimation { target: _slide; property: "y";       from: 8; to: 0; duration: 210; easing.type: Easing.OutCubic }
        }
    }

    Timer {
        id: _hideTimer
        interval: 3200
        onTriggered: _hideAnim.start()
    }

    SequentialAnimation {
        id: _hideAnim
        ParallelAnimation {
            NumberAnimation { target: root;   property: "opacity"; to: 0; duration: 260; easing.type: Easing.InCubic }
            NumberAnimation { target: _slide; property: "y";       to: 8; duration: 260; easing.type: Easing.InCubic }
        }
    }
}
