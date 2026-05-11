import QtQuick 2.15
import QtQuick.Controls 2.15
import Qt5Compat.GraphicalEffects
import App.Theme 1.0

Item {
    id: card
    property bool shadow: true
    property int radius: 12
    property bool topLeft: true
    property bool topRight: true
    property bool bottomLeft: true
    property bool bottomRight: true

    width: 200
    height: 120

    Rectangle {
        id: background
        anchors.fill: parent
        color: ThemeManager.surfaceColor

        radius: 0 // base sem radius

        // máscara para controlar quais cantos ficam arredondados
        layer.enabled: true
        layer.smooth: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: card.width
                height: card.height
                color: "black"

                radius: card.radius

                // controla cada canto individualmente
                property int r: card.radius
                Rectangle { anchors.top: parent.top; anchors.left: parent.left; width: r; height: r; radius: card.topLeft ? r : 0; color: "black" }
                Rectangle { anchors.top: parent.top; anchors.right: parent.right; width: r; height: r; radius: card.topRight ? r : 0; color: "black" }
                Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; width: r; height: r; radius: card.bottomLeft ? r : 0; color: "black" }
                Rectangle { anchors.bottom: parent.bottom; anchors.right: parent.right; width: r; height: r; radius: card.bottomRight ? r : 0; color: "black" }
            }
        }
    }

    // sombra opcional
    DropShadow {
        anchors.fill: background
        source: background
        horizontalOffset: 4
        verticalOffset: 4
        radius: 12
        samples: 16
        color: ThemeManager.shadowColor
        visible: card.shadow
    }

    // conteúdo do card
    Text {
        anchors.centerIn: parent
        text: "Card QML"
        color: ThemeManager.textColor
    }
}

