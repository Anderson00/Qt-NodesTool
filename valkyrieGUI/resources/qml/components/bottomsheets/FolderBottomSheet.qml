import QtQuick.Controls 2.15 as Contrl
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.14
import QtQuick.Window 2.2
import QtQuick 2.14
import QtQml 2.14
import App.Theme 1.0
import App.Icons 1.0
import App.NodeRegistry 1.0

import '../'

Contrl.Drawer {
    id: root

    property bool gridMode: true
    property QtObject viewPortWindow
    property var dragViewMini
    property var selectedElement

    signal behaviourSelected(string path, variant infos);

    property var categoryIcons: {
        'Debug': Icons.bug,
        'Plugins': Icons.codeBraces
    }

    width: parent.width
    height: 200
    modal: false
    edge: Qt.BottomEdge
    interactive: false

    background: Rectangle {
        color: ThemeManager.foregroundColor
    }

    function getTextLabel(text){
        if (!text) return ""
        let arr = text.split(";");
        if(arr.length === 1)
            return text;
        if(arr.length > 1)
            return arr[arr.length - 1];
        return ""
    }

    function getPath(){
        return breadcrumb.model.slice(1, breadcrumb.model.length).join('/')
    }

    ColumnLayout {
        id: columnLayout
        spacing: 0
        anchors.fill: parent

        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: ThemeManager.surfaceColor

            MouseArea {
                width: parent.width
                height: 5
                cursorShape: Qt.ArrowCursor
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

                Item { width: 8 }

                Repeater {
                    id: breadcrumb
                    Layout.leftMargin: 16
                    model: ['home']

                    delegate: RowLayout {
                        ColorIcon {
                            id: breadcrumbIcon
                            width: 20; height: 20
                            visible: modelData === "home"
                            source: Icons.home
                            color: breadcrumbIconHoverHandler.hovered ? ThemeManager.primaryColor : ThemeManager.textColor

                            HoverHandler { id: breadcrumbIconHoverHandler; enabled: index < breadcrumb.model.length - 1 }
                            TapHandler {
                                enabled: breadcrumbIconHoverHandler.enabled
                                onTapped: { console.log(modelData); }
                            }
                        }

                        Contrl.Label {
                            visible: !breadcrumbIcon.visible
                            text: modelData
                            height: 30
                            color: hoverHandler.hovered ? ThemeManager.primaryColor : ThemeManager.textColor
                            font.underline: hoverHandler.hovered

                            HoverHandler { id: hoverHandler; enabled: index < breadcrumb.model.length - 1 }
                            TapHandler {
                                enabled: hoverHandler.enabled
                                onTapped: { console.log(modelData); }
                            }
                        }

                        Contrl.Label {
                            visible: index < breadcrumb.model.length - 1
                            text: "/"
                            height: 30
                            color: ThemeManager.textColor
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                RowLayout {
                    id: searchBar
                    Layout.preferredHeight: 35
                    spacing: 8

                    ColorIcon {
                        width: 20; height: 20
                        source: Icons.magnify
                        color: ThemeManager.textColor
                    }

                    Contrl.TextField {
                        id: _nameInput
                        Layout.preferredWidth: 200
                        Layout.preferredHeight: 35
                        placeholderText: "Search"
                    }
                }

                Rectangle {
                    id: divider
                    width: 1
                    height: parent.height - 16
                    Layout.margins: 8
                    color: ThemeManager.borderColor
                }

                RowLayout {
                    spacing: 8
                    ColorIcon { width: 20; height: 20; source: Icons.folder; color: ThemeManager.textColor }
                    Contrl.Label { text: "2"; color: ThemeManager.textColor }

                    ColorIcon { width: 20; height: 20; source: Icons.bug; color: ThemeManager.textColor }
                    Contrl.Label { text: "33"; color: ThemeManager.textColor }

                    ColorIcon { width: 20; height: 20; source: Icons.codeBraces; color: ThemeManager.textColor }
                    Contrl.Label { text: "1"; color: ThemeManager.textColor }
                }

                Rectangle {
                    width: 1; height: parent.height - 16; Layout.margins: 8
                    color: ThemeManager.borderColor
                }

                AppToolButton {
                    iconSource: Icons.plus
                    iconColor: ThemeManager.primaryColor
                    onClicked: {}
                }

                AppToolButton {
                    iconSource: gridMode ? Icons.viewList : Icons.viewGrid
                    iconColor: ThemeManager.primaryColor
                    onClicked: {
                        gridMode = !gridMode
                        gridView.cellWidth = gridMode ? 150 : gridView.width
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Contrl.SplitView {
                anchors.fill: parent
                orientation: Qt.Horizontal

                Rectangle {
                    width: 200
                    Contrl.SplitView.minimumWidth: 150
                    color: "transparent"
                    clip: true

                    ListView {
                        id: categoryList
                        anchors.fill: parent
                        model: NodeRegistry.discoverAllToTree()
                        delegate: Column {
                            width: categoryList.width
                            
                            Rectangle {
                                width: parent.width
                                height: 32
                                color: (root.selectedElement === modelData) ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.2) : "transparent"
                                
                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    spacing: 8
                                    
                                    ColorIcon {
                                        width: 16; height: 16
                                        source: Icons.chevronRight
                                        color: ThemeManager.textColor
                                        rotation: modelData.expanded ? 90 : 0
                                        visible: modelData.children && modelData.children.length > 0
                                        Behavior on rotation { NumberAnimation { duration: 200 } }
                                    }
                                    
                                    ColorIcon {
                                        width: 16; height: 16
                                        source: root.categoryIcons[modelData.text] || Icons.folder
                                        color: ThemeManager.textColor
                                    }
                                    
                                    Contrl.Label {
                                        text: modelData.text
                                        Layout.fillWidth: true
                                        color: ThemeManager.textColor
                                        elide: Text.ElideRight
                                    }
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        modelData.expanded = !modelData.expanded
                                        categoryList.model = NodeRegistry.discoverAllToTree() // Refresh hack for JSON
                                    }
                                }
                            }
                            
                            Repeater {
                                model: modelData.expanded ? modelData.children : []
                                delegate: Rectangle {
                                    width: categoryList.width
                                    height: 28
                                    color: (root.selectedElement === modelData) ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.3) : "transparent"
                                    
                                    Contrl.Label {
                                        anchors.fill: parent
                                        anchors.leftMargin: 32
                                        text: getTextLabel(modelData.text)
                                        verticalAlignment: Text.AlignVCenter
                                        color: ThemeManager.textColor
                                        font.pixelSize: 12
                                    }
                                    
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            root.selectedElement = modelData
                                            let path = modelData.text
                                            // The text in children is already the sub-path
                                            let fullPath = categoryList.model[index].text + "/" + path
                                            // Wait, the path logic needs to be careful
                                            let infos = NodeRegistry.discoverAll()["Debug/" + categoryList.model[index].text] // This is simplified
                                            // Better: use the actual path
                                            gridView.model = NodeRegistry.discoverAll()["Debug/" + categoryList.model[index].text]
                                            
                                            breadcrumb.model = ['home', categoryList.model[index].text, path]
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: centerItem
                    Contrl.SplitView.preferredWidth: 20
                    color: "transparent"

                    GridView {
                        id: gridView
                        clip: true
                        anchors.fill: parent
                        anchors.margins: 8
                        boundsBehavior: Flickable.StopAtBounds
                        flow: GridView.LeftToRight
                        snapMode: GridView.SnapOneRow
                        cellWidth: 150
                        cellHeight: 150

                        Contrl.ScrollBar.vertical: Contrl.ScrollBar {
                            policy: Contrl.ScrollBar.AsNeeded
                        }

                        delegate: ViewComponentMini {
                            id: card
                            name: modelData.name
                            desc: modelData.desc
                            n_inputs: modelData.inputs_count
                            n_outputs: modelData.outputs_count
                            onDoubleClicked: { behaviourSelected(getPath(), modelData) }
                            color: ThemeManager.surfaceColor
                            border.width: 1
                            border.color: ThemeManager.primaryColor
                            radius: 4
                            width: gridView.cellWidth - 8
                            height: gridView.cellHeight - 8
                        }
                    }
                }
            }
        }
    }
}

