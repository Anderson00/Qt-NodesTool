import QtQuick 2.12
import QtQuick.Controls 2.12
import App.Theme 1.0
import App.Desktop 1.0
import App.Icons 1.0

import ".."

// Modal popup shown when the user tries to create a 9th+ virtual desktop.
// "OK, create anyway" dismisses the warning for the rest of the session and
// forwards the request to DesktopManager.addDesktopForced().
Popup {
    id: root
    width: 420
    z: 5000
    modal: true
    padding: 0
    closePolicy: Popup.CloseOnEscape

    x: parent ? (parent.width  - width)  / 2 : 0
    y: parent ? (parent.height - height) / 2 : 0

    property string pendingName: ""

    background: Rectangle {
        color:  ThemeManager.surfaceColor
        radius: 10
        border.color: Qt.rgba(ThemeManager.borderColor.r,
                              ThemeManager.borderColor.g,
                              ThemeManager.borderColor.b, 0.5)
        border.width: 1
    }

    Column {
        width: parent.width
        spacing: 0

        Item {
            width: parent.width
            height: 64
            Row {
                anchors.left: parent.left; anchors.leftMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14
                ColorIcon {
                    source: Icons.alertOutline
                    color:  "#ff9800"
                    width: 22; height: 22
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "Desktop limit"
                    font.pixelSize: 14
                    font.bold: true
                    color: ThemeManager.textColor
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: ThemeManager.borderColor; opacity: 0.4 }

        Item {
            width: parent.width
            height: warnBody.implicitHeight + 48
            Column {
                id: warnBody
                x: 24; y: 24
                width: parent.width - 48
                spacing: 20

                Text {
                    width: parent.width
                    text: "You are about to create more than " + DesktopManager.softLimit
                          + " virtual desktops. Having many desktops may impact performance and memory."
                    color: ThemeManager.textSecondaryColor
                    font.pixelSize: 13
                    lineHeight: 1.5
                    wrapMode: Text.WordWrap
                }
                Text {
                    width: parent.width
                    text: "Click OK to continue (this warning won't appear again in this session)."
                    color: ThemeManager.textSecondaryColor
                    font.pixelSize: 11
                    opacity: 0.7
                    lineHeight: 1.5
                    wrapMode: Text.WordWrap
                }

                Row {
                    anchors.right: parent.right
                    spacing: 8

                    Rectangle {
                        width: 80; height: 36; radius: 6
                        color: cancelHover.containsMouse
                                   ? Qt.rgba(ThemeManager.borderColor.r,
                                             ThemeManager.borderColor.g,
                                             ThemeManager.borderColor.b, 0.25)
                                   : "transparent"
                        border.color: ThemeManager.borderColor
                        border.width: 1
                        Text { anchors.centerIn: parent; text: "Cancel"
                               color: ThemeManager.textSecondaryColor; font.pixelSize: 12 }
                        MouseArea {
                            id: cancelHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.close()
                        }
                    }

                    Rectangle {
                        width: 180; height: 36; radius: 6
                        color: okHover.containsMouse
                                   ? Qt.lighter("#ff9800", 1.1)
                                   : "#ff9800"
                        Text { anchors.centerIn: parent; text: "OK, create anyway"
                               color: "white"; font.pixelSize: 12; font.bold: true }
                        MouseArea {
                            id: okHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                DesktopManager.dismissDesktopWarning()
                                DesktopManager.addDesktopForced(root.pendingName)
                                root.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
