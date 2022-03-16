import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.0

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
