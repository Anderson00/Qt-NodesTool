import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import App.Icons 1.0

Item {
    id: root

    property real   value:     0
    property real   from:     -1e9
    property real   to:        1e9
    property real   stepSize:  1.0
    property int    decimals:  2
    property string label:     ""
    property string suffix:    ""
    property color  accentColor: ThemeManager.primaryColor
    property bool   showBar:   false

    signal valueModified(real newValue)

    implicitHeight: 36

    function _clamp(v) {
        return Math.max(root.from, Math.min(root.to, v))
    }

    function applyStep(mul) {
        var raw = parseFloat(field.text)
        if (isNaN(raw)) raw = root.value
        var nv = _clamp(raw + root.stepSize * mul)
        root.value = nv
        field.text = nv.toFixed(root.decimals)
        root.valueModified(nv)
    }

    function commitText() {
        var v = parseFloat(field.text)
        if (!isNaN(v)) {
            var nv = _clamp(v)
            root.value = nv
            field.text = nv.toFixed(root.decimals)
            root.valueModified(nv)
        } else {
            field.text = root.value.toFixed(root.decimals)
        }
    }

    onValueChanged: {
        if (!field.activeFocus)
            field.text = value.toFixed(root.decimals)
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            visible: root.label !== ""
            Layout.preferredWidth: 28
            Layout.fillHeight: true
            radius: 4
            color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.15)

            Text {
                anchors.centerIn: parent
                text: root.label
                font.pixelSize: 10
                font.bold: true
                color: root.accentColor
            }
        }

        Item { Layout.preferredWidth: root.label !== "" ? 3 : 0 }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 4
            clip: true
            color: field.activeFocus
                   ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.08)
                   : Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.06)
            border.width: 1
            border.color: field.activeFocus
                          ? root.accentColor
                          : Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.35)

            Behavior on border.color { ColorAnimation { duration: 100 } }
            Behavior on color        { ColorAnimation { duration: 100 } }

            Rectangle {
                visible: root.showBar && root.from > -1e8 && root.to < 1e8
                anchors { left: parent.left; bottom: parent.bottom }
                height: 2; radius: 1
                color: root.accentColor; opacity: 0.5
                width: {
                    var range = root.to - root.from
                    return range > 0
                           ? parent.width * Math.max(0, Math.min(1, (root.value - root.from) / range))
                           : 0
                }
                Behavior on width { NumberAnimation { duration: 80 } }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 2
                spacing: 2

                TextInput {
                    id: field
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: TextInput.AlignVCenter
                    horizontalAlignment: TextInput.AlignHCenter
                    font.pixelSize: 13
                    font.family: "Consolas"
                    color: ThemeManager.textColor
                    selectionColor: root.accentColor
                    selectedTextColor: "#fff"
                    selectByMouse: true
                    text: root.value.toFixed(root.decimals)

                    onAccepted:       root.commitText()
                    onEditingFinished: root.commitText()
                }

                Text {
                    visible: root.suffix !== ""
                    text: root.suffix
                    font.pixelSize: 9
                    color: ThemeManager.textSecondaryColor
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: 2
                }

                Column {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    Rectangle {
                        width: 18; height: 17; radius: 2
                        color: upMa.containsMouse
                               ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25)
                               : "transparent"
                        Behavior on color { ColorAnimation { duration: 80 } }
                        SvgIcon {
                            anchors.centerIn: parent
                            width: 12; height: 12
                            source: Icons.chevronUp
                            color: upMa.containsMouse ? root.accentColor : ThemeManager.textSecondaryColor
                        }
                        MouseArea {
                            id: upMa
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.applyStep(1)
                        }
                    }
                    Rectangle {
                        width: 18; height: 17; radius: 2
                        color: dnMa.containsMouse
                               ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25)
                               : "transparent"
                        Behavior on color { ColorAnimation { duration: 80 } }
                        SvgIcon {
                            anchors.centerIn: parent
                            width: 12; height: 12
                            source: Icons.chevronDown
                            color: dnMa.containsMouse ? root.accentColor : ThemeManager.textSecondaryColor
                        }
                        MouseArea {
                            id: dnMa
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.applyStep(-1)
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function(wheel) {
            var mul = 1
            if (wheel.modifiers & Qt.ShiftModifier)   mul = 10
            if (wheel.modifiers & Qt.ControlModifier)  mul = 100
            root.applyStep(wheel.angleDelta.y > 0 ? mul : -mul)
        }
    }
}

