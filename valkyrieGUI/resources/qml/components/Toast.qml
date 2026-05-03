import QtQuick 2.12
import App.Theme 1.0
import App.Toast 1.0
import Qaterial as Qaterial

// Toast display driven by ToastManager singleton
// Usage from C++: ToastManager::instance()->show("message", "type")
// Usage from QML: ToastManager.show("message", "type")
Item {
    id: root

    implicitWidth:  _bg.implicitWidth
    implicitHeight: _bg.implicitHeight
    opacity: ToastManager.visible ? 1.0 : 0.0

    readonly property color _typeColor: {
        if (ToastManager.type === "success") return ThemeManager.successColor
        if (ToastManager.type === "error")   return ThemeManager.dangerColor
        if (ToastManager.type === "warning") return ThemeManager.warningColor
        return ThemeManager.primaryColor
    }
    readonly property string _typeIcon: {
        if (ToastManager.type === "success") return Qaterial.Icons.checkCircleOutline
        if (ToastManager.type === "error")   return Qaterial.Icons.alertCircleOutline
        if (ToastManager.type === "warning") return Qaterial.Icons.alertOutline
        return Qaterial.Icons.informationOutline
    }

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
                text:           ToastManager.message
                color:          ThemeManager.textColor
                font.pixelSize: 13
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    transform: Translate {
        id: _slide
        y: root.opacity === 1.0 ? 0 : 8
        Behavior on y { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: root.opacity === 1.0 ? 210 : 260
            easing.type: root.opacity === 1.0 ? Easing.OutCubic : Easing.InCubic
        }
    }
}
