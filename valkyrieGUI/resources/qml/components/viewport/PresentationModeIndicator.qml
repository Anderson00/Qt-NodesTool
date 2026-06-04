import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0

import ".."

Rectangle {
    id: root

    property int  mode: 1
    property bool active: true

    signal exitRequested()

    readonly property color modeColor: {
        if (mode === 1) return ThemeManager.primaryColor
        if (mode === 2) return ThemeManager.warningColor
        return ThemeManager.textColor
    }
    readonly property string modeLabel: {
        if (mode === 1) return qsTr("Quiet Mode")
        if (mode === 2) return qsTr("Locked Mode")
        return ""
    }

    width:  indicatorRow.implicitWidth + 24
    height: 32
    radius: 16
    color:  Qt.rgba(0, 0, 0, 0.65)
    border.width: 1
    border.color: Qt.rgba(modeColor.r, modeColor.g, modeColor.b, 0.55)
    opacity: active ? 1.0 : 0.0
    Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

    Row {
        id: indicatorRow
        anchors.centerIn: parent
        spacing: 8
        leftPadding: 4
        rightPadding: 4

        Rectangle {
            width: 8; height: 8; radius: 4
            color: root.modeColor
            anchors.verticalCenter: parent.verticalCenter
            SequentialAnimation on opacity {
                running: root.visible
                loops:   Animation.Infinite
                NumberAnimation { from: 0.5; to: 1.0; duration: 900 }
                NumberAnimation { from: 1.0; to: 0.5; duration: 900 }
            }
        }
        Text {
            text: root.modeLabel
            color: "white"
            font.pixelSize: 11
            font.weight: Font.Bold
            anchors.verticalCenter: parent.verticalCenter
        }
        Rectangle {
            width: 1; height: 14
            color: Qt.rgba(1, 1, 1, 0.2)
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: "F10"
            color: Qt.rgba(1, 1, 1, 0.75)
            font.pixelSize: 10
            font.family: "monospace"
            anchors.verticalCenter: parent.verticalCenter
            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: 3
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.4)
                z: -1
            }
        }
        Text {
            text: qsTr("to exit")
            color: Qt.rgba(1, 1, 1, 0.5)
            font.pixelSize: 10
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.exitRequested()
    }
}
