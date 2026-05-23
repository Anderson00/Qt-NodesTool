import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import App.Icons 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent

    property var behaviourObject

    Component.onCompleted: {
        debounce.start()
    }

    Timer {
        id: debounce
        repeat: false
        interval: 50
        onTriggered: { }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        // ── Title ────────────────────────────────────────────────────────
        Text {
            text: "File Opener"
            color: ThemeManager.textColor
            font.pixelSize: 11
            font.bold: true
        }

        // ── Root path + filter row ────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            CustomTextField {
                id: rootPath
                Layout.fillWidth: true
                placeholderText: "Root path (default: .)"
            }

            CustomTextField {
                id: filterField
                Layout.preferredWidth: 100
                placeholderText: "Filter: *.exe"
            }

            // Browse button
            Rectangle {
                width: 28
                height: 28
                radius: 5
                color: browseMouse.containsMouse
                    ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.2)
                    : Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.3)
                border.color: ThemeManager.borderColor
                border.width: 1

                SvgIcon {
                    anchors.centerIn: parent
                    source: Icons.folderOpenOutline
                    color: ThemeManager.textColor
                    width: 16
                    height: 16
                }

                MouseArea {
                    id: browseMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var rootText = rootPath.text || '.'
                        var infos = behaviourObject.chooseFile(rootText, filterField.text)
                        if (infos && infos['filePath']) {
                            fileUrl.text  = infos['filePath']
                            fileName.text = infos['fileName']
                            fileSize.text = (infos['size'] / 1024 / 1024).toFixed(2) + " MB"
                        }
                    }
                }
                AppToolTip { text: "Browse for file"; visible: browseMouse.containsMouse; delay: 500 }
            }
        }

        // ── Result fields ────────────────────────────────────────────────
        // Full path
        Rectangle {
            Layout.fillWidth: true
            height: 28
            radius: 5
            color: Qt.rgba(ThemeManager.backgroundColor.r, ThemeManager.backgroundColor.g, ThemeManager.backgroundColor.b, 0.5)
            border.color: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.5)
            border.width: 1

            TextInput {
                id: fileUrl
                anchors.fill: parent
                anchors.margins: 6
                verticalAlignment: TextInput.AlignVCenter
                color: ThemeManager.textColor
                font.pixelSize: 10
                font.family: "Consolas, monospace"
                selectByMouse: true
                clip: true

                Text {
                    visible: fileUrl.text === ""
                    text: "No file selected"
                    color: ThemeManager.textSecondaryColor
                    font: fileUrl.font
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        // Name + size row
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Rectangle {
                Layout.fillWidth: true
                height: 24
                radius: 5
                color: Qt.rgba(ThemeManager.surfaceColor.r, ThemeManager.surfaceColor.g, ThemeManager.surfaceColor.b, 0.5)
                border.color: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.4)
                border.width: 1

                TextInput {
                    id: fileName
                    anchors.fill: parent
                    anchors.margins: 5
                    verticalAlignment: TextInput.AlignVCenter
                    color: ThemeManager.textSecondaryColor
                    font.pixelSize: 10
                    readOnly: true
                    clip: true

                    Text {
                        visible: fileName.text === ""
                        text: "Name"
                        color: ThemeManager.textSecondaryColor
                        font: fileName.font
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Rectangle {
                width: 72
                height: 24
                radius: 5
                color: Qt.rgba(ThemeManager.surfaceColor.r, ThemeManager.surfaceColor.g, ThemeManager.surfaceColor.b, 0.5)
                border.color: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.4)
                border.width: 1

                TextInput {
                    id: fileSize
                    anchors.fill: parent
                    anchors.margins: 5
                    verticalAlignment: TextInput.AlignVCenter
                    color: ThemeManager.textSecondaryColor
                    font.pixelSize: 10
                    readOnly: true
                    clip: true

                    Text {
                        visible: fileSize.text === ""
                        text: "Size"
                        color: ThemeManager.textSecondaryColor
                        font: fileSize.font
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
