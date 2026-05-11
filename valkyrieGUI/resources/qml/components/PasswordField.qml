import QtQuick 2.15
import QtQuick.Controls 2.15
import App.Theme 1.0

TextField {
    id: control

    property color accentColor: ThemeManager.primaryColor
    property color backgroundColor: Qt.rgba(1, 1, 1, 0.06)
    property color borderColor: Qt.rgba(1, 1, 1, 0.18)
    property bool showStrength: false
    property bool revealed: false
    property int radius: 6

    // 0..4 strength score
    readonly property int strength: {
        var s = 0
        if (length >= 8) s++
        if (/[A-Z]/.test(text) && /[a-z]/.test(text)) s++
        if (/\d/.test(text)) s++
        if (/[^A-Za-z0-9]/.test(text)) s++
        return s
    }
    readonly property color strengthColor: {
        switch (strength) {
            case 0: return Qt.rgba(1, 1, 1, 0.15)
            case 1: return "#e74c3c"
            case 2: return "#e67e22"
            case 3: return "#f1c40f"
            default: return "#2ecc71"
        }
    }

    echoMode: revealed ? TextInput.Normal : TextInput.Password
    passwordMaskDelay: 600
    font.pixelSize: 13
    implicitHeight: 36
    leftPadding: 12
    rightPadding: 40
    color: ThemeManager.textColor
    selectionColor: accentColor
    selectedTextColor: "#ffffff"
    placeholderText: qsTr("Password")
    placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)

    background: Rectangle {
        radius: control.radius
        color: control.backgroundColor
        border.width: 1
        border.color: control.activeFocus || control.hovered
                      ? control.accentColor
                      : control.borderColor
        Behavior on border.color { ColorAnimation { duration: 120 } }

        // Strength bar
        Row {
            visible: control.showStrength && control.text.length > 0
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            anchors.bottomMargin: 2
            spacing: 2
            Repeater {
                model: 4
                Rectangle {
                    width: (parent.width - 6) / 4
                    height: 2
                    radius: 1
                    color: index < control.strength
                           ? control.strengthColor
                           : Qt.rgba(1, 1, 1, 0.08)
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }
    }

    // Eye toggle
    Item {
        width: 28
        height: 28
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: control.revealed = !control.revealed
        }

        // Simple eye glyph using shapes
        Rectangle {
            anchors.centerIn: parent
            width: 18; height: 12
            radius: 6
            color: "transparent"
            border.width: 1.5
            border.color: ThemeManager.textColor
            opacity: 0.8
            Rectangle {
                anchors.centerIn: parent
                width: 5; height: 5; radius: 2.5
                color: ThemeManager.textColor
                visible: control.revealed
            }
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 6
                height: 1.5
                color: ThemeManager.textColor
                rotation: -25
                visible: !control.revealed
            }
        }
    }
}

