import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.14
import QtQuick.Window 2.2
import QtQuick 2.14
import QtQml 2.14

import Qaterial 1.0 as Qaterial

import App.Theme 1.0

import '../'

Drawer {
    id: root

    property QtObject viewPortWindow
    property var selectedObjectView

    width: 280
    height: parent.height
    modal: false
    edge: Qt.RightEdge
    interactive: false
    visible: selectedObjectView !== null && selectedObjectView !== undefined

    background: Rectangle {
        color: Qt.rgba(ThemeManager.surfaceColor.r,
                      ThemeManager.surfaceColor.g,
                      ThemeManager.surfaceColor.b, 0.15)
        border.width: 1
        border.color: Qt.rgba(ThemeManager.primaryColor.r,
                             ThemeManager.primaryColor.g,
                             ThemeManager.primaryColor.b, 0.2)
    }

    onSelectedObjectViewChanged: {
        if (selectedObjectView) {
            name.text = selectedObjectView.behaviourObject.title
            updateValues()
            updateConnectionsList()
        }
    }

    function updateConnectionsList() {
        if (selectedObjectView && viewPortWindow) {
            var nodeUuid = viewPortWindow.getUUIDFromBehaviour(selectedObjectView.behaviourObject);
            connsRepeater.model = viewPortWindow.getNodeConnections(nodeUuid);
        } else {
            connsRepeater.model = []
        }
    }

    function updateValues() {
        if (selectedObjectView && viewPortWindow) {
            posXVal.text = Math.round(selectedObjectView.x - 5000)
            posYVal.text = Math.round(selectedObjectView.y - 5000)
            widthVal.text = Math.round(selectedObjectView.width)
            heightVal.text = Math.round(selectedObjectView.height)
            zVal.text = selectedObjectView.z
        }
    }

    Connections {
        target: selectedObjectView

        function onXChanged() {
            updateValues()
        }

        function onYChanged() {
            updateValues()
        }

        function onWidthChanged() {
            updateValues()
        }

        function onHeightChanged() {
            updateValues()
        }

        function onZChanged() {
            updateValues()
        }
    }

        function clamp(value, min, max) {
        return Math.max(min, Math.min(max, value))
    }

    Connections {
        target: viewPortWindow
        function onConnectionAdded() { updateConnectionsList() }
        function onConnectionRemoved() { updateConnectionsList() }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // Header with node title
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            radius: 8
            color: Qt.rgba(ThemeManager.primaryColor.r,
                          ThemeManager.primaryColor.g,
                          ThemeManager.primaryColor.b, 0.15)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.primaryColor.r,
                                 ThemeManager.primaryColor.g,
                                 ThemeManager.primaryColor.b, 0.3)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 2

                Text {
                    text: "Selected Node"
                    font.pixelSize: 10
                    font.bold: true
                    color: ThemeManager.textSecondaryColor
                    opacity: 0.7
                }

                Text {
                    id: name
                    text: ""
                    font.pixelSize: 14
                    font.bold: true
                    color: ThemeManager.primaryColor
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        // Position section
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            radius: 6
            color: Qt.rgba(ThemeManager.backgroundColor.r,
                          ThemeManager.backgroundColor.g,
                          ThemeManager.backgroundColor.b, 0.4)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Text {
                    text: "Position (relative to center)"
                    font.pixelSize: 11
                    font.bold: true
                    color: ThemeManager.textSecondaryColor
                    opacity: 0.7
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        radius: 4
                        color: Qt.rgba(ThemeManager.primaryColor.r,
                                      ThemeManager.primaryColor.g,
                                      ThemeManager.primaryColor.b, 0.08)
                        border.width: 1
                        border.color: Qt.rgba(ThemeManager.primaryColor.r,
                                             ThemeManager.primaryColor.g,
                                             ThemeManager.primaryColor.b, 0.2)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 3

                            Text {
                                text: "X"
                                font.pixelSize: 9
                                color: ThemeManager.textSecondaryColor
                                opacity: 0.7
                            }

                            Text {
                                id: posXVal
                                text: "0"
                                font.pixelSize: 16
                                font.bold: true
                                color: ThemeManager.primaryColor
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        radius: 4
                        color: Qt.rgba(ThemeManager.primaryColor.r,
                                      ThemeManager.primaryColor.g,
                                      ThemeManager.primaryColor.b, 0.08)
                        border.width: 1
                        border.color: Qt.rgba(ThemeManager.primaryColor.r,
                                             ThemeManager.primaryColor.g,
                                             ThemeManager.primaryColor.b, 0.2)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 3

                            Text {
                                text: "Y"
                                font.pixelSize: 9
                                color: ThemeManager.textSecondaryColor
                                opacity: 0.7
                            }

                            Text {
                                id: posYVal
                                text: "0"
                                font.pixelSize: 16
                                font.bold: true
                                color: ThemeManager.primaryColor
                            }
                        }
                    }
                }
            }
        }

        // Size section
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            radius: 6
            color: Qt.rgba(ThemeManager.backgroundColor.r,
                          ThemeManager.backgroundColor.g,
                          ThemeManager.backgroundColor.b, 0.4)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Text {
                    text: "Size"
                    font.pixelSize: 11
                    font.bold: true
                    color: ThemeManager.textSecondaryColor
                    opacity: 0.7
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        radius: 4
                        color: Qt.rgba(ThemeManager.successColor.r,
                                      ThemeManager.successColor.g,
                                      ThemeManager.successColor.b, 0.08)
                        border.width: 1
                        border.color: Qt.rgba(ThemeManager.successColor.r,
                                             ThemeManager.successColor.g,
                                             ThemeManager.successColor.b, 0.2)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 3

                            Text {
                                text: "Width"
                                font.pixelSize: 9
                                color: ThemeManager.textSecondaryColor
                                opacity: 0.7
                            }

                            Text {
                                id: widthVal
                                text: "0"
                                font.pixelSize: 16
                                font.bold: true
                                color: ThemeManager.successColor
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        radius: 4
                        color: Qt.rgba(ThemeManager.successColor.r,
                                      ThemeManager.successColor.g,
                                      ThemeManager.successColor.b, 0.08)
                        border.width: 1
                        border.color: Qt.rgba(ThemeManager.successColor.r,
                                             ThemeManager.successColor.g,
                                             ThemeManager.successColor.b, 0.2)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 3

                            Text {
                                text: "Height"
                                font.pixelSize: 9
                                color: ThemeManager.textSecondaryColor
                                opacity: 0.7
                            }

                            Text {
                                id: heightVal
                                text: "0"
                                font.pixelSize: 16
                                font.bold: true
                                color: ThemeManager.successColor
                            }
                        }
                    }
                }
            }
        }

        // Z-index section
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            radius: 6
            color: Qt.rgba(ThemeManager.warningColor.r,
                          ThemeManager.warningColor.g,
                          ThemeManager.warningColor.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.warningColor.r,
                                 ThemeManager.warningColor.g,
                                 ThemeManager.warningColor.b, 0.2)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Z-Index (Layer)"
                        font.pixelSize: 10
                        font.bold: true
                        color: ThemeManager.textSecondaryColor
                        opacity: 0.6
                    }

                    Text {
                        id: zVal
                        text: "0"
                        font.pixelSize: 12
                        font.bold: true
                        color: ThemeManager.warningColor
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 28
                    radius: 4
                    color: Qt.rgba(ThemeManager.primaryColor.r,
                                  ThemeManager.primaryColor.g,
                                  ThemeManager.primaryColor.b, 0.2)

                    Text {
                        anchors.centerIn: parent
                        text: "Front"
                        font.pixelSize: 10
                        color: ThemeManager.textColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: selectedObjectView.z += 1
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 60
                    Layout.preferredHeight: 28
                    radius: 4
                    color: Qt.rgba(ThemeManager.primaryColor.r,
                                  ThemeManager.primaryColor.g,
                                  ThemeManager.primaryColor.b, 0.2)

                    Text {
                        anchors.centerIn: parent
                        text: "Back"
                        font.pixelSize: 10
                        color: ThemeManager.textColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: selectedObjectView.z = Math.max(0, selectedObjectView.z - 1)
                    }
                }
            }
        }

        // Connections section
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            radius: 6
            color: Qt.rgba(ThemeManager.backgroundColor.r,
                          ThemeManager.backgroundColor.g,
                          ThemeManager.backgroundColor.b, 0.4)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Text {
                    text: "Connections"
                    font.pixelSize: 11
                    font.bold: true
                    color: ThemeManager.textSecondaryColor
                    opacity: 0.7
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                    ColumnLayout {
                        width: parent.width
                        spacing: 6

                        Repeater {
                            id: connsRepeater
                            model: []

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 46
                                radius: 4
                                color: Qt.rgba(ThemeManager.surfaceColor.r,
                                              ThemeManager.surfaceColor.g,
                                              ThemeManager.surfaceColor.b, 0.4)
                                border.width: 1
                                border.color: Qt.rgba(ThemeManager.primaryColor.r,
                                                     ThemeManager.primaryColor.g,
                                                     ThemeManager.primaryColor.b, 0.2)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 4

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            text: {
                                                // Identify if we are the input or output of this connection
                                                var isOutput = (modelData.outputUuid === selectedObjectView.uuid);
                                                var dir = isOutput ? "=> Destino" : "<= Origem";
                                                return dir + " (" + (isOutput ? modelData.inputMethod : modelData.outputMethod) + ")"
                                            }
                                            font.pixelSize: 10
                                            color: ThemeManager.textColor
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: "M: " + (modelData.outputUuid === selectedObjectView.uuid ? modelData.outputMethod : modelData.inputMethod)
                                            font.pixelSize: 9
                                            color: ThemeManager.textSecondaryColor
                                            opacity: 0.8
                                        }
                                    }

                                    // Comment Button
                                    Rectangle {
                                        Layout.preferredWidth: 26
                                        Layout.preferredHeight: 26
                                        radius: 4
                                        color: "transparent"
                                        Image {
                                            anchors.centerIn: parent
                                            width: 16
                                            height: 16
                                            source: "qrc:/icons/file-document-edit-outline.svg"
                                            sourceSize: Qt.size(16, 16)
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                var cmt = viewPortWindow.getConnectionComment(modelData.outputUuid, modelData.outputMethod, modelData.inputUuid, modelData.inputMethod);
                                                var msg = cmt ? cmt : "Sem anotação.";
                                                ToastManager.show("Comentário: " + msg, "info");
                                            }
                                            onEntered: parent.color = Qt.rgba(1,1,1,0.1)
                                            onExited: parent.color = "transparent"
                                        }
                                    }

                                    // Values Button
                                    Rectangle {
                                        Layout.preferredWidth: 26
                                        Layout.preferredHeight: 26
                                        radius: 4
                                        color: "transparent"
                                        Image {
                                            anchors.centerIn: parent
                                            width: 16
                                            height: 16
                                            source: "qrc:/icons/view-week.svg"
                                            sourceSize: Qt.size(16, 16)
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: ToastManager.show("Intercepção de valores requer o nó Debugger (Em breve)", "warning")
                                            onEntered: parent.color = Qt.rgba(1,1,1,0.1)
                                            onExited: parent.color = "transparent"
                                        }
                                    }

                                    // Remove Button
                                    Rectangle {
                                        Layout.preferredWidth: 26
                                        Layout.preferredHeight: 26
                                        radius: 4
                                        color: "transparent"
                                        Image {
                                            anchors.centerIn: parent
                                            width: 16
                                            height: 16
                                            source: "qrc:/icons/close.svg"
                                            sourceSize: Qt.size(16, 16)
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: viewPortWindow.removeConnectionWithUndo(modelData.outputUuid, modelData.outputMethod, modelData.inputUuid, modelData.inputMethod)
                                            onEntered: parent.color = Qt.rgba(ThemeManager.errorColor.r, ThemeManager.errorColor.g, ThemeManager.errorColor.b, 0.2)
                                            onExited: parent.color = "transparent"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
