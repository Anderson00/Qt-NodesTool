import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import App.Theme 1.0

ComboBox {
    id: control

    property color accentColor: ThemeManager.primaryColor
    property color backgroundColor: Qt.rgba(1, 1, 1, 0.06)
    property color borderColor: Qt.rgba(1, 1, 1, 0.18)
    property int radius: 6

    font.pixelSize: 13
    implicitHeight: 36
    leftPadding: 12
    rightPadding: 32

    background: Rectangle {
        radius: control.radius
        color: control.backgroundColor
        border.width: 1
        border.color: control.activeFocus || control.hovered
                      ? control.accentColor
                      : control.borderColor

        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    contentItem: Text {
        text: control.displayText
        font: control.font
        color: ThemeManager.textColor
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Canvas {
        x: control.width - width - 10
        y: control.topPadding + (control.availableHeight - height) / 2
        width: 10
        height: 6
        contextType: "2d"
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.fillStyle = ThemeManager.textColor
            ctx.beginPath()
            ctx.moveTo(0, 0)
            ctx.lineTo(width, 0)
            ctx.lineTo(width / 2, height)
            ctx.closePath()
            ctx.fill()
        }
        rotation: control.popup.visible ? 180 : 0
        Behavior on rotation { NumberAnimation { duration: 150 } }
    }

    delegate: ItemDelegate {
        width: control.width
        height: 32
        contentItem: Text {
            text: modelData !== undefined ? modelData
                  : (model && model.text !== undefined ? model.text : "")
            font: control.font
            color: ThemeManager.textColor
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle {
            color: hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
        }
        highlighted: control.highlightedIndex === index
    }

    popup: Popup {
        y: control.height + 2
        width: control.width
        implicitHeight: contentItem.implicitHeight
        padding: 4

        contentItem: ListView {
            clip: true
            implicitHeight: Math.min(contentHeight, 240)
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator { }
        }

        background: Rectangle {
            color: ThemeManager.backgroundColor
            border.color: control.borderColor
            border.width: 1
            radius: control.radius
        }
    }
}

