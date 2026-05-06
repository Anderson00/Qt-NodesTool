import QtQuick 2.12
import QtQuick.Controls 2.12
import Qt5Compat.GraphicalEffects
import App.Theme 1.0
import App.Toast 1.0

Popup {
    id: root
    width: 160
    height: 160
    padding: 0
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    // Coordinates to open at
    property real originX: 0
    property real originY: 0

    // Connection data
    property int connectionIndex: -1
    property string outNodeName: ""
    property string outMethod: ""
    property string inNodeName: ""
    property string inMethod: ""
    property string outUuid: ""
    property string inUuid: ""

    x: originX - width / 2
    y: originY - height / 2

    // Animation state
    property real expansion: 0.0

    onOpened: {
        expansionAnim.restart()
    }

    onClosed: {
        expansion = 0.0
    }

    NumberAnimation {
        id: expansionAnim
        target: root
        property: "expansion"
        from: 0.0
        to: 1.0
        duration: 300
        easing.type: Easing.OutBack
    }

    background: Item {
        // Transparent background for the popup itself
    }

    // Central aesthetic dot
    Rectangle {
        anchors.centerIn: parent
        width: 12 * root.expansion
        height: 12 * root.expansion
        radius: width / 2
        color: ThemeManager.primaryColor
        opacity: 0.8
    }

    // Radial Buttons
    // 1. Info Button (Top)
    RadialButton {
        id: infoBtn
        angle: -90
        distance: 50 * root.expansion
        iconSource: "qrc:/icons/information.svg"
        toolTipText: "Informação"
        onClicked: {
            ToastManager.show("Conexão: " + outNodeName + " (" + outMethod + ") -> " + inNodeName + " (" + inMethod + ")", "info")
            root.close()
        }
    }

    // 2. Remove Button (Bottom Right)
    RadialButton {
        id: removeBtn
        angle: 30
        distance: 50 * root.expansion
        iconSource: "qrc:/icons/close.svg"
        toolTipText: "Remover"
        iconColor: ThemeManager.errorColor
        onClicked: {
            if (connectionIndex !== -1) {
                viewPort.removeConnectionWithUndo(outUuid, outMethod, inUuid, inMethod)
            }
            root.close()
        }
    }

    // 3. Copy Button (Bottom Left)
    RadialButton {
        id: copyBtn
        angle: 150
        distance: 50 * root.expansion
        iconSource: "qrc:/icons/file-document-edit-outline.svg"
        toolTipText: "Copiar Dados"
        onClicked: {
            // Can be extended to copy to clipboard
            ToastManager.show("UUID Origem: " + outUuid + "\nUUID Destino: " + inUuid, "success")
            root.close()
        }
    }

    // Component for each radial button
    component RadialButton: Rectangle {
        property real angle: 0
        property real distance: 0
        property string iconSource: ""
        property string toolTipText: ""
        property color iconColor: ThemeManager.textColor

        signal clicked()

        width: 40
        height: 40
        radius: 20
        color: Qt.darker(ThemeManager.backgroundColor, 1.2)
        border.color: Qt.darker(ThemeManager.primaryColor, 1.5)
        border.width: 1
        opacity: root.expansion

        // Positioning using polar coordinates relative to center
        x: (root.width / 2) + Math.cos(angle * Math.PI / 180) * distance - width / 2
        y: (root.height / 2) + Math.sin(angle * Math.PI / 180) * distance - height / 2

        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true
            color: "#60000000"
            radius: 8
            samples: 16
        }

        Image {
            anchors.centerIn: parent
            width: 20
            height: 20
            source: parent.iconSource
            sourceSize: Qt.size(20, 20)
            // Color overlay if needed (QtGraphicalEffects ColorOverlay is typical, but we can just use opacity for now)
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.clicked()
            onEntered: {
                parent.color = Qt.lighter(ThemeManager.backgroundColor, 1.5)
                parent.scale = 1.1
            }
            onExited: {
                parent.color = Qt.darker(ThemeManager.backgroundColor, 1.2)
                parent.scale = 1.0
            }
        }

        ToolTip.visible: parent.children[2].containsMouse
        ToolTip.text: parent.toolTipText
        
        Behavior on scale { NumberAnimation { duration: 150 } }
        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
