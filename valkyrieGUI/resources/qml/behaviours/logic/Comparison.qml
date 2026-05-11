import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import App.Theme 1.0

import '../../components'

Item {
    id: root
    anchors.fill: parent
    property var behaviourObject

    readonly property var opSymbols: ["==", "?", "<", ">", "=", "="]

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 4

        // -- Operator selector ----------------------------------------------
        Rectangle {
            Layout.fillWidth: true; height: 32; radius: 4
            color: Qt.rgba(ThemeManager.textColor.r, ThemeManager.textColor.g, ThemeManager.textColor.b, 0.04)
            clip: true

            Row {
                anchors.fill: parent; spacing: 0
                Repeater {
                    model: root.opSymbols
                    delegate: Rectangle {
                        width: parent.width / root.opSymbols.length; height: 32; radius: 4
                        color: behaviourObject && behaviourObject.operation === index
                               ? ThemeManager.primaryColor : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Text {
                            anchors.centerIn: parent
                            text: modelData; font.pixelSize: 14; font.bold: true
                            color: behaviourObject && behaviourObject.operation === index
                                   ? ThemeManager.backgroundColor : ThemeManager.textColor
                            opacity: behaviourObject && behaviourObject.operation === index ? 1.0 : 0.5
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: behaviourObject.setOperation(index)
                        }
                    }
                }
            }
        }

        // -- Result indicator -----------------------------------------------
        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 52; radius: 6
            color: {
                if (!behaviourObject) return "transparent"
                return behaviourObject.result ? Qt.rgba(0, 0.78, 0.33, 0.1) : Qt.rgba(1, 0.09, 0.27, 0.1)
            }
            border.width: 1
            border.color: {
                if (!behaviourObject) return "transparent"
                return behaviourObject.result ? "#00C853" : "#FF1744"
            }
            Behavior on border.color { ColorAnimation { duration: 200 } }
            Behavior on color        { ColorAnimation { duration: 200 } }

            RowLayout {
                anchors.centerIn: parent; spacing: 8
                Rectangle {
                    width: 16; height: 16; radius: 8
                    color: behaviourObject && behaviourObject.result ? "#00C853" : "#FF1744"
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    text: behaviourObject && behaviourObject.result ? "TRUE" : "FALSE"
                    font.pixelSize: 18; font.bold: true
                    color: behaviourObject && behaviourObject.result ? "#00C853" : "#FF1744"
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        // -- Formula display ------------------------------------------------
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: {
                if (!behaviourObject) return ""
                return behaviourObject.valueA.toFixed(4) + " " +
                       root.opSymbols[behaviourObject.operation] + " " +
                       behaviourObject.valueB.toFixed(4)
            }
            font.pixelSize: 11; font.family: "Consolas"
            color: ThemeManager.textSecondaryColor
        }

        // -- A input --------------------------------------------------------
        NumericInputField {
            Layout.fillWidth: true; implicitHeight: 36
            label: "A"
            value: behaviourObject ? behaviourObject.valueA : 0
            from: -1e6; to: 1e6
            stepSize: 1.0; decimals: 4
            showBar: false
            accentColor: "#2ecc71"
            onValueModified: function(newValue) { if (behaviourObject) behaviourObject.setA(newValue) }
        }

        // -- B input --------------------------------------------------------
        NumericInputField {
            Layout.fillWidth: true; implicitHeight: 36
            label: "B"
            value: behaviourObject ? behaviourObject.valueB : 0
            from: -1e6; to: 1e6
            stepSize: 1.0; decimals: 4
            showBar: false
            accentColor: "#3498db"
            onValueModified: function(newValue) { if (behaviourObject) behaviourObject.setB(newValue) }
        }
    }
}

