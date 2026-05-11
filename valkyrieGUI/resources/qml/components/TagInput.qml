import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import App.Theme 1.0

Item {
    id: root

    property var tags: []
    property string placeholderText: qsTr("Add tag...")
    property color accentColor: ThemeManager.primaryColor
    property color backgroundColor: Qt.rgba(1, 1, 1, 0.06)
    property color borderColor: Qt.rgba(1, 1, 1, 0.18)
    property color tagColor: Qt.rgba(ThemeManager.primaryColor.r,
                                     ThemeManager.primaryColor.g,
                                     ThemeManager.primaryColor.b, 0.25)
    property int radius: 6
    property bool allowDuplicates: false

    signal tagAdded(string tag)
    signal tagRemoved(string tag, int index)

    implicitHeight: Math.max(40, flow.implicitHeight + 12)
    implicitWidth: 200

    function addTag(text) {
        var t = text.trim()
        if (t.length === 0) return false
        if (!allowDuplicates && tags.indexOf(t) !== -1) return false
        var copy = tags.slice()
        copy.push(t)
        tags = copy
        tagAdded(t)
        return true
    }

    function removeTagAt(index) {
        if (index < 0 || index >= tags.length) return
        var removed = tags[index]
        var copy = tags.slice()
        copy.splice(index, 1)
        tags = copy
        tagRemoved(removed, index)
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.backgroundColor
        border.width: 1
        border.color: input.activeFocus ? root.accentColor : root.borderColor
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Flow {
            id: flow
            anchors.fill: parent
            anchors.margins: 6
            spacing: 6

            Repeater {
                model: root.tags
                delegate: Rectangle {
                    height: 24
                    radius: 12
                    color: root.tagColor
                    width: tagRow.implicitWidth + 16

                    Row {
                        id: tagRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: modelData
                            color: ThemeManager.textColor
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            width: 14; height: 14; radius: 7
                            color: "transparent"
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                color: ThemeManager.textColor
                                font.pixelSize: 14
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.removeTagAt(index)
                            }
                        }
                    }
                }
            }

            TextField {
                id: input
                width: Math.max(80, flow.width - x - 4)
                height: 24
                placeholderText: root.placeholderText
                placeholderTextColor: Qt.rgba(1, 1, 1, 0.4)
                color: ThemeManager.textColor
                font.pixelSize: 12
                selectionColor: root.accentColor
                selectedTextColor: "#ffffff"
                background: Item {}

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Return ||
                        event.key === Qt.Key_Enter ||
                        event.key === Qt.Key_Comma) {
                        if (root.addTag(text)) text = ""
                        event.accepted = true
                    } else if (event.key === Qt.Key_Backspace && text.length === 0) {
                        root.removeTagAt(root.tags.length - 1)
                    }
                }
            }
        }
    }
}

