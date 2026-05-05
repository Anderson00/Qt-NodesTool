import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import Qaterial 1.0 as Qaterial
import App.Theme 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // ── Toolbar ───────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: behaviourObject ? behaviourObject.lineCount + " lines" : "0 lines"
                font.pixelSize: 10; color: ThemeManager.textSecondaryColor
                Layout.fillWidth: true
            }

            Rectangle {
                width: 24; height: 24; radius: 4
                color: clearMa.containsMouse
                       ? Qt.rgba(ThemeManager.dangerColor.r, ThemeManager.dangerColor.g, ThemeManager.dangerColor.b, 0.15)
                       : "transparent"
                Qaterial.ColorIcon {
                    anchors.centerIn: parent
                    source: Qaterial.Icons.deleteOutline; width: 14; height: 14
                    color: ThemeManager.dangerColor; opacity: 0.7
                }
                MouseArea {
                    id: clearMa; anchors.fill: parent; hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: behaviourObject.clear()
                }
            }
        }

        // ── Text area ─────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 4
            color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.04)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.3)
            clip: true

            ScrollView {
                id: scrollView
                anchors.fill: parent
                anchors.margins: 4

                TextArea {
                    id: textArea
                    readOnly: true
                    wrapMode: TextArea.Wrap
                    font.pixelSize: 10
                    font.family: "Consolas"
                    color: ThemeManager.textColor
                    text: behaviourObject ? behaviourObject.displayText : ""
                    background: null
                    selectByMouse: true
                }
            }
        }
    }

    // Auto-scroll to bottom
    Connections {
        target: behaviourObject
        function onDisplayTextChanged() {
            scrollView.ScrollBar.vertical.position = 1.0 - scrollView.ScrollBar.vertical.size
        }
    }
}
