import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.12
import QtQuick.Controls.Material.impl 2.12
import QtQuick.Layouts 1.15
import App.Theme 1.0

ColumnLayout {
    id: root
    width: parent ? parent.width : 0
    spacing: 0

    // -- Public API --
    property alias title: titleLabel.text
    property alias loader: loaderBody.sourceComponent
    property int loaderHeight: 0
    property bool opened: false

    // -- Theming --
    property color headerColor: ThemeManager.foregroundColor
    property color headerHoverColor: ThemeManager.borderColor
    property color headerPressedColor: ThemeManager.selectionColor
    property color contentBgColor: ThemeManager.surfaceColor
    property color titleColor: ThemeManager.textColor
    property color iconColor: ThemeManager.primaryColor
    property color borderColor: ThemeManager.borderColor
    property int headerHeight: 40
    property int radius: 6

    // ---- Header ----
    Rectangle {
        id: header
        Layout.fillWidth: true
        Layout.preferredHeight: root.headerHeight
        radius: root.radius
        color: headerArea.pressed ? root.headerPressedColor
             : headerArea.containsMouse ? root.headerHoverColor
                                        : root.headerColor
        border.width: 1
        border.color: root.borderColor

        Behavior on color { ColorAnimation { duration: 120 } }

        // Title (centered vertically, padded left)
        Label {
            id: titleLabel
            anchors.left: parent.left
            anchors.right: chevron.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 14
            anchors.rightMargin: 8
            color: root.titleColor
            font.pixelSize: 13
            font.bold: true
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        // Chevron (drawn with Canvas, perfectly centered)
        Item {
            id: chevron
            width: 16
            height: 16
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            rotation: root.opened ? 180 : 0
            Behavior on rotation {
                NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
            }

            Canvas {
                id: chevronCanvas
                anchors.fill: parent
                property color strokeColor: root.iconColor
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    ctx.strokeStyle = strokeColor
                    ctx.lineWidth = 2
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"
                    ctx.beginPath()
                    ctx.moveTo(width * 0.20, height * 0.38)
                    ctx.lineTo(width * 0.50, height * 0.66)
                    ctx.lineTo(width * 0.80, height * 0.38)
                    ctx.stroke()
                }
                onStrokeColorChanged: requestPaint()
            }
        }

        MouseArea {
            id: headerArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.opened = !root.opened
        }
    }

    // ---- Content area ----
    Rectangle {
        id: loaderBackground
        Layout.fillWidth: true
        Layout.preferredHeight: root.opened ? root.loaderHeight : 0
        color: root.contentBgColor
        radius: root.radius
        border.width: root.opened ? 1 : 0
        border.color: root.borderColor
        clip: true

        Behavior on Layout.preferredHeight {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
        }

        Loader {
            id: loaderBody
            anchors.fill: parent
            anchors.margins: 4
        }
    }
}
