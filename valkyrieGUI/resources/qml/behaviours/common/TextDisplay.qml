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

    readonly property string _text: behaviourObject ? behaviourObject.displayText : ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // ── Toolbar ────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: behaviourObject ? behaviourObject.lineCount + " lines" : "0 lines"
                font.pixelSize: 10
                color: ThemeManager.textSecondaryColor
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
            }

            // Max lines control
            Text {
                text: "max:"
                font.pixelSize: 9
                color: ThemeManager.textSecondaryColor
                Layout.alignment: Qt.AlignVCenter
            }
            NumberSpinBox {
                Layout.preferredWidth: 72
                implicitHeight: 24
                from: 10; to: 10000; stepSize: 100
                value: behaviourObject ? behaviourObject.maxLines : 500
                accentColor: ThemeManager.primaryColor
                onValueChanged: if (behaviourObject) behaviourObject.setMaxLines(value)
            }

            // Clear button
            Rectangle {
                width: 24; height: 24; radius: 4
                color: clearMa.containsMouse
                       ? Qt.rgba(ThemeManager.dangerColor.r,
                                 ThemeManager.dangerColor.g,
                                 ThemeManager.dangerColor.b, 0.18)
                       : "transparent"
                Behavior on color { ColorAnimation { duration: 100 } }

                ColorIcon {
                    anchors.centerIn: parent
                    source: Icons.deleteOutline
                    width: 14; height: 14
                    color: ThemeManager.dangerColor
                    opacity: clearMa.containsMouse ? 1.0 : 0.6
                }
                MouseArea {
                    id: clearMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (behaviourObject) behaviourObject.clear()
                }
            }
        }

        // ── Log area ───────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 4
            color: Qt.rgba(ThemeManager.backgroundColor.r,
                           ThemeManager.backgroundColor.g,
                           ThemeManager.backgroundColor.b, 0.6)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.borderColor.r,
                                  ThemeManager.borderColor.g,
                                  ThemeManager.borderColor.b, 0.35)
            clip: true

            // Placeholder when empty
            Text {
                anchors.centerIn: parent
                visible: root._text === ""
                text: "No output yet.\nConnect a node to\nappendText or appendLine."
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 10
                color: ThemeManager.textSecondaryColor
                opacity: 0.4
            }

            Flickable {
                id: flick
                anchors { fill: parent; margins: 4 }
                contentWidth:  width
                contentHeight: logText.implicitHeight + 8
                clip: true

                ScrollBar.vertical: ScrollBar {
                    id: vBar
                    policy: ScrollBar.AsNeeded
                    width: 5
                    minimumSize: 0.05
                }

                Text {
                    id: logText
                    width:    flick.width - (vBar.visible ? 6 : 0)
                    text:     root._text
                    wrapMode: Text.WrapAnywhere
                    font.pixelSize: 11
                    font.family:   "Consolas"
                    color:         ThemeManager.textColor
                    lineHeight:    1.3

                    // Highlight last line faintly
                    Rectangle {
                        visible: logText.lineCount > 0
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: logText.lineCount > 0
                                ? Math.ceil(logText.implicitHeight / Math.max(1, logText.lineCount))
                                : 0
                        color: Qt.rgba(ThemeManager.primaryColor.r,
                                       ThemeManager.primaryColor.g,
                                       ThemeManager.primaryColor.b, 0.06)
                        z: -1
                    }
                }
            }

            // Scroll-to-bottom button (shown only when not at bottom)
            Rectangle {
                anchors { right: parent.right; bottom: parent.bottom; margins: 6 }
                width: 22; height: 22; radius: 11
                visible: flick.contentHeight > flick.height &&
                         flick.contentY < flick.contentHeight - flick.height - 4
                color: Qt.rgba(ThemeManager.primaryColor.r,
                               ThemeManager.primaryColor.g,
                               ThemeManager.primaryColor.b, 0.8)

                SvgIcon {
                    anchors.centerIn: parent
                    width: 14; height: 14
                    source: Icons.chevronDown
                    color: ThemeManager.backgroundColor
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: flick.contentY = Math.max(0, flick.contentHeight - flick.height)
                }
            }
        }
    }

    // Auto-scroll to bottom when new text arrives
    Connections {
        target: behaviourObject
        function onDisplayTextChanged() {
            Qt.callLater(() => {
                if (flick.contentHeight > flick.height)
                    flick.contentY = flick.contentHeight - flick.height
            })
        }
    }
}

