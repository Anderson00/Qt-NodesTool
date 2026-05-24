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

    property var interfaceData: []

    Connections {
        target: behaviourObject
        function onInternalInterfacesFetched(interfaces) {
            interfaceData = interfaces
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // -- Header row --
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Network Interfaces"
                font.pixelSize: 10
                font.bold: true
                color: ThemeManager.textColor
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            Badge {
                count: behaviourObject ? behaviourObject.interfaceCount : 0
                badgeColor: ThemeManager.primaryColor
            }

            NewButton {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 24
                variant: "outlined"
                iconSource: Icons.refresh
                onClicked: { if (behaviourObject) behaviourObject.refresh() }
            }
        }

        // -- Interface list --
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 4
            color: Qt.rgba(ThemeManager.backgroundColor.r, ThemeManager.backgroundColor.g, ThemeManager.backgroundColor.b, 0.4)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.3)
            clip: true

            ListView {
                id: ifaceList
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4
                model: interfaceData
                clip: true

                delegate: Rectangle {
                    width: ifaceList.width
                    height: ifaceCol.implicitHeight + 10
                    radius: 4
                    color: Qt.rgba(ThemeManager.surfaceColor.r, ThemeManager.surfaceColor.g, ThemeManager.surfaceColor.b, 0.6)
                    border.width: 1
                    border.color: Qt.rgba(ThemeManager.borderColor.r, ThemeManager.borderColor.g, ThemeManager.borderColor.b, 0.2)

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 6

                        // Status dot
                        StatusDot {
                            status: modelData.isUp ? "active" : "inactive"
                            Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                            Layout.topMargin: 2
                        }

                        // Interface details
                        ColumnLayout {
                            id: ifaceCol
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                spacing: 4
                                Text {
                                    text: modelData.name
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: ThemeManager.textColor
                                }
                                Chip {
                                    visible: modelData.isLoopback
                                    label: "lo"
                                    closeable: false
                                    selectable: false
                                    chipColor: Qt.rgba(ThemeManager.textSecondaryColor.r, ThemeManager.textSecondaryColor.g, ThemeManager.textSecondaryColor.b, 0.2)
                                }
                            }

                            Text {
                                visible: modelData.mac !== ""
                                text: modelData.mac
                                font.pixelSize: 8
                                font.family: "Consolas, monospace"
                                color: ThemeManager.textSecondaryColor
                            }

                            Text {
                                visible: modelData.ip4 !== ""
                                text: "IPv4: " + modelData.ip4
                                font.pixelSize: 9
                                color: "#2ecc71"
                            }

                            Text {
                                visible: modelData.ip6 !== ""
                                text: "IPv6: " + modelData.ip6
                                font.pixelSize: 8
                                color: "#5dade2"
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                // Empty state
                Text {
                    anchors.centerIn: parent
                    visible: ifaceList.count === 0
                    text: "No interfaces found"
                    font.pixelSize: 10
                    color: ThemeManager.textSecondaryColor
                }
            }
        }
    }
}
