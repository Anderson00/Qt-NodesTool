import QtQuick 2.12
import QtQuick.Controls 2.12
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts 1.12
import App.Theme 1.0
import App.Toast 1.0

Popup {
    id: root
    width: 160
    height: 160
    padding: 0
    modal: true
    dim: false
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
        distance: 55 * root.expansion
        iconSource: "qrc:/icons/information.svg"
        toolTipText: "Informação"
        onClicked: {
            ToastManager.show("Conexão: " + outNodeName + " (" + outMethod + ") -> " + inNodeName + " (" + inMethod + ")", "info")
            root.close()
        }
    }

    // 2. Remove Button (Right)
    RadialButton {
        id: removeBtn
        angle: 0
        distance: 55 * root.expansion
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

    // 3. Comment Button (Bottom)
    RadialButton {
        id: commentBtn
        angle: 90
        distance: 55 * root.expansion
        iconSource: "qrc:/icons/file-document-edit-outline.svg" // Use an edit icon for comment
        toolTipText: "Adicionar Comentário"
        onClicked: {
            commentDialog.open()
        }
    }

    // Comment Input Dialog
    Popup {
        id: commentDialog
        width: 320
        height: 200
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        modal: true
        dim: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        background: Rectangle {
            color: ThemeManager.surfaceColor
            radius: 8
            border.color: ThemeManager.primaryColor
            border.width: 1
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12
            
            Text {
                text: "Anotação da Conexão"
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 14
                font.bold: true
            }
            
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                TextArea {
                    id: commentInput
                    placeholderText: "Escreva suas anotações aqui..."
                    color: ThemeManager.textColor
                    font.pixelSize: 14
                    wrapMode: Text.Wrap
                    background: Rectangle {
                        color: Qt.rgba(ThemeManager.backgroundColor.r, ThemeManager.backgroundColor.g, ThemeManager.backgroundColor.b, 0.5)
                        radius: 4
                        border.width: 1
                        border.color: ThemeManager.primaryColor
                    }
                }
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignRight
                Button {
                    id: saveBtn
                    text: "Salvar"
                    flat: true
                    contentItem: Text {
                        text: saveBtn.text
                        color: ThemeManager.primaryColor
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        viewPort.setConnectionComment(outUuid, outMethod, inUuid, inMethod, commentInput.text)
                        ToastManager.show("Comentário salvo!", "success")
                        commentDialog.close()
                        root.close()
                    }
                }
            }
        }
        
        onOpened: {
            commentInput.text = viewPort.getConnectionComment(outUuid, outMethod, inUuid, inMethod)
            commentInput.forceActiveFocus()
        }
    }

    // 4. Copy Button (Left)
    RadialButton {
        id: copyBtn
        angle: 180
        distance: 55 * root.expansion
        iconSource: "qrc:/icons/content-save-cog-outline.svg"
        toolTipText: "Copiar UUIDs"
        onClicked: {
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
            id: iconImg
            anchors.centerIn: parent
            width: 20
            height: 20
            source: parent.iconSource
            sourceSize: Qt.size(20, 20)
            visible: false
        }
        
        ColorOverlay {
            anchors.fill: iconImg
            source: iconImg
            color: parent.iconColor
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
