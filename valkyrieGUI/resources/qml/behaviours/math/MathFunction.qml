import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import App.Theme 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    readonly property var funcNames: ["sin","cos","tan","abs","v","ln","log10","e?","?x?","?x?","round"]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // -- Function selector ----------------------------------------------
        Rectangle {
            Layout.fillWidth: true; implicitHeight: funcGrid.height + 8; radius: 4
            color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.04)
            clip: true

            Flow {
                id: funcGrid
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 4 }
                spacing: 2

                Repeater {
                    model: root.funcNames
                    delegate: Rectangle {
                        width: 42; height: 22; radius: 3
                        color: behaviourObject && behaviourObject.function === index
                               ? ThemeManager.primaryColor : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            anchors.centerIn: parent
                            text: modelData; font.pixelSize: 9
                            color: behaviourObject && behaviourObject.function === index
                                   ? ThemeManager.backgroundColor : ThemeManager.textColor
                            opacity: behaviourObject && behaviourObject.function === index ? 1.0 : 0.5
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: behaviourObject.setFunction(index)
                        }
                    }
                }
            }
        }

        // -- Result display -------------------------------------------------
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 46; radius: 6
            color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.08)
            border.width: 1
            border.color: Qt.rgba(ThemeManager.primaryColor.r, ThemeManager.primaryColor.g, ThemeManager.primaryColor.b, 0.2)

            Column {
                anchors.centerIn: parent; spacing: 2
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: behaviourObject ? behaviourObject.result.toFixed(6) : "0"
                    font.pixelSize: 16; font.family: "Consolas"; font.bold: true
                    color: ThemeManager.primaryColor
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        if (!behaviourObject) return ""
                        return root.funcNames[behaviourObject.function] + "(" + behaviourObject.inputValue.toFixed(4) + ")"
                    }
                    font.pixelSize: 9; color: ThemeManager.textSecondaryColor
                }
            }
        }

        // -- X input --------------------------------------------------------
        NumericInputField {
            Layout.fillWidth: true; implicitHeight: 36
            label: "x"
            value: behaviourObject ? behaviourObject.inputValue : 0
            from: -1e6; to: 1e6
            stepSize: 0.1; decimals: 4
            showBar: false
            accentColor: ThemeManager.primaryColor
            onValueModified: function(newValue) { if (behaviourObject) behaviourObject.setInput(newValue) }
        }
    }
}

