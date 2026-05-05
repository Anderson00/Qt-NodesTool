import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Qaterial 1.0 as Qaterial
import App.Theme 1.0

Rectangle {
    id: root
    width: layout.implicitWidth + 32
    height: 56
    radius: height / 2
    
    // Glassmorphism effect base
    color: ThemeManager.primaryColor
    opacity: 0.95
    border.color: ThemeManager.borderColor
    border.width: 1

    property real zoomScale: 1.0
    property real minZoom: 0.1
    property real maxZoom: 5.0
    property bool showGrid: true

    signal zoomIn()
    signal zoomOut()
    signal resetZoom()
    signal centerView()
    signal toggleGrid()
    signal toggleFps()
    signal toggleFullscreen()

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 8

        // Tool Mode: Select
        Qaterial.ToolButton {
            icon.source: Qaterial.Icons.cursorDefault
            icon.color: ThemeManager.accentColor
            ToolTip.text: "Select Tool"
            ToolTip.visible: hovered
        }

        // Tool Mode: Pan
        Qaterial.ToolButton {
            icon.source: Qaterial.Icons.handBackRight
            icon.color: ThemeManager.textColor
            ToolTip.text: "Pan Tool"
            ToolTip.visible: hovered
        }

        Rectangle { width: 1; height: 32; color: ThemeManager.borderColor; Layout.alignment: Qt.AlignVCenter }

        // Zoom Out
        Qaterial.ToolButton {
            icon.source: Qaterial.Icons.minus
            icon.color: ThemeManager.textColor
            ToolTip.text: "Zoom Out"
            ToolTip.visible: hovered
            onClicked: root.zoomOut()
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
                ToolTip.text: "Reset Zoom"
                ToolTip.visible: containsMouse
            }
        }

        // Zoom In
        Qaterial.ToolButton {
            icon.source: Qaterial.Icons.plus
            icon.color: ThemeManager.textColor
            ToolTip.text: "Zoom In"
            ToolTip.visible: hovered
            onClicked: root.zoomIn()
        }

        Rectangle { width: 1; height: 32; color: ThemeManager.borderColor; Layout.alignment: Qt.AlignVCenter }

        // Center View
        Qaterial.ToolButton {
            icon.source: Qaterial.Icons.imageFilterCenterFocus
            icon.color: ThemeManager.textColor
            ToolTip.text: "Center View"
            ToolTip.visible: hovered
            onClicked: root.centerView()
        }

        // View Menu
        Qaterial.ToolButton {
            id: viewMenuBtn
            icon.source: Qaterial.Icons.eyeOutline
            icon.color: ThemeManager.textColor
            ToolTip.text: "View Options"
            ToolTip.visible: hovered
            onClicked: viewMenu.open()

            Qaterial.Menu {
                id: viewMenu
                y: -height - 12
                x: -width / 2 + viewMenuBtn.width / 2

                Qaterial.MenuItem {
                    text: root.showGrid ? "Hide Grid" : "Show Grid"
                    icon.source: Qaterial.Icons.grid
                    onTriggered: root.toggleGrid()
                }
                Qaterial.MenuItem {
                    text: "Toggle FPS"
                    icon.source: Qaterial.Icons.monitorHeart
                    onTriggered: root.toggleFps()
                }
                Qaterial.MenuItem {
                    text: "Toggle Fullscreen"
                    icon.source: Qaterial.Icons.fullscreen
                    onTriggered: root.toggleFullscreen()
                }
            }
        }
    }
}
