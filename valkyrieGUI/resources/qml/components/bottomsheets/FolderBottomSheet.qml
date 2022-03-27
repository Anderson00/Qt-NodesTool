import QtQuick.Controls 2.15 as Contrl
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.14
import QtQuick.Window 2.2
import QtQuick 2.14
import QtQml 2.14

import Qaterial 1.0 as Qaterial

import '../'

Contrl.Drawer {
    id: root

    property bool gridMode: true
    property QtObject viewPortWindow
    property var dragViewMini
    property QtObject selectedElement

    property var icons: {'Debug': Qaterial.Icons.bug,
        'Plugins': Qaterial.Icons.codeBraces}

    width: parent.width
    height: 200
    modal: false
    edge: Qt.BottomEdge
    interactive: false

    background: Rectangle {
        color: Qt.rgba(0.2, 0.2, 0.2, 0.8)
    }

//    ViewComponentMini {
//        id: dragMinComp
//        z: 1000000

//        x:0
//        y:0

//    }

    // TODO: content, list of properties insipired in unity3d, blender, etc.
    ColumnLayout {
        id: columnLayout
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
                    visible: false
                    Layout.preferredHeight: 20
                    enabled: false
                    icon.source: `qrc:/Qaterial/Icons/arrow-left`
                    icon.color: Material.accentColor
                    Layout.alignment: Qt.AlignLeft

                    onClicked: {

                    }
                }

                RowLayout {
                    Layout.preferredHeight: 35
                    Layout.leftMargin: 8

                    Qaterial.Icon {
                        Layout.preferredHeight: 20
                        icon: Qaterial.Icons.magnify
                    }

                    Contrl.TextField {
                        id: _nameInput
                        Layout.preferredWidth: 200
                        Layout.preferredHeight: 35
                        placeholderText: "Search"

                        trailingInline: true
                        trailingContent: Qaterial.TextFieldButtonContainer
                        {
                            visible: _nameInput.text.trim().length > 0
                            anchors.top: parent.top
                            anchors.topMargin: 8
                            Qaterial.TextFieldClearButton { height: 20;}
                        } // TextFieldButtonContainer
                        //title: "Search"
                    } // TextField
                }

                Repeater {
                    id: breadcrumb
                    visible: false

                    model: ["home", "Debugging", "test"]

                    delegate: RowLayout {
                        visible: false

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

                        Contrl.Label {
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

                        Contrl.Label {
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
                    Contrl.Label {
                        text: "2"
                    }

                    Qaterial.Icon {
                        Layout.preferredHeight: 20
                        icon: Qaterial.Icons.bug
                    }
                    Contrl.Label {
                        text: "33"
                    }

                    Qaterial.Icon {
                        Layout.preferredHeight: 20
                        icon: Qaterial.Icons.codeBraces
                    }
                    Contrl.Label {
                        text: "1"
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

                        gridView.cellWidth = gridMode ? 150 : gridView.width
                        //gridView.cellHeight = gridMode ? 150 : gridView.height

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
                    //Layout.fillWidth: true
                    color: "transparent"
                    clip: true

                    Qaterial.TreeView {
                        id: treeView
                        anchors.fill: parent
                        height: parent ? Math.min(contentHeight, parent.height) : contentHeight

                        model: Qaterial.TreeModel {
                            Qaterial.TreeElement
                            {
                                text: "Debug"
                                Qaterial.TreeElement { text: "Common" }
                                Qaterial.TreeElement { text: "Conditional" }
                            }
                            Qaterial.TreeElement {
                                text: "Plugins"
                                Qaterial.TreeElement { text: "CMakeLists.txt" }
                            }
                        }

                        itemDelegate: Qaterial.ItemDelegate
                        {
                            id: control

                            property QtObject model
                            property int depth
                            property int index

                            height: 24
                            leftPadding: depth * 20

                            contentItem: RowLayout
                            {
                                Qaterial.ColorIcon
                                {
                                    source: Qaterial.Icons.chevronRight
                                    color: Qaterial.Style.primaryTextColor()
                                    visible: control.model && control.model.children && control.model.children.count
                                    Binding on rotation
                                    {
                                        when: control.model && control.model.expanded
                                        value: 90
                                        restoreMode: Binding.RestoreBindingOrValue
                                    }
                                    Behavior on rotation { NumberAnimation { duration: 200;easing.type: Easing.OutQuart } }
                                }

                                Qaterial.ColorIcon
                                {
                                    visible: source != ""
                                    source: root.icons[control.model ? control.model.text : ""] ?? ""
                                                                                                   color: Qaterial.Style.primaryTextColor()

                                }

                                Qaterial.Label
                                {
                                    Layout.fillWidth: true
                                    text: control.model ? control.model.text : ""
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                    Binding on color
                                    {
                                        when: model === root.selectedElement
                                        value: Qaterial.Style.accentColor
                                    }
                                }
                            }

                            onClicked: function()
                            {
                                if(model.children.count !== 0)
                                    model.expanded = !model.expanded
                                else{
                                    selectedElement = model

                                    console.log("item: " + model.text + model)

                                    console.log(Object.keys(treeView.model))
                                    console.log(model.index)
                                }
                            }
                        }
                    }

                }
                Rectangle {
                    id: centerItem
                    Contrl.SplitView.preferredWidth: 20
                    //Layout.minimumWidth: 50
                    //Layout.fillWidth: true
                    color: "transparent"


                    GridView {
                        id: gridView
                        clip: true
                        anchors.fill: parent
                        model:[1,2,3,4,5,6,7,8,9,10]

                        anchors.topMargin: 8
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8

                        boundsBehavior: Flickable.StopAtBounds
                        flow: GridView.LeftToRight
                        snapMode: GridView.SnapOneRow

                        Contrl.ScrollBar.vertical: Contrl.ScrollBar {
                            visible: true

                            contentItem: Rectangle {
                                width: 100
                                implicitHeight:4
                                radius: implicitHeight/2
                                color: Material.accentColor
                            }
                        }

                        cellWidth: 150
                        cellHeight: 150
                        delegate: ViewComponentMini {
                            id: card
                            color: "#222"
                            border.width: 1
                            border.color: Material.accentColor
                            radius: 4
                            width: gridView.cellWidth - 8
                            height: gridView.cellHeight - 8

                            Behavior on width {
                                enabled: !gridMode
                                NumberAnimation {
                                    duration: 150
                                }
                            }

                            MouseArea {
                                anchors.fill: parent

                                onDoubleClicked: {

                                }
                            }
                        }
                    }
                }
            }

        }
    }
}
