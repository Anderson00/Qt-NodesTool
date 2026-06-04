import QtQuick 2.12
import QtQuick.Controls 2.12
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts 1.12
import App.Theme 1.0
import App.Toast 1.0
import App.Icons 1.0
import ".."

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
        iconSource: Icons.information
        toolTipText: qsTr("Info")
        onClicked: {
            ToastManager.show(qsTr("Connection: %1 (%2) -> %3 (%4)").arg(outNodeName).arg(outMethod).arg(inNodeName).arg(inMethod), "info")
            root.close()
        }
    }

    // 2. Remove Button (Right)
    RadialButton {
        id: removeBtn
        angle: 0
        distance: 55 * root.expansion
        iconSource: Icons.close
        toolTipText: qsTr("Remove")
        iconColor: ThemeManager.dangerColor
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
        iconSource: Icons.fileDocumentEditOutline // Use an edit icon for comment
        toolTipText: qsTr("Add Comment")
        onClicked: {
            commentDialog.open()
        }
    }

    // Comment Input Dialog
    Popup {
        id: commentDialog
        width: 350
        height: 250
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        modal: true
        dim: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        background: Rectangle {
            color: "transparent"
        }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 8
            
            Text {
                text: qsTr("Connection Annotation")
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 14
                font.bold: true
                Layout.leftMargin: 4
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Qt.rgba(ThemeManager.backgroundColor.r, ThemeManager.backgroundColor.g, ThemeManager.backgroundColor.b, 0.85)
                radius: 8
                border.width: 1
                border.color: ThemeManager.primaryColor

                    
                TextArea {
                    id: commentInput
                    anchors.fill: parent

                    placeholderText: qsTr("Write your annotations here...")
                    color: ThemeManager.textColor
                    font.pixelSize: 14
                    wrapMode: Text.Wrap
                    background: Item {} // Transparent background
                }
            }
            
            RowLayout {
                Layout.alignment: Qt.AlignRight
                Button {
                    id: saveBtn
                    text: qsTr("Save Annotation")
                    background: Rectangle {
                        color: ThemeManager.primaryColor
                        radius: 6
                    }
                    contentItem: Text {
                        text: saveBtn.text
                        color: "#FFFFFF"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        viewPort.setConnectionComment(outUuid, outMethod, inUuid, inMethod, commentInput.text)
                        ToastManager.show(qsTr("Annotation saved!"), "success")
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
        iconSource: Icons.contentSaveCogOutline
        toolTipText: qsTr("Copy UUIDs")
        onClicked: {
            ToastManager.show(qsTr("Source UUID: %1\nTarget UUID: %2").arg(outUuid).arg(inUuid), "success")
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
            id: radialMA
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

        AppToolTip { text: toolTipText; visible: radialMA.containsMouse }
        
        Behavior on scale { NumberAnimation { duration: 150 } }
        Behavior on color { ColorAnimation { duration: 150 } }
    }
}

