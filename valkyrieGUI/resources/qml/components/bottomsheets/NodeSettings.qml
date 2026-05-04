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

        Item {
            Layout.fillHeight: true
        }
    }
}
