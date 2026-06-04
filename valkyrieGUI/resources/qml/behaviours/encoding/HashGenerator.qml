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

    Connections {
        target: behaviourObject

        function onInternalHashReady(hexHash) {
            resultField.text = hexHash
        }

        function onInternalAlgorithmChanged(alg) {
            // algorithm chips update via behaviourObject.algorithm binding
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 6

        // ── Algorithm selector ────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: qsTr("Algorithm:")
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 11
            }

            Chip {
                label: qsTr("MD5")
                closeable: false
                selectable: true
                selected: behaviourObject ? behaviourObject.algorithm === "md5" : false
                onClicked: behaviourObject.setAlgorithm("md5")
            }

            Chip {
                label: qsTr("SHA1")
                closeable: false
                selectable: true
                selected: behaviourObject ? behaviourObject.algorithm === "sha1" : false
                onClicked: behaviourObject.setAlgorithm("sha1")
            }

            Chip {
                label: qsTr("SHA256")
                closeable: false
                selectable: true
                selected: behaviourObject ? behaviourObject.algorithm === "sha256" : true
                onClicked: behaviourObject.setAlgorithm("sha256")
            }

            Chip {
                label: qsTr("SHA512")
                closeable: false
                selectable: true
                selected: behaviourObject ? behaviourObject.algorithm === "sha512" : false
                onClicked: behaviourObject.setAlgorithm("sha512")
            }
        }

        // ── Input ─────────────────────────────────────────────────────────────
        CustomTextField {
            id: inputField
            Layout.fillWidth: true
            placeholderText: qsTr("Input text...")
            onAccepted: behaviourObject.hash(text)
        }

        // ── Hash button ───────────────────────────────────────────────────────
        NewButton {
            Layout.fillWidth: true
            text: qsTr("Hash")
            variant: "filled"
            onClicked: behaviourObject.hash(inputField.text)
        }

        // ── Result ────────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Rectangle {
                Layout.fillWidth: true
                height: 32
                color: Qt.rgba(ThemeManager.backgroundColor.r, ThemeManager.backgroundColor.g, ThemeManager.backgroundColor.b, 0.6)
                border.color: ThemeManager.borderColor
                border.width: 1
                radius: 6

                TextInput {
                    id: resultField
                    anchors.fill: parent
                    anchors.margins: 6
                    verticalAlignment: TextInput.AlignVCenter
                    color: ThemeManager.textColor
                    font { pixelSize: 10; family: "Consolas" }
                    readOnly: true
                    selectByMouse: true
                    text: behaviourObject ? behaviourObject.lastHash : ""
                    clip: true

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            parent.selectAll()
                            parent.copy()
                        }
                        cursorShape: Qt.IBeamCursor
                    }
                }
            }

            // Copy button
            Rectangle {
                width: 28; height: 32; radius: 4
                color: copyMouse.containsMouse
                    ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.18)
                    : Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.3)
                border.color: ThemeManager.borderColor; border.width: 1

                SvgIcon {
                    anchors.centerIn: parent
                    source: Icons.clipboardTextOutline
                    color: ThemeManager.textSecondaryColor
                    width: 14; height: 14
                }

                MouseArea {
                    id: copyMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        resultField.selectAll()
                        resultField.copy()
                    }
                }
                AppToolTip { text: qsTr("Copy hash"); visible: copyMouse.containsMouse; delay: 600 }
            }
        }
    }
}
