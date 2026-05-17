import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import App.Theme 1.0
import App.Icons 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    property var treeModel: []

    // Track collapsed node keys at each depth
    property var collapsedSet: ({})

    function typeIcon(type) {
        if (type === "object")  return "{}"
        if (type === "array")   return "[]"
        if (type === "string")  return "\""
        if (type === "number")  return "0"
        if (type === "bool")    return "✓"
        if (type === "null")    return "∅"
        return "?"
    }

    function typeColor(type) {
        if (type === "object")  return ThemeManager.primaryColor
        if (type === "array")   return "#f39c12"
        if (type === "string")  return ThemeManager.successColor
        if (type === "number")  return "#e74c3c"
        if (type === "bool")    return ThemeManager.warningColor
        if (type === "null")    return ThemeManager.textSecondaryColor
        return ThemeManager.textSecondaryColor
    }

    Connections {
        target: behaviourObject

        function onInternalLoad(model) {
            collapsedSet = {}
            treeModel = model
        }

        function onInternalClear() {
            treeModel = []
            collapsedSet = {}
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Toolbar ────────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            height: 34
            color: ThemeManager.surfaceColor

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 4

                Text {
                    text: "JSON Tree Viewer"
                    color: ThemeManager.textColor
                    font.pixelSize: 11
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: (behaviourObject ? behaviourObject.nodeCount : 0) + " nodes"
                    color: ThemeManager.textSecondaryColor
                    font.pixelSize: 9
                    Layout.alignment: Qt.AlignVCenter
                }

                // Expand depth spinbox
                Text {
                    text: "depth:"
                    color: ThemeManager.textSecondaryColor
                    font.pixelSize: 9
                    Layout.alignment: Qt.AlignVCenter
                }

                NumberSpinBox {
                    value: behaviourObject ? behaviourObject.expandDepth : 2
                    from: 0
                    to: 20
                    Layout.preferredWidth: 56
                    onValueChanged: {
                        if (behaviourObject && behaviourObject.expandDepth !== value)
                            behaviourObject.setExpandDepth(value)
                    }
                }
            }
        }

        // ── Tree ListView ──────────────────────────────────────────────────
        ListView {
            id: treeList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: treeModel.length
            ScrollBar.vertical: ScrollBar {}

            delegate: Rectangle {
                id: rowRect
                width: treeList.width
                height: 24

                property var  node:    treeModel[index] !== undefined ? treeModel[index] : {}
                property int  indentD: node.depth !== undefined ? node.depth : 0
                property bool hasCh:   node.hasChildren === true
                property bool isExp:   node.expanded === true && !(collapsedSet[index] === true)

                color: rowMouse.containsMouse
                       ? Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g,
                                 ThemeManager.primaryColor.b, 0.10)
                       : (index % 2 === 0
                          ? Qt.rgba(ThemeManager.surfaceColor.r, ThemeManager.surfaceColor.g,
                                    ThemeManager.surfaceColor.b, 0.25)
                          : "transparent")

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 6 + indentD * 12
                    anchors.rightMargin: 6
                    spacing: 4

                    // Expand/collapse triangle
                    Text {
                        text: hasCh ? (isExp ? "▾" : "▸") : " "
                        color: ThemeManager.textSecondaryColor
                        font.pixelSize: 10
                        Layout.preferredWidth: 12
                        Layout.alignment: Qt.AlignVCenter

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: hasCh ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (!hasCh) return
                                var cs = Object.assign({}, collapsedSet)
                                if (cs[index]) {
                                    delete cs[index]
                                } else {
                                    cs[index] = true
                                }
                                collapsedSet = cs
                            }
                        }
                    }

                    // Type icon badge
                    Rectangle {
                        width: typeIconText.width + 8
                        height: 16
                        radius: 3
                        color: Qt.rgba(typeColorVal.r, typeColorVal.g, typeColorVal.b, 0.15)

                        property color typeColorVal: typeColor(node.type !== undefined ? node.type : "")

                        Text {
                            id: typeIconText
                            anchors.centerIn: parent
                            text: typeIcon(node.type !== undefined ? node.type : "")
                            color: parent.typeColorVal
                            font.pixelSize: 9
                            font.family: "Consolas, monospace"
                        }
                    }

                    // Key label
                    Text {
                        text: (node.key !== undefined ? node.key : "") + ":"
                        color: ThemeManager.primaryColor
                        font.pixelSize: 10
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.preferredWidth: 90
                        Layout.alignment: Qt.AlignVCenter
                    }

                    // Value label
                    Text {
                        Layout.fillWidth: true
                        text: node.value !== undefined ? String(node.value) : ""
                        color: typeColor(node.type !== undefined ? node.type : "")
                        font.family: "Consolas, monospace"
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }
        }

        // ── Empty state ────────────────────────────────────────────────────
        Rectangle {
            visible: treeModel.length === 0
            Layout.fillWidth: true
            height: 40
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: "Send JSON to loadJson() to visualize"
                color: ThemeManager.textSecondaryColor
                font.pixelSize: 10
            }
        }
    }
}
