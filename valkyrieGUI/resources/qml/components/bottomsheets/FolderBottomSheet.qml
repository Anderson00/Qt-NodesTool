import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.0
import QtQuick.Window 2.2

import Qaterial 1.0 as Qaterial

Drawer {
    id: root

    property bool gridMode: true

    width: parent.width
    height: 200
    modal: false
    edge: Qt.BottomEdge
    interactive: false

    background: Rectangle {
        color: Qt.rgba(0.2, 0.2, 0.2, 0.8)
    }

    // TODO: content, list of properties insipired in unity3d, blender, etc.
    ColumnLayout {
        spacing: 0
        anchors.fill: parent

        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: "#222"

            MouseArea {
                width: parent.width
                height: 5
                cursorShape: Qt.ArrowCursor

                drag.target: root
                drag.axis: Drag.YAxis

                onMouseYChanged: {
                    let calc = root.height + (-1)*mouseY;
                    if(calc >= 40 && calc <= Screen.height / 2){
                        root.height = calc
                    }

                }
            }

            RowLayout {
                anchors.fill: parent

                Qaterial.AppBarButton{
                    Layout.preferredHeight: 20
                    enabled: false
                    icon.source: `qrc:/Qaterial/Icons/arrow-left`
                    icon.color: Material.accentColor
                    Layout.alignment: Qt.AlignLeft

                    onClicked: {

                    }
                }

                Repeater {
                    id: breadcrumb

                    model: ["home", "Debugging", "test"]

                    delegate: RowLayout {

                        Qaterial.Icon {
                            id: breadcrumbIcon
                            Layout.preferredHeight: 20
                            visible: modelData === "home"
                            icon: Qaterial.Icons.home

                            HoverHandler {
                                id: breadcrumbIconHoverHandler
                                enabled: index < breadcrumb.model.length - 1

                                onHoveredChanged: {
                                    if(hovered)
                                        parent.color = Material.accentColor
                                    else
                                        parent.color = "#fff"
                                }
                            }

                            TapHandler {
                                enabled: breadcrumbIconHoverHandler.enabled

                                onTapped: {
                                    console.log(modelData);
                                }
                            }
                        }

                        Label {
                            visible: !breadcrumbIcon.visible
                            text: modelData
                            height: 30

                            HoverHandler {
                                id: hoverHandler
                                enabled: index < breadcrumb.model.length - 1

                                onHoveredChanged: {
                                    if(hovered)
                                        parent.color = Material.accentColor
                                    else
                                        parent.color = "#fff"

                                    parent.font.underline = hovered
                                }
                            }

                            TapHandler {
                                enabled: hoverHandler.enabled

                                onTapped: {
                                    console.log(modelData);
                                }
                            }
                        }

                        Label {
                            visible: index < breadcrumb.model.length - 1
                            text: "/"
                            height: 30
                        }
                    }


                }

                Item {
                    Layout.fillWidth: true
                }

                RowLayout {
                    Qaterial.Icon {
                        Layout.preferredHeight: 20
                        icon: Qaterial.Icons.folder
                    }
                    Label {
                        text: "2"
                    }

                    Qaterial.Icon {
                        Layout.preferredHeight: 20
                        icon: Qaterial.Icons.bug
                    }
                    Label {
                        text: "33"
                    }
                }


                Rectangle {
                    id: divider

                    width: 1
                    height: parent.height - 16
                    Layout.topMargin: 8
                    Layout.bottomMargin: 8
                    Layout.leftMargin: 16
                    color: "#333"
                }


                Qaterial.AppBarButton{
                    Layout.preferredHeight: 20
                    icon.source: 'qrc:/Qaterial/Icons/plus'
                    icon.color: Material.accentColor

                    onClicked: {

                    }
                }

                Qaterial.AppBarButton{
                    Layout.preferredHeight: 20
                    icon.source: gridMode ? 'qrc:/Qaterial/Icons/view-list' : 'qrc:/Qaterial/Icons/view-grid'
                    icon.color: Material.accentColor

                    onClicked: {
                        gridMode = !gridMode

                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true


        }

//        ColumnLayout {
//            Layout.fillHeight: true
//            Layout.fillWidth: true

//            Label {
//                text: "Content goes here!"
//            }
//        }
    }
}
