import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import App.Theme 1.0
import App.Icons 1.0
import ".."

Rectangle {
    id: root
    width: layout.implicitWidth + 32
    height: 56
    radius: height / 2
    
    // Glassmorphism effect base
    color: Qt.rgba(ThemeManager.backgroundColor.r,
                   ThemeManager.backgroundColor.g,
                   ThemeManager.backgroundColor.b, 0.85)
    border.color: ThemeManager.borderColor
    border.width: 1

    property real zoomScale: 1.0
    property real minZoom: 0.1
    property real maxZoom: 5.0
    property bool showGrid: true
    property bool connectionsMinimized: false
    property bool snapEnabled: false
    property string toolMode: "pan"

    signal toolModeActivated(string mode)
    signal zoomIn()
    signal zoomOut()
    signal resetZoom()
    signal centerView()
    signal toggleGrid()
    signal toggleFps()
    signal toggleFullscreen()
    signal toggleConnectionsMinimized()
    signal toggleSnap()

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8

        // Tool Mode: Select
        AppToolButton {
            checkable: true
            checked: root.toolMode === "select"
            iconSource: Icons.cursorDefault
            iconColor: root.toolMode === "select" ? ThemeManager.accentColor : ThemeManager.textColor
            onClicked: root.toolModeActivated("select")
            AppToolTip { text: qsTr("Select Tool  [S]"); visible: parent.hovered }
        }

        // Tool Mode: Pan
        AppToolButton {
            checkable: true
            checked: root.toolMode === "pan"
            iconSource: Icons.handBackRight
            iconColor: root.toolMode === "pan" ? ThemeManager.accentColor : ThemeManager.textColor
            onClicked: root.toolModeActivated("pan")
            AppToolTip { text: qsTr("Pan Tool  [P]"); visible: parent.hovered }
        }

        Rectangle { width: 1; height: 32; color: ThemeManager.borderColor; Layout.alignment: Qt.AlignVCenter }

        // Zoom Out
        AppToolButton {
            checkable: false
            iconSource: Icons.minus
            iconColor: ThemeManager.textColor
            onClicked: root.zoomOut()
            AppToolTip { text: qsTr("Zoom Out"); visible: parent.hovered }
        }

        // Zoom Label
        Label {
            text: Math.round(root.zoomScale * 100) + "%"
            color: ThemeManager.textColor
            font.bold: true
            font.pixelSize: 14
            Layout.minimumWidth: 45
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            MouseArea {
                anchors.fill: parent
                onClicked: root.resetZoom()
                cursorShape: Qt.PointingHandCursor
                AppToolTip { text: qsTr("Reset Zoom"); visible: parent.containsMouse }
            }
        }

        // Zoom In
        AppToolButton {
            checkable: false
            iconSource: Icons.plus
            iconColor: ThemeManager.textColor
            onClicked: root.zoomIn()
            AppToolTip { text: qsTr("Zoom In"); visible: parent.hovered }
        }

        Rectangle { width: 1; height: 32; color: ThemeManager.borderColor; Layout.alignment: Qt.AlignVCenter }

        // Toggle Connections Minimize
        AppToolButton {
            id: toggleConnsBtn
            checkable: false
            iconSource: root.connectionsMinimized
                ? Icons.chevronUp
                : Icons.chevronDown
            iconColor: root.connectionsMinimized
                ? ThemeManager.accentColor
                : ThemeManager.textColor
            onClicked: root.toggleConnectionsMinimized()
            AppToolTip { text: root.connectionsMinimized ? "Expandir todas as conexões" : "Recolher todas as conexões"; visible: parent.hovered }
        }

        Rectangle { width: 1; height: 32; color: ThemeManager.borderColor; Layout.alignment: Qt.AlignVCenter }

        // Center View
        AppToolButton {
            checkable: false
            iconSource: Icons.centerFocus
            iconColor: ThemeManager.textColor
            onClicked: root.centerView()
            AppToolTip { text: qsTr("Center View"); visible: parent.hovered }
        }

        Rectangle { width: 1; height: 32; color: ThemeManager.borderColor; Layout.alignment: Qt.AlignVCenter }

        // Grid Snap toggle
        AppToolButton {
            id: snapBtn
            checkable: true
            checked: root.snapEnabled
            iconSource: Icons.magnet
            iconColor: root.snapEnabled ? "#00e676" : ThemeManager.textColor
            onClicked: root.toggleSnap()
            AppToolTip { text: qsTr("Grid Snap  [G]"); visible: parent.hovered; delay: 600 }

            // Subtle green glow ring when active
            Rectangle {
                anchors.centerIn: parent
                width:  parent.width  + 6
                height: parent.height + 6
                radius: width / 2
                color: "transparent"
                border.width: root.snapEnabled ? 1.5 : 0
                border.color: "#00e676"
                opacity: root.snapEnabled ? 0.55 : 0
                Behavior on opacity  { NumberAnimation { duration: 150 } }
                Behavior on border.width { NumberAnimation { duration: 150 } }
            }
        }

        // View Options
        AppToolButton {
            id: viewMenuBtn
            iconSource: Icons.eye
            iconColor:  ThemeManager.textColor
            onClicked: viewMenu.open()
            AppToolTip { text: qsTr("View Options"); visible: parent.hovered }
        }

        Popup {
            id: viewMenu
            // Position above the button, horizontally centered on it
            parent: viewMenuBtn
            y: -implicitHeight - 10
            x: (viewMenuBtn.width - implicitWidth) / 2

            padding: 0
            implicitWidth: 188

            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            background: Rectangle {
                color:        ThemeManager.surfaceColor
                border.color: ThemeManager.borderColor
                border.width: 1
                radius:       6
            }

            contentItem: Column {
                spacing: 0

                // Reusable themed menu item
                component AppMenuItem: Rectangle {
                    id: mi
                    property string label:      ""
                    property string iconSource: ""
                    signal triggered()

                    width:  188
                    height: 36
                    color:  miMouse.containsMouse
                            ? Qt.rgba(ThemeManager.primaryColor.r,
                                      ThemeManager.primaryColor.g,
                                      ThemeManager.primaryColor.b, 0.14)
                            : "transparent"
                    radius: 4

                    Row {
                        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 12 }
                        spacing: 10

                        ColorIcon {
                            source: mi.iconSource
                            color:  ThemeManager.textSecondaryColor
                            width: 16; height: 16
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text:  mi.label
                            color: ThemeManager.textColor
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: miMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape:  Qt.PointingHandCursor
                        onClicked: { mi.triggered(); viewMenu.close() }
                    }
                }

                // 4 px top padding
                Item { width: 1; height: 4 }

                AppMenuItem {
                    label:      root.showGrid ? "Hide Grid" : "Show Grid"
                    iconSource: Icons.viewGrid
                    onTriggered: root.toggleGrid()
                }
                AppMenuItem {
                    label: qsTr("Toggle FPS")
                    iconSource: Icons.speedometer
                    onTriggered: root.toggleFps()
                }
                AppMenuItem {
                    label: qsTr("Toggle Fullscreen")
                    iconSource: Icons.fullscreen
                    onTriggered: root.toggleFullscreen()
                }

                // 4 px bottom padding
                Item { width: 1; height: 4 }
            }
        }
    }
}

